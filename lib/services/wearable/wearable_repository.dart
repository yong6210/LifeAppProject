import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import 'package:life_app/services/wearable/wearable_sync_service.dart';

class WearableSummary {
  const WearableSummary({
    required this.connected,
    required this.source,
    required this.lastSync,
    required this.sleepMinutes,
    required this.restingHeartRate,
    required this.hrvScore,
    required this.steps,
  });

  const WearableSummary.disconnected()
    : connected = false,
      source = 'Not connected',
      lastSync = null,
      sleepMinutes = 0,
      restingHeartRate = 0,
      hrvScore = 0,
      steps = 0;

  final bool connected;
  final String source;
  final DateTime? lastSync;
  final int sleepMinutes;
  final int restingHeartRate;
  final int hrvScore;
  final int steps;

  bool get hasMetrics => connected && lastSync != null;

  WearableSummary copyWith({
    bool? connected,
    String? source,
    DateTime? lastSync,
    int? sleepMinutes,
    int? restingHeartRate,
    int? hrvScore,
    int? steps,
  }) {
    return WearableSummary(
      connected: connected ?? this.connected,
      source: source ?? this.source,
      lastSync: lastSync ?? this.lastSync,
      sleepMinutes: sleepMinutes ?? this.sleepMinutes,
      restingHeartRate: restingHeartRate ?? this.restingHeartRate,
      hrvScore: hrvScore ?? this.hrvScore,
      steps: steps ?? this.steps,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'connected': connected,
      'source': source,
      'lastSync': lastSync?.toUtc().toIso8601String(),
      'sleepMinutes': sleepMinutes,
      'restingHeartRate': restingHeartRate,
      'hrvScore': hrvScore,
      'steps': steps,
    };
  }

  factory WearableSummary.fromJson(Map<String, dynamic> json) {
    DateTime? parseLastSync() {
      final raw = json['lastSync'] as String?;
      if (raw == null) return null;
      final parsed = DateTime.tryParse(raw);
      return parsed?.toUtc();
    }

    return WearableSummary(
      connected: json['connected'] as bool? ?? false,
      source: json['source'] as String? ?? 'Not connected',
      lastSync: parseLastSync(),
      sleepMinutes: (json['sleepMinutes'] as num?)?.toInt() ?? 0,
      restingHeartRate: (json['restingHeartRate'] as num?)?.toInt() ?? 0,
      hrvScore: (json['hrvScore'] as num?)?.toInt() ?? 0,
      steps: (json['steps'] as num?)?.toInt() ?? 0,
    );
  }
}

abstract class WearableRepository {
  Future<WearableSummary> fetchTodaySummary();
  Stream<WearableSummary> watchTodaySummary();
  Future<WearableSummary> requestConnect({bool forceRefresh = false});
  Future<WearableSummary> disconnect();
  void dispose();
}

class WearableAuthorizationException implements Exception {
  const WearableAuthorizationException(this.message);

  final String message;

  @override
  String toString() => 'WearableAuthorizationException: $message';
}

class WearableOperationException implements Exception {
  WearableOperationException(this.message, [this.cause, this.stackTrace]);

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() =>
      'WearableOperationException: $message${cause == null ? '' : ' ($cause)'}';
}

class HealthWearableRepository implements WearableRepository {
  HealthWearableRepository({
    WearableSyncService? syncService,
    Duration refreshInterval = const Duration(minutes: 30),
    DateTime Function()? clock,
  }) : _syncService = syncService ?? wearableSyncService,
       _refreshInterval = refreshInterval,
       _clock = clock ?? DateTime.now;

  final WearableSyncService _syncService;
  final Duration _refreshInterval;
  final DateTime Function() _clock;

  final StreamController<WearableSummary> _controller =
      StreamController<WearableSummary>.broadcast();

  WearableSummary _current = const WearableSummary.disconnected();
  Timer? _poller;
  bool _configured = false;
  bool _authorized = false;
  bool _disposed = false;

  @override
  Future<WearableSummary> fetchTodaySummary() async {
    if (_authorized) {
      try {
        return await _refreshSummary();
      } on WearableOperationException {
        // Surface the last known summary if refresh fails.
        return _current;
      }
    }
    return _current;
  }

  @override
  Stream<WearableSummary> watchTodaySummary() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<WearableSummary> requestConnect({bool forceRefresh = false}) async {
    await _ensureConfigured();
    final granted = await _syncService.requestAuthorization();
    if (!granted) {
      _authorized = false;
      throw const WearableAuthorizationException(
        'Permission not granted by user',
      );
    }
    _authorized = true;
    final summary = await _refreshSummary();
    _startPolling();
    return summary;
  }

