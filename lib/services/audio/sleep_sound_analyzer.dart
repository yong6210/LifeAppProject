import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:life_app/services/audio/sleep_sound_recorder.dart';

/// Possible qualitative scores derived from the sound analysis.
enum SleepSoundScore { restful, moderate, disrupted }

/// Summary data produced after running an on-device sleep sound analysis session.
class SleepSoundSummary {
  SleepSoundSummary({
    required this.recordingPath,
    required this.duration,
    required this.averageAmplitude,
    required this.maxAmplitude,
    required this.loudEventCount,
    required this.sampleCount,
    required this.restfulSampleRatio,
    List<SleepNoiseEvent>? noiseEvents,
  }) : noiseEvents = noiseEvents ?? const [];

  /// Location of the recorded audio file (if recording was started).
  final String? recordingPath;

  /// Total duration of the session.
  final Duration duration;

  /// Average normalized amplitude (0..1) across the session.
  final double averageAmplitude;

  /// Maximum normalized amplitude (0..1) detected.
  final double maxAmplitude;

  /// Number of detected loud events crossing the configured threshold.
  final int loudEventCount;

  /// Number of amplitude samples captured during the session.
  final int sampleCount;

  /// Ratio (0-1) of samples considered "restful" (below quiet threshold).
  final double restfulSampleRatio;

  /// Timeline of detected loud events during the session.
  final List<SleepNoiseEvent> noiseEvents;

  factory SleepSoundSummary.fromJson(Map<String, dynamic> json) {
    double castDouble(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }
      return 0.0;
    }

    int castInt(dynamic value) {
      if (value is num) {
        return value.toInt();
      }
      return 0;
    }

    return SleepSoundSummary(
      recordingPath: json['recordingPath'] as String?,
      duration: Duration(milliseconds: castInt(json['durationMs'])),
      averageAmplitude: castDouble(json['averageAmplitude']),
      maxAmplitude: castDouble(json['maxAmplitude']),
      loudEventCount: castInt(json['loudEventCount']),
      sampleCount: castInt(json['sampleCount']),
      restfulSampleRatio: (castDouble(json['restfulSampleRatio'])
              .clamp(0.0, 1.0) as num)
          .toDouble(),
      noiseEvents: (json['noiseEvents'] as List<dynamic>?)
              ?.map((event) => SleepNoiseEvent.fromJson(
                    Map<String, dynamic>.from(event as Map),
                  ))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'recordingPath': recordingPath,
        'durationMs': duration.inMilliseconds,
        'averageAmplitude': averageAmplitude,
        'maxAmplitude': maxAmplitude,
        'loudEventCount': loudEventCount,
        'sampleCount': sampleCount,
        'restfulSampleRatio': restfulSampleRatio,
        'noiseEvents': noiseEvents.map((event) => event.toJson()).toList(),
      };

  /// Approximate restful minutes (based on quiet samples).
  double get restfulMinutes => duration.inSeconds * restfulSampleRatio / 60.0;

  /// Simple qualitative score based on noise ratio and loud event count.
  SleepSoundScore get score {
    if (restfulSampleRatio >= 0.75 && loudEventCount <= 3) {
      return SleepSoundScore.restful;
    }
    if (restfulSampleRatio >= 0.5 && loudEventCount <= 8) {
      return SleepSoundScore.moderate;
    }
    return SleepSoundScore.disrupted;
  }
}

/// Provides a minimal sleep sound analysis flow. This is intentionally simple so
/// teams can iterate on thresholds or swap in an ML model later without
/// rewiring recorder code.
class SleepSoundAnalyzer {
  SleepSoundAnalyzer({SleepSoundRecorder? recorder})
    : _recorder = recorder ?? sleepSoundRecorder;

  final SleepSoundRecorder _recorder;

  StreamSubscription<double>? _amplitudeSubscription;
  DateTime? _startTime;
  String? _recordingPath;

  final _samples = <double>[];
  final _noiseEvents = <SleepNoiseEvent>[];
  final _loudEventTimestamps = <DateTime>[];
  int _consecutiveLoudSamples = 0;
  int _restfulSampleCount = 0;
  DateTime? _currentEventStart;
  double _currentEventPeak = 0.0;
  int _currentEventSamples = 0;

  bool get isRunning => _startTime != null;

  static const double _loudThreshold = 0.35; // empirically chosen baseline
  static const int _consecutiveTrigger = 3; // ~1.2s with 400ms polling
  static const double _restfulThreshold = 0.18;

  /// Starts recording + amplitude monitoring. Returns `true` if the session
  /// successfully started.
  Future<bool> start() async {
    if (isRunning) {
      return true;
    }

    final allowed = await _recorder.ensurePermissions();
    if (!allowed) {
      return false;
    }

    _recordingPath = await _recorder.startRecording();
    _startTime = DateTime.now();
    _samples.clear();
    _loudEventTimestamps.clear();
    _consecutiveLoudSamples = 0;
    _restfulSampleCount = 0;
    _noiseEvents.clear();
    _currentEventStart = null;
    _currentEventPeak = 0.0;
    _currentEventSamples = 0;

    _amplitudeSubscription = _recorder.amplitudeStream.listen(
      _handleAmplitudeSample,
      onError: (Object error, StackTrace stack) {
        debugPrint('SleepSoundAnalyzer amplitude error: $error');
      },
    );

    return true;
  }

