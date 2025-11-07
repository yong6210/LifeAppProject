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
      restfulSampleRatio:
          (castDouble(json['restfulSampleRatio']).clamp(0.0, 1.0) as num)
              .toDouble(),
      noiseEvents:
          (json['noiseEvents'] as List<dynamic>?)
              ?.map(
                (event) => SleepNoiseEvent.fromJson(
                  Map<String, dynamic>.from(event as Map),
                ),
              )
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
