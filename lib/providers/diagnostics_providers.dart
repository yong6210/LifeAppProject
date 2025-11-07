import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:life_app/services/diagnostics/timer_diagnostics_service.dart';

final timerDiagnosticsServiceProvider = FutureProvider<TimerDiagnosticsService>(
  (ref) async {
    return TimerDiagnosticsService.create();
  },
);

final timerAccuracySamplesProvider = FutureProvider<List<TimerAccuracySample>>((
  ref,
) async {
  final service = await ref.watch(timerDiagnosticsServiceProvider.future);
  return service.loadAccuracySamples();
});
