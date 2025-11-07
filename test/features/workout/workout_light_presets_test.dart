import 'package:flutter_test/flutter_test.dart';
import 'package:life_app/features/timer/timer_plan.dart';
import 'package:life_app/features/workout/workout_light_presets.dart';

void main() {
  group('Workout light presets', () {
    test('run_light preset builds alternating run and walk segments', () {
      final preset = workoutLightPresets.firstWhere(
        (entry) => entry.id == 'run_light',
      );
      final plan = TimerPlanFactory.createWorkoutLightPlan(preset);

      expect(plan.mode, 'workout');
      expect(plan.segments.length, 7);
      expect(
        plan.segments.where((segment) => segment.type == 'workout').length,
        4,
      );
      expect(
        plan.segments.where((segment) => segment.type == 'rest').length,
        3,
      );
      expect(plan.segments.first.duration, const Duration(minutes: 3));
      expect(plan.segments.first.playSoundProfile, 'workout');
      expect(plan.segments.last.type, 'workout');
      expect(plan.segments.last.duration, const Duration(minutes: 3));
    });

    test('ride_vigorous preset includes warm-up and cooldown', () {
      final preset = workoutLightPresets.firstWhere(
        (entry) => entry.id == 'ride_vigorous',
      );
      final plan = TimerPlanFactory.createWorkoutLightPlan(preset);

      expect(plan.mode, 'workout');
      expect(plan.segments.first.type, 'workout');
      expect(plan.segments.first.duration, const Duration(minutes: 5));
      expect(
        plan.segments.first.localizationKey,
        'timer_workout_light_segment_warmup',
      );
      expect(plan.segments.last.type, 'rest');
      expect(plan.segments.last.duration, const Duration(minutes: 3));
      expect(
        plan.segments.last.localizationKey,
        'timer_workout_light_segment_cooldown',
      );
    });
  });
}