  void _handleAmplitudeSample(double amplitude) {
    _samples.add(amplitude);
    if (amplitude >= _loudThreshold) {
      _consecutiveLoudSamples += 1;
      if (_consecutiveLoudSamples >= _consecutiveTrigger) {
        _loudEventTimestamps.add(DateTime.now());
        _consecutiveLoudSamples = 0;
      }
      _startEventIfNeeded(amplitude);
    } else {
      _consecutiveLoudSamples = 0;
      _finishCurrentEvent();
    }

    if (amplitude <= _restfulThreshold) {
      _restfulSampleCount += 1;
    }
    _updateEventPeak(amplitude);
  }

  /// Stops the current session, finalizes the recording and returns a summary.
  Future<SleepSoundSummary> stop() async {
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;

    final path = await _recorder.stopRecording();
    final startedAt = _startTime ?? DateTime.now();
    final duration = DateTime.now().difference(startedAt);

    _finishCurrentEvent(force: true);

    final sampleCount = _samples.length;
    final maxAmplitude = _samples.isEmpty
        ? 0.0
        : _samples.reduce((a, b) => a > b ? a : b);
    final averageAmplitude = _samples.isEmpty
        ? 0.0
        : _samples.fold<double>(0.0, (acc, value) => acc + value) / sampleCount;
    final restfulRatio = sampleCount == 0
        ? 0.0
        : (_restfulSampleCount / sampleCount).clamp(0.0, 1.0);

    _startTime = null;

    return SleepSoundSummary(
      recordingPath: path ?? _recordingPath,
      duration: duration,
      averageAmplitude: averageAmplitude,
      maxAmplitude: maxAmplitude,
      loudEventCount: _noiseEvents.length,
      sampleCount: sampleCount,
      restfulSampleRatio: restfulRatio,
      noiseEvents: List.unmodifiable(_noiseEvents),
    );
  }

  Future<void> dispose() async {
    await _amplitudeSubscription?.cancel();
    await _recorder.dispose();
  }

  void _startEventIfNeeded(double amplitude) {
    if (_startTime == null) return;
    if (_currentEventStart != null) {
      _currentEventSamples += 1;
      return;
    }
    _currentEventStart = DateTime.now();
    _currentEventPeak = amplitude;
    _currentEventSamples = 1;
  }

  void _updateEventPeak(double amplitude) {
    if (_currentEventStart == null) {
      return;
    }
    if (amplitude > _currentEventPeak) {
      _currentEventPeak = amplitude;
    }
  }

  void _finishCurrentEvent({bool force = false}) {
    if (_currentEventStart == null) {
      return;
    }
    if (!force && _currentEventSamples < _consecutiveTrigger) {
      _currentEventStart = null;
      _currentEventSamples = 0;
      _currentEventPeak = 0.0;
      return;
    }
    final startTime = _currentEventStart!;
    final startOffset = _startTime == null
        ? Duration.zero
        : startTime.difference(_startTime!);
    final endTime = DateTime.now();
    final rawDuration = endTime.difference(startTime);
    final minDuration = const Duration(milliseconds: 400);
    final maxDuration = const Duration(minutes: 5);
    final duration = rawDuration < minDuration
        ? minDuration
        : (rawDuration > maxDuration ? maxDuration : rawDuration);
    _noiseEvents.add(
      SleepNoiseEvent(
        offset: startOffset,
        duration: duration,
        peakAmplitude: _currentEventPeak,
        sampleCount: _currentEventSamples,
      ),
    );
    _currentEventStart = null;
    _currentEventSamples = 0;
    _currentEventPeak = 0.0;
  }
}

class SleepNoiseEvent {
  SleepNoiseEvent({
    required this.offset,
    required this.duration,
    required this.peakAmplitude,
    required this.sampleCount,
  });

  final Duration offset;
  final Duration duration;
  final double peakAmplitude;
  final int sampleCount;

  factory SleepNoiseEvent.fromJson(Map<String, dynamic> json) {
    double castDouble(dynamic value) => value is num ? value.toDouble() : 0.0;
    int castInt(dynamic value) => value is num ? value.toInt() : 0;

    return SleepNoiseEvent(
      offset: Duration(milliseconds: castInt(json['offsetMs'])),
      duration: Duration(milliseconds: castInt(json['durationMs'])),
      peakAmplitude: castDouble(json['peakAmplitude']).clamp(0.0, 1.0),
      sampleCount: castInt(json['sampleCount']),
    );
  }

  Map<String, dynamic> toJson() => {
        'offsetMs': offset.inMilliseconds,
        'durationMs': duration.inMilliseconds,
        'peakAmplitude': peakAmplitude,
        'sampleCount': sampleCount,
      };
}
