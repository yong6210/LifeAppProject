import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TimerAccuracySample {
  const TimerAccuracySample({
    required this.recordedAt,
    required this.mode,
    required this.segmentId,
    required this.segmentLabel,
    required this.skewMs,
  });

  final DateTime recordedAt;
  final String mode;
  final String segmentId;
  final String segmentLabel;
  final int skewMs;

  Map<String, dynamic> toJson() => {
    'recordedAt': recordedAt.toIso8601String(),
    'mode': mode,
    'segmentId': segmentId,
    'segmentLabel': segmentLabel,
    'skewMs': skewMs,
  };

  static TimerAccuracySample? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final recordedAtString = json['recordedAt'] as String?;
    if (recordedAtString == null) return null;
    return TimerAccuracySample(
      recordedAt:
          DateTime.tryParse(recordedAtString)?.toUtc() ??
          DateTime.now().toUtc(),
      mode: json['mode'] as String? ?? 'unknown',
      segmentId: json['segmentId'] as String? ?? 'unknown',
      segmentLabel: json['segmentLabel'] as String? ?? 'unknown',
      skewMs: (json['skewMs'] as num?)?.toInt() ?? 0,
    );
  }
}

class TimerDiagnosticsService {
  TimerDiagnosticsService._(this._prefs);

  static const _prefsKeyAccuracy = 'diagnostics_timer_accuracy_v1';
  static const _maxSamples = 50;

  final SharedPreferences _prefs;

  static Future<TimerDiagnosticsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return TimerDiagnosticsService._(prefs);
  }

  Future<void> appendAccuracySample(TimerAccuracySample sample) async {
    final entries = await loadAccuracySamples();
    final updated = <TimerAccuracySample>[
      sample,
      ...entries,
    ].take(_maxSamples).toList();
    final encoded = updated
        .map((entry) => jsonEncode(entry.toJson()))
        .toList(growable: false);
    await _prefs.setStringList(_prefsKeyAccuracy, encoded);
  }

  Future<List<TimerAccuracySample>> loadAccuracySamples() async {
    final raw = _prefs.getStringList(_prefsKeyAccuracy) ?? const [];
    return raw
        .map((entry) {
          try {
            final decoded = jsonDecode(entry) as Map<String, dynamic>;
            return TimerAccuracySample.fromJson(decoded);
          } catch (_) {
            return null;
          }
        })
        .whereType<TimerAccuracySample>()
        .toList(growable: false);
  }

  Future<void> clearAccuracySamples() async {
    await _prefs.remove(_prefsKeyAccuracy);
  }

  Future<String> exportAccuracySamplesAsCsv() async {
    final samples = await loadAccuracySamples();
    final buffer = StringBuffer(
      'recorded_at_utc,mode,segment_id,segment_label,skew_ms\n',
    );
    for (final sample in samples) {
      buffer.writeln(
        '${sample.recordedAt.toIso8601String()},'
        '${_escape(sample.mode)},'
        '${_escape(sample.segmentId)},'
        '${_escape(sample.segmentLabel)},'
        '${sample.skewMs}',
      );
    }
    return buffer.toString();
  }

  String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }
    return value;
  }
}
