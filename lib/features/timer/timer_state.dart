class TimerState {
  final String mode;            // 'focus' | 'rest' | 'workout' | 'sleep'
  final int totalSeconds;       // 시작 시 총 초
  final int remainingSeconds;   // 남은 초
  final bool isRunning;         // 실행 중 여부
  final DateTime? startTime;    // 실제 시작 시각 (일시정지/재개 포함)

  const TimerState({
    required this.mode,
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.isRunning,
    required this.startTime,
  });

  factory TimerState.idle({String mode = 'focus', int minutes = 25}) =>
      TimerState(
        mode: mode,
        totalSeconds: minutes * 60,
        remainingSeconds: minutes * 60,
        isRunning: false,
        startTime: null,
      );

  TimerState copyWith({
    String? mode,
    int? totalSeconds,
    int? remainingSeconds,
    bool? isRunning,
    DateTime? startTime,
  }) {
    return TimerState(
      mode: mode ?? this.mode,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      startTime: startTime ?? this.startTime,
    );
  }
}
