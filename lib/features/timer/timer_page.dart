import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'timer_controller.dart';
import 'timer_state.dart';

String _mmss(int s) {
  final m = (s ~/ 60).toString().padLeft(2, '0');
  final ss = (s % 60).toString().padLeft(2, '0');
  return '$m:$ss';
}

class TimerPage extends ConsumerWidget {
  const TimerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timerControllerProvider);
    final ctrl = ref.read(timerControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text('Timer • ${state.mode.toUpperCase()}')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 남은 시간
            Text(
              _mmss(state.remainingSeconds),
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // 프리셋 선택
            Wrap(
              spacing: 8,
              children: [
                _PresetChip(label: 'Focus 25', onTap: () => ctrl.setPreset('focus', 25), selected: state.mode=='focus' && state.totalSeconds==25*60),
                _PresetChip(label: 'Rest 5',   onTap: () => ctrl.setPreset('rest', 5),   selected: state.mode=='rest' && state.totalSeconds==5*60),
                _PresetChip(label: 'Workout 20', onTap: () => ctrl.setPreset('workout', 20), selected: state.mode=='workout' && state.totalSeconds==20*60),
                _PresetChip(label: 'Sleep 30', onTap: () => ctrl.setPreset('sleep', 30), selected: state.mode=='sleep' && state.totalSeconds==30*60),
              ],
            ),
            const SizedBox(height: 24),

            // 컨트롤 버튼들
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: state.remainingSeconds > 0 ? ctrl.toggleStartStop : null,
                  icon: Icon(state.isRunning ? Icons.stop : Icons.play_arrow),
                  label: Text(state.isRunning ? 'Stop' : 'Start'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: ctrl.reset,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('완료되면 자동으로 세션이 저장되고 목록 화면에 반영됩니다.'),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onTap, required this.selected});
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
