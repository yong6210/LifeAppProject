import 'package:equatable/equatable.dart';

/// High-level target for the sleep routine.
enum SleepGoal {
  /// Short restorative power nap.
  rest,

  /// Standard overnight sleep.
  standard,

  /// Deeper recovery sleep after fatigue.
  recovery,
}

/// How the user specified the routine length.
enum SleepIntentType {
  /// Sleep for a specific duration.
  duration,

  /// Wake up at a target clock time.
  wakeTime,
}

/// Represents the user's high-level intent.
class SleepIntent extends Equatable {
  const SleepIntent.duration(this.duration)
      : type = SleepIntentType.duration,
        wakeTime = null;

  const SleepIntent.wakeTime(this.wakeTime)
      : type = SleepIntentType.wakeTime,
        duration = null;

  final SleepIntentType type;
  final Duration? duration;
  final DateTime? wakeTime;

  bool get isDuration => type == SleepIntentType.duration;
  bool get isWakeTime => type == SleepIntentType.wakeTime;

  @override
  List<Object?> get props => [type, duration, wakeTime];
}

/// Semantic grouping for sleep routine segments.
enum SleepRoutineSegmentKind {
  windDown,
  relax,
  mainSleep,
  preWake,
  wakeAlarm,
}

/// Single segment in an AI generated sleep routine.
class SleepRoutineSegmentPlan extends Equatable {
  const SleepRoutineSegmentPlan({
    required this.id,
    required this.kind,
    required this.duration,
    required this.localizationKey,
    this.localizationArgs = const {},
    this.soundProfile,
    this.autoStartNext = true,
    this.enableSmartAlarm = false,
  });

  final String id;
  final SleepRoutineSegmentKind kind;
  final Duration duration;
  final String localizationKey;
  final Map<String, String> localizationArgs;
  final String? soundProfile;
  final bool autoStartNext;
  final bool enableSmartAlarm;

  @override
  List<Object?> get props => [
        id,
        kind,
        duration,
        localizationKey,
        localizationArgs,
        soundProfile,
        autoStartNext,
        enableSmartAlarm,
      ];
}

/// Declarative audio blend values for the routine.
class SleepAudioBlend extends Equatable {
  const SleepAudioBlend({
    required this.layers,
    this.fadeIn = const Duration(seconds: 3),
    this.fadeOut = const Duration(seconds: 5),
  });

  /// Map of ambience id -> normalized gain (0.0-1.0).
  final Map<String, double> layers;
  final Duration fadeIn;
  final Duration fadeOut;

  @override
  List<Object?> get props => [layers, fadeIn, fadeOut];
}

class SleepRoutinePlan extends Equatable {
  const SleepRoutinePlan({
    required this.goal,
    required this.intent,
    required this.recommendedBedTime,
    required this.recommendedWakeTime,
    required this.segments,
    required this.audioBlend,
    required this.totalDuration,
  });

  final SleepGoal goal;
  final SleepIntent intent;
  final DateTime recommendedBedTime;
  final DateTime recommendedWakeTime;
  final List<SleepRoutineSegmentPlan> segments;
  final SleepAudioBlend audioBlend;
  final Duration totalDuration;

  SleepRoutineSegmentPlan get mainSleepSegment =>
      segments.firstWhere((segment) => segment.kind == SleepRoutineSegmentKind.mainSleep);

  @override
  List<Object?> get props => [
        goal,
        intent,
        recommendedBedTime,
        recommendedWakeTime,
        segments,
        audioBlend,
        totalDuration,
      ];
}

class DailyUsageContext {
  const DailyUsageContext({
    required this.focusMinutes,
    required this.restMinutes,
    required this.workoutMinutes,
    required this.sleepMinutes,
  });

  final int focusMinutes;
  final int restMinutes;
  final int workoutMinutes;
  final int sleepMinutes;

  double get _focusLoad =>
      (focusMinutes / 180).clamp(0, 2.0); // intense focus beyond 3h

  double get _restDeficit =>
      ((30 - restMinutes).clamp(0, 60)) / 60; // prefer at least 30m rest

  double _sleepDebtScoreFor(SleepGoal goal) {
    final targetMinutes = switch (goal) {
      SleepGoal.rest => 90,
      SleepGoal.standard => 420,
      SleepGoal.recovery => 480,
    };
    final debtMinutes = (targetMinutes - sleepMinutes).clamp(0, 240);
    return debtMinutes / 240;
  }

  double get _physicalLoad =>
      (workoutMinutes / 60).clamp(0, 2.0); // heavy activity beyond 1h

  double calmNeedScore() =>
      (0.6 * _focusLoad + 0.8 * _restDeficit).clamp(0, 1.0);

  double physicalRecoveryNeedScore(SleepGoal goal) =>
      (0.6 * _physicalLoad + 0.4 * _sleepDebtScoreFor(goal)).clamp(0, 1.0);

  double sleepExtensionScore(SleepGoal goal) =>
      (calmNeedScore() * 0.2 + _sleepDebtScoreFor(goal)).clamp(0, 1.0);

  Duration recommendedAdditionalDuration(SleepGoal goal) {
    final baseMinutes = (sleepExtensionScore(goal) * 60).round();
    final focusBonus = (_focusLoad * 15).round();
    final totalMinutes = switch (goal) {
      SleepGoal.rest => (baseMinutes * 0.3 + focusBonus * 0.5).round(),
      SleepGoal.standard => baseMinutes + focusBonus,
      SleepGoal.recovery => (baseMinutes * 1.2 + focusBonus).round(),
    };
    final capped = switch (goal) {
      SleepGoal.rest => totalMinutes.clamp(0, 20),
      SleepGoal.standard => totalMinutes.clamp(0, 45),
      SleepGoal.recovery => totalMinutes.clamp(0, 75),
    };
    return Duration(minutes: capped);
  }
}