  @override
  Future<WearableSummary> disconnect() async {
    try {
      await _syncService.revokePermissions();
    } catch (_) {
      // Ignore revoke failures; some platforms do not support this call.
    }
    _authorized = false;
    _poller?.cancel();
    const summary = WearableSummary.disconnected();
    _emit(summary);
    return summary;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _poller?.cancel();
    unawaited(_controller.close());
  }

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _syncService.configure();
    _configured = true;
  }

  Future<WearableSummary> _refreshSummary() async {
    if (!_authorized) {
      return _current;
    }
    try {
      final now = _clock();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final sleepPoints = await _syncService.fetchSleepSamples(startOfDay, now);
      final heartRatePoints = await _syncService.fetchHeartRateSamples(
        startOfDay,
        now,
      );
      final hrvPoints = await _syncService.fetchHrvSamples(startOfDay, now);
      final steps = await _syncService.fetchStepCount(startOfDay, now) ?? 0;

      final summary = WearableSummary(
        connected: true,
        source: _resolveSource([sleepPoints, heartRatePoints, hrvPoints]),
        lastSync: now,
        sleepMinutes: _sumNumericMinutes(sleepPoints),
        restingHeartRate: _averageNumericValue(heartRatePoints),
        hrvScore: _averageNumericValue(hrvPoints),
        steps: steps,
      );

      _emit(summary);
      return summary;
    } catch (error, stackTrace) {
      throw WearableOperationException(
        'Failed to refresh wearable summary',
        error,
        stackTrace,
      );
    }
  }

  void _emit(WearableSummary summary) {
    if (_disposed) return;
    _current = summary;
    if (!_controller.isClosed) {
      _controller.add(summary);
    }
  }

  void _startPolling() {
    if (_disposed || _refreshInterval <= Duration.zero) {
      return;
    }
    _poller?.cancel();
    _poller = Timer.periodic(_refreshInterval, (_) {
      if (!_authorized || _disposed) return;
      unawaited(_refreshSummary());
    });
  }

  int _sumNumericMinutes(List<HealthDataPoint> points) {
    double total = 0;
    for (final point in points) {
      final value = point.value;
      if (value is NumericHealthValue) {
        total += value.numericValue.toDouble();
      }
    }
    return total.round();
  }

  int _averageNumericValue(List<HealthDataPoint> points) {
    if (points.isEmpty) return 0;
    double total = 0;
    var count = 0;
    for (final point in points) {
      final value = point.value;
      if (value is NumericHealthValue) {
        total += value.numericValue.toDouble();
        count += 1;
      }
    }
    if (count == 0) return 0;
    return (total / count).round();
  }

  String _resolveSource(List<List<HealthDataPoint>> collections) {
    for (final collection in collections) {
      for (final point in collection) {
        final sourceName = point.sourceName.trim();
        if (sourceName.isNotEmpty) {
          return sourceName;
        }
      }
    }
    if (kIsWeb) {
      return 'Wearable';
    }
    if (Platform.isIOS) {
      return 'Apple Health';
    }
    if (Platform.isAndroid) {
      return 'Google Fit';
    }
    return 'Wearable';
  }
}

class MockWearableRepository implements WearableRepository {
  MockWearableRepository();

  final StreamController<WearableSummary> _controller =
      StreamController<WearableSummary>.broadcast();

  WearableSummary _current = const WearableSummary.disconnected();

  bool _disposed = false;

  @override
  Future<WearableSummary> fetchTodaySummary() async => _current;

  @override
  Stream<WearableSummary> watchTodaySummary() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<WearableSummary> requestConnect({bool forceRefresh = false}) async {
    final now = DateTime.now();
    _current = WearableSummary(
      connected: true,
      source: defaultTargetPlatform == TargetPlatform.iOS
          ? 'HealthKit (Demo)'
          : 'Google Fit (Demo)',
      lastSync: now,
      sleepMinutes: 7 * 60 + 15,
      restingHeartRate: 58,
      hrvScore: 72,
      steps: 6420,
    );
    if (!_controller.isClosed) {
      _controller.add(_current);
    }
    return _current;
  }

  @override
  Future<WearableSummary> disconnect() async {
    _current = const WearableSummary.disconnected();
    if (!_controller.isClosed) {
      _controller.add(_current);
    }
    return _current;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_controller.close());
  }
}
