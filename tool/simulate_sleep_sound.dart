import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:life_app/services/audio/sleep_sound_models.dart';

/// Generates a synthetic sleep sound session so QA can tune thresholds without
/// recording on a physical device. Run with:
///   dart run tool/simulate_sleep_sound.dart --out build/simulated_sleep_summary.json
///
/// The script emits a JSON summary compatible with [SleepSoundSummary.fromJson]
/// and logs a human readable breakdown for quick inspection.
Future<void> main(List<String> args) async {
  final argMap = _parseArgs(args);
  final outputPath = argMap['out'] ?? 'build/sleep_summary_simulated.json';
  final sampleInterval = const Duration(milliseconds: 400);

  final session = _SimulatedSession(
    segments: [
      _SimulatedSegment.restful(const Duration(minutes: 8)),
      _SimulatedSegment.snore(const Duration(seconds: 30)),
      _SimulatedSegment.restful(const Duration(minutes: 5)),
      _SimulatedSegment.noiseBurst(const Duration(seconds: 45)),
      _SimulatedSegment.restful(const Duration(minutes: 6)),
    ],
    sampleInterval: sampleInterval,
  );

  final summary = session.buildSummary();
  final jsonSummary = jsonEncode(summary.toJson());

  await File(outputPath).create(recursive: true);
  await File(outputPath).writeAsString(jsonSummary);

  stdout.writeln('Generated synthetic sleep sound summary:');
  stdout.writeln('- Output: $outputPath');
  stdout.writeln('- Duration: ${summary.duration.inMinutes}분 '
      '${summary.duration.inSeconds.remainder(60)}초');
  stdout.writeln('- Samples: ${summary.sampleCount}');
  stdout.writeln('- Loud events: ${summary.loudEventCount}');
  stdout.writeln(
    '- Restful ratio: ${(summary.restfulSampleRatio * 100).toStringAsFixed(1)}%',
  );
  stdout.writeln('Event timeline (max 5 shown):');
  for (final event in summary.noiseEvents.take(5)) {
    stdout.writeln(
      '  • offset ${_formatDuration(event.offset)} | '
      'duration ${_formatDuration(event.duration)} | '
      'peak ${(event.peakAmplitude * 100).toStringAsFixed(0)}%',
    );
  }
}

class _SimulatedSession {
  _SimulatedSession({
    required this.segments,
    required this.sampleInterval,
  });

  final List<_SimulatedSegment> segments;
  final Duration sampleInterval;

  static const double _restfulThreshold = 0.18;
  static const double _loudThreshold = 0.35;
  static const int _consecutiveTrigger = 3;

