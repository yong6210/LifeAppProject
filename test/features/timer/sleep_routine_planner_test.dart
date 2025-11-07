import 'package:flutter_test/flutter_test.dart';
import 'package:life_app/features/timer/sleep_routine_models.dart';
import 'package:life_app/features/timer/sleep_routine_planner.dart';
import 'package:life_app/models/settings.dart';

void main() {
  final planner = SleepRoutinePlanner();
  final settings = Settings()
    ..sleepSmartAlarmWindowMinutes = 15
    ..sleepSmartAlarmIntervalMinutes = 3
    ..sleepSmartAlarmExactFallback = true;

  group('SleepRoutinePlanner', () {
    test('creates rest routine with duration intent', () {
      final plan = planner.build(
        goal: SleepGoal.rest,
        intent: const SleepIntent.duration(Duration(minutes: 30)),
        settings: settings,
        now: DateTime.utc(2025, 1, 1, 10, 0),
      );

      expect(plan.goal, SleepGoal.rest);
      expect(plan.segments.length, 5);
      final total =
          plan.segments.fold<Duration>(Duration.zero, (prev, s) => prev + s.duration);
      expect(total.inMinutes, plan.totalDuration.inMinutes);
      final main = plan.mainSleepSegment.duration;
      expect(main.inMinutes, greaterThanOrEqualTo(12));
      expect(plan.recommendedWakeTime.isAfter(plan.recommendedBedTime), isTrue);
    });

    test('adjusts wake time intent into the future', () {
      final now = DateTime.utc(2025, 1, 1, 23, 0);
      final targetWake = DateTime.utc(2025, 1, 1, 6, 30);
      final plan = planner.build(
        goal: SleepGoal.standard,
        intent: SleepIntent.wakeTime(targetWake),
        settings: settings,
        now: now,
      );

      expect(plan.recommendedWakeTime.isAfter(now), isTrue);
      expect(plan.recommendedBedTime.isBefore(plan.recommendedWakeTime), isTrue);
      expect(plan.totalDuration.inHours, greaterThanOrEqualTo(4));
      expect(plan.mainSleepSegment.duration.inHours, greaterThanOrEqualTo(4));
      expect(
        plan.segments.where((segment) => segment.enableSmartAlarm).length,
        equals(1),
      );
    });

    test('recovery routine clamps to minimum duration', () {
      final plan = planner.build(
        goal: SleepGoal.recovery,
        intent: const SleepIntent.duration(Duration(hours: 3)),
        settings: settings,
        now: DateTime.utc(2025, 1, 2, 22, 0),
      );

      expect(plan.totalDuration.inMinutes, greaterThanOrEqualTo(321));
      expect(plan.mainSleepSegment.duration.inHours, greaterThanOrEqualTo(5));
    });

    test('usage context increases relaxation when focus load is high', () {
      final basePlan = planner.build(
        goal: SleepGoal.standard,
        intent: const SleepIntent.duration(Duration(hours: 7)),
        settings: settings,
        now: DateTime.utc(2025, 1, 3, 20, 0),
      );

      final usage = DailyUsageContext(
        focusMinutes: 360,
        restMinutes: 10,
        workoutMinutes: 45,
        sleepMinutes: 300,
      );

      final tunedPlan = planner.build(
        goal: SleepGoal.standard,
        intent: const SleepIntent.duration(Duration(hours: 7)),
        settings: settings,
        now: DateTime.utc(2025, 1, 3, 20, 0),
        usage: usage,
      );

      final baseWindDown = basePlan.segments
          .firstWhere((segment) => segment.kind == SleepRoutineSegmentKind.windDown)
          .duration;
      final tunedWindDown = tunedPlan.segments
          .firstWhere((segment) => segment.kind == SleepRoutineSegmentKind.windDown)
          .duration;
      expect(tunedWindDown, greaterThan(baseWindDown));
      expect(tunedPlan.totalDuration.inMinutes,
          greaterThanOrEqualTo(basePlan.totalDuration.inMinutes));
      expect(tunedPlan.audioBlend.layers.containsKey('ocean_waves'), isTrue);
    });
  });
}
