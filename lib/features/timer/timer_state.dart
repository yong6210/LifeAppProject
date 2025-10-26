import 'package:life_app/features/timer/timer_plan.dart';
import 'package:life_app/features/workout/models/workout_navigator_models.dart';

class TimerState {
  const TimerState({
    required this.mode,
    required this.segments,
    required this.currentSegmentIndex,
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.segmentRemainingSeconds,
    required this.isRunning,
    required this.sessionStartedAt,
    required this.segmentStartedAt,
    required this.isSoundEnabled,
    this.navigatorRoute,
    this.navigatorTarget,
    this.navigatorVoiceEnabled = true,
    this.navigatorLastCueMessage,
    this.navigatorLastCueAt,
    this.navigatorLastSummary,
  });

  final String mode;
  final List<TimerSegment> segments;
  final int currentSegmentIndex;
  final int totalSeconds;
  final int remainingSeconds;
  final int segmentRemainingSeconds;
  final bool isRunning;
  final DateTime? sessionStartedAt;
  final DateTime? segmentStartedAt;
  final bool isSoundEnabled;
  final WorkoutNavigatorRoute? navigatorRoute;
  final WorkoutNavigatorTarget? navigatorTarget;
  final bool navigatorVoiceEnabled;
  final String? navigatorLastCueMessage;
  final DateTime? navigatorLastCueAt;
  final NavigatorCompletionSummary? navigatorLastSummary;

  TimerSegment get currentSegment => segments[currentSegmentIndex];

  int get segmentTotalSeconds => currentSegment.duration.inSeconds;

  int get completedSeconds => totalSeconds - remainingSeconds;

  bool get isLastSegment => currentSegmentIndex >= segments.length - 1;

  factory TimerState.idle({
    required TimerPlan plan,
    bool soundEnabled = true,
    WorkoutNavigatorRoute? navigatorRoute,
    WorkoutNavigatorTarget? navigatorTarget,
    bool navigatorVoiceEnabled = true,
    NavigatorCompletionSummary? navigatorLastSummary,
  }) {
    return TimerState(
      mode: plan.mode,
      segments: plan.segments,
      currentSegmentIndex: 0,
      totalSeconds: plan.totalSeconds,
      remainingSeconds: plan.totalSeconds,
      segmentRemainingSeconds: plan.segments.first.duration.inSeconds,
      isRunning: false,
      sessionStartedAt: null,
      segmentStartedAt: null,
      isSoundEnabled: soundEnabled,
      navigatorRoute: navigatorRoute,
      navigatorTarget: navigatorTarget,
      navigatorVoiceEnabled: navigatorVoiceEnabled,
      navigatorLastCueMessage: null,
      navigatorLastCueAt: null,
      navigatorLastSummary: navigatorLastSummary,
    );
  }

  TimerState copyWith({
    String? mode,
    List<TimerSegment>? segments,
    int? currentSegmentIndex,
    int? totalSeconds,
    int? remainingSeconds,
    int? segmentRemainingSeconds,
    bool? isRunning,
    DateTime? sessionStartedAt,
    DateTime? segmentStartedAt,
    bool? isSoundEnabled,
    bool? navigatorVoiceEnabled,
    Object? navigatorRoute = _sentinel,
    Object? navigatorTarget = _sentinel,
    Object? navigatorLastCueMessage = _sentinel,
    Object? navigatorLastCueAt = _sentinel,
    Object? navigatorLastSummary = _sentinel,
  }) {
    final effectiveSegments = segments ?? this.segments;
    final effectiveIndex = currentSegmentIndex ?? this.currentSegmentIndex;
    return TimerState(
      mode: mode ?? this.mode,
      segments: effectiveSegments,
      currentSegmentIndex: effectiveIndex,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      segmentRemainingSeconds:
          segmentRemainingSeconds ?? this.segmentRemainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      sessionStartedAt: sessionStartedAt ?? this.sessionStartedAt,
      segmentStartedAt: segmentStartedAt ?? this.segmentStartedAt,
      isSoundEnabled: isSoundEnabled ?? this.isSoundEnabled,
      navigatorRoute: navigatorRoute == _sentinel
          ? this.navigatorRoute
          : navigatorRoute as WorkoutNavigatorRoute?,
      navigatorTarget: navigatorTarget == _sentinel
          ? this.navigatorTarget
          : navigatorTarget as WorkoutNavigatorTarget?,
      navigatorVoiceEnabled:
          navigatorVoiceEnabled ?? this.navigatorVoiceEnabled,
      navigatorLastCueMessage: navigatorLastCueMessage == _sentinel
          ? this.navigatorLastCueMessage
          : navigatorLastCueMessage as String?,
      navigatorLastCueAt: navigatorLastCueAt == _sentinel
          ? this.navigatorLastCueAt
          : navigatorLastCueAt as DateTime?,
      navigatorLastSummary: navigatorLastSummary == _sentinel
          ? this.navigatorLastSummary
          : navigatorLastSummary as NavigatorCompletionSummary?,
    );
  }
}

const _sentinel = Object();

class NavigatorCompletionSummary {
  const NavigatorCompletionSummary({
    required this.routeId,
    required this.completedAt,
    required this.elapsedSeconds,
    required this.voiceGuidanceEnabled,
    required this.checklistCheckedCount,
    this.targetType,
    this.targetValue,
  });

  final String routeId;
  final DateTime completedAt;
  final int elapsedSeconds;
  final WorkoutTargetType? targetType;
  final double? targetValue;
  final bool voiceGuidanceEnabled;
  final int checklistCheckedCount;
}
