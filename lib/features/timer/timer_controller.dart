import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/session.dart';
import '../../repositories/session_repository.dart';
import '../../providers/session_providers.dart';
import 'timer_state.dart';

class TimerController extends StateNotifier<TimerState> {
  TimerController(this.ref) : super(TimerState.idle());
  final Ref ref;
  Timer? _ticker;

  // 프리셋 선택 (모드/분)
  void setPreset(String mode, int minutes) {
    _stopTicker();
    state = TimerState.idle(mode: mode, minutes: minutes);
  }

  Future<void> toggleStartStop() async {
    if (state.isRunning) {
      // Stop (일시정지)
      _stopTicker();
      state = state.copyWith(isRunning: false);
      return;
    }

    // Start
    if (state.remainingSeconds <= 0) return;
    state = state.copyWith(
      isRunning: true,
      startTime: state.startTime ?? DateTime.now(),
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  // 리셋
  void reset() {
    _stopTicker();
    state = TimerState.idle(mode: state.mode, minutes: state.totalSeconds ~/ 60);
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  Future<void> _tick() async {
    final next = state.remainingSeconds - 1;
    if (next > 0) {
      state = state.copyWith(remainingSeconds: next);
      return;
    }
    // 완료
    _stopTicker();
    final repo = ref.read(sessionRepoProvider);
    final now = DateTime.now();
    final start = state.startTime ?? now.subtract(Duration(seconds: state.totalSeconds));
    final s = Session()
      ..mode = state.mode
      ..durationSeconds = state.totalSeconds
      ..startTime = start
      ..endTime = now
      ..note = 'timer';
    await repo.add(s);
    // 완료 후 초기화 (같은 프리셋으로 대기)
    state = TimerState.idle(mode: state.mode, minutes: state.totalSeconds ~/ 60);
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }
}

// Riverpod 프로바이더
final timerControllerProvider =
StateNotifierProvider<TimerController, TimerState>((ref) {
  return TimerController(ref);
});