  SleepSoundSummary buildSummary() {
    final amplitudes = <double>[];
    final random = Random(42);

    for (final segment in segments) {
      final sampleCount = segment.duration.inMilliseconds ~/ sampleInterval.inMilliseconds;
      for (var i = 0; i < sampleCount; i += 1) {
        final amp = segment.sample(random);
        amplitudes.add(amp);
      }
    }

    final events = <SleepNoiseEvent>[];
    var restfulCount = 0;
    var consecutiveLoud = 0;
    DateTime? startTime;
    DateTime? currentEventStart;
    var currentEventSamples = 0;
    var currentEventPeak = 0.0;

    void finishEvent({bool force = false, required DateTime now}) {
      if (currentEventStart == null) return;
      if (!force && currentEventSamples < _consecutiveTrigger) {
        currentEventStart = null;
        currentEventSamples = 0;
        currentEventPeak = 0.0;
        return;
      }
      final start = currentEventStart!;
      final offset = startTime == null ? Duration.zero : start.difference(startTime);
      final duration = now.difference(start) < const Duration(milliseconds: 400)
          ? const Duration(milliseconds: 400)
          : now.difference(start);
      events.add(
        SleepNoiseEvent(
          offset: offset,
          duration: duration,
          peakAmplitude: currentEventPeak.clamp(0.0, 1.0),
          sampleCount: currentEventSamples,
        ),
      );
      currentEventStart = null;
      currentEventSamples = 0;
      currentEventPeak = 0.0;
    }

    final now = DateTime.now();
    startTime = now;
    for (var index = 0; index < amplitudes.length; index += 1) {
      final amplitude = amplitudes[index].clamp(0.0, 1.0);
      final sampleTime = startTime.add(
        _scaledDuration(sampleInterval, index),
      );

      if (amplitude <= _restfulThreshold) {
        restfulCount += 1;
      }

      if (amplitude >= _loudThreshold) {
        consecutiveLoud += 1;
        currentEventSamples += 1;
        currentEventPeak = max(currentEventPeak, amplitude);
        currentEventStart ??= sampleTime;
        if (consecutiveLoud >= _consecutiveTrigger) {
          // keep the event open; the finish logic will capture duration.
          consecutiveLoud = 0;
        }
      } else {
        consecutiveLoud = 0;
        finishEvent(force: false, now: sampleTime);
      }
    }

    finishEvent(
      force: true,
      now: startTime.add(
        _scaledDuration(sampleInterval, amplitudes.length),
      ),
    );

    final duration = _scaledDuration(sampleInterval, amplitudes.length);
    final averageAmplitude =
        amplitudes.isEmpty ? 0.0 : amplitudes.reduce((a, b) => a + b) / amplitudes.length;
    final maxAmplitude =
        amplitudes.isEmpty ? 0.0 : amplitudes.reduce((a, b) => max(a, b));
    final restfulRatio =
        amplitudes.isEmpty ? 0.0 : (restfulCount / amplitudes.length).clamp(0.0, 1.0);

    return SleepSoundSummary(
      recordingPath: 'simulated',
      duration: duration,
      averageAmplitude: averageAmplitude,
      maxAmplitude: maxAmplitude,
      loudEventCount: events.length,
      sampleCount: amplitudes.length,
      restfulSampleRatio: restfulRatio,
      noiseEvents: events,
    );
  }
}

abstract class _SimulatedSegment {
  _SimulatedSegment({
    required this.duration,
    required this.baseAmplitude,
    required this.variance,
  });

  final Duration duration;
  final double baseAmplitude;
  final double variance;

  factory _SimulatedSegment.restful(Duration duration) => _RestfulSegment(duration);
  factory _SimulatedSegment.snore(Duration duration) => _SnoreSegment(duration);
  factory _SimulatedSegment.noiseBurst(Duration duration) => _NoiseBurstSegment(duration);

  double sample(Random random) {
    final jitter = (random.nextDouble() - 0.5) * variance * 2;
    return (baseAmplitude + jitter).clamp(0.0, 1.0);
  }
}

class _RestfulSegment extends _SimulatedSegment {
  _RestfulSegment(Duration duration)
    : super(duration: duration, baseAmplitude: 0.12, variance: 0.04);
}

class _SnoreSegment extends _SimulatedSegment {
  _SnoreSegment(Duration duration)
    : super(duration: duration, baseAmplitude: 0.55, variance: 0.12);
}

class _NoiseBurstSegment extends _SimulatedSegment {
  _NoiseBurstSegment(Duration duration)
    : super(duration: duration, baseAmplitude: 0.42, variance: 0.15);
}

Map<String, String> _parseArgs(List<String> args) {
  final result = <String, String>{};
  for (final arg in args) {
    final parts = arg.split('=');
    if (parts.length == 2) {
      result[parts[0].replaceFirst('--', '')] = parts[1];
    }
  }
  return result;
}

String _formatDuration(Duration duration) {
  if (duration.inMinutes >= 1) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes분 $seconds초';
  }
  return '${duration.inSeconds}초';
}

Duration _scaledDuration(Duration duration, int multiplier) {
  return Duration(microseconds: duration.inMicroseconds * multiplier);
}
