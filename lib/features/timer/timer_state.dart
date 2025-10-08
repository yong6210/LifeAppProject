import 'package:life_app/features/timer/timer_plan.dart';

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

  TimerSegment get currentSegment => segments[currentSegmentIndex];

  int get segmentTotalSeconds => currentSegment.duration.inSeconds;

  int get completedSeconds => totalSeconds - remainingSeconds;

  bool get isLastSegment => currentSegmentIndex >= segments.length - 1;

  factory TimerState.idle({required TimerPlan plan, bool soundEnabled = true}) {
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
    );
  }
}
