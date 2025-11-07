import 'package:life_app/features/workout/models/workout_navigator_models.dart';

/// Metadata describing a timer-based workout preset used for the Stage 0 light
/// workout routines.
class WorkoutLightPreset {
  const WorkoutLightPreset({
    required this.id,
    required this.labelKey,
    required this.descriptionKey,
    required this.discipline,
    required this.intensity,
    required this.totalMinutes,
  });

  /// Unique identifier that ties UI, persistence, and timer plan generation.
  final String id;

  /// Localization key used for the preset chip label.
  final String labelKey;

  /// Localization key describing the preset structure (e.g., rounds, pace).
  final String descriptionKey;

  final WorkoutDiscipline discipline;
  final WorkoutIntensity intensity;

  /// Approximate duration surfaced to the user.
  final int totalMinutes;
}

const workoutLightPresets = <WorkoutLightPreset>[
  WorkoutLightPreset(
    id: 'run_light',
    labelKey: 'timer_workout_light_run_light_title',
    descriptionKey: 'timer_workout_light_run_light_desc',
    discipline: WorkoutDiscipline.running,
    intensity: WorkoutIntensity.light,
    totalMinutes: 16,
  ),
  WorkoutLightPreset(
    id: 'run_moderate',
    labelKey: 'timer_workout_light_run_moderate_title',
    descriptionKey: 'timer_workout_light_run_moderate_desc',
    discipline: WorkoutDiscipline.running,
    intensity: WorkoutIntensity.moderate,
    totalMinutes: 24,
  ),
  WorkoutLightPreset(
    id: 'run_vigorous',
    labelKey: 'timer_workout_light_run_vigorous_title',
    descriptionKey: 'timer_workout_light_run_vigorous_desc',
    discipline: WorkoutDiscipline.running,
    intensity: WorkoutIntensity.vigorous,
    totalMinutes: 22,
  ),
  WorkoutLightPreset(
    id: 'ride_light',
    labelKey: 'timer_workout_light_ride_light_title',
    descriptionKey: 'timer_workout_light_ride_light_desc',
    discipline: WorkoutDiscipline.cycling,
    intensity: WorkoutIntensity.light,
    totalMinutes: 27,
  ),
  WorkoutLightPreset(
    id: 'ride_moderate',
    labelKey: 'timer_workout_light_ride_moderate_title',
    descriptionKey: 'timer_workout_light_ride_moderate_desc',
    discipline: WorkoutDiscipline.cycling,
    intensity: WorkoutIntensity.moderate,
    totalMinutes: 32,
  ),
  WorkoutLightPreset(
    id: 'ride_vigorous',
    labelKey: 'timer_workout_light_ride_vigorous_title',
    descriptionKey: 'timer_workout_light_ride_vigorous_desc',
    discipline: WorkoutDiscipline.cycling,
    intensity: WorkoutIntensity.vigorous,
    totalMinutes: 31,
  ),
];
