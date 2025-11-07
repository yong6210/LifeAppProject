enum WorkoutDiscipline { running, cycling }

enum WorkoutIntensity { light, moderate, vigorous }

enum WorkoutTargetType { distance, duration }

class WorkoutNavigatorCue {
  const WorkoutNavigatorCue({
    required this.offset,
    required this.message,
  });

  final Duration offset;
  final String message;
}

class WorkoutNavigatorSegment {
  const WorkoutNavigatorSegment({
    required this.startOffset,
    required this.endOffset,
    required this.focus,
    required this.cue,
  });

  final Duration startOffset;
  final Duration endOffset;
  final String focus;
  final String cue;
}

class WorkoutNavigatorRoute {
  const WorkoutNavigatorRoute({
    required this.id,
    required this.title,
    required this.description,
    required this.discipline,
    required this.intensity,
    required this.distanceKm,
    required this.estimatedMinutes,
    this.mapAssetPath,
    this.segments = const <WorkoutNavigatorSegment>[],
    this.voiceCues = const <WorkoutNavigatorCue>[],
    required this.offlineSummary,
  });

  final String id;
  final String title;
  final String description;
  final WorkoutDiscipline discipline;
  final WorkoutIntensity intensity;
  final double distanceKm;
  final double estimatedMinutes;
  final String? mapAssetPath;
  final List<WorkoutNavigatorSegment> segments;
  final List<WorkoutNavigatorCue> voiceCues;
  final String offlineSummary;

  Duration get totalDuration {
    if (segments.isEmpty) {
      return Duration.zero;
    }
    return segments
        .map((segment) => segment.endOffset)
        .reduce((a, b) => a >= b ? a : b);
  }
}

class WorkoutNavigatorTarget {
  const WorkoutNavigatorTarget.distance({
    required this.discipline,
    required this.intensity,
    required double kilometers,
  }) : type = WorkoutTargetType.distance,
       value = kilometers;

  const WorkoutNavigatorTarget.duration({
    required this.discipline,
    required this.intensity,
    required double minutes,
  }) : type = WorkoutTargetType.duration,
       value = minutes;

  final WorkoutDiscipline discipline;
  final WorkoutIntensity intensity;
  final WorkoutTargetType type;
  final double value;
}

class WorkoutNavigatorRecommendation {
  const WorkoutNavigatorRecommendation({
    required this.route,
    required this.tips,
  });

  final WorkoutNavigatorRoute route;
  final List<String> tips;
}
