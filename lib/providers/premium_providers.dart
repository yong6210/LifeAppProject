import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/services/premium/premium_routine.dart';

final premiumRoutineCatalogProvider = Provider<PremiumRoutineCatalog>((ref) {
  return const PremiumRoutineCatalog();
});

final premiumFocusRoutinesProvider = Provider<List<PremiumRoutine>>((ref) {
  final catalog = ref.watch(premiumRoutineCatalogProvider);
  return catalog.routinesFor(PremiumRoutineMode.focus);
});

final premiumRestRoutinesProvider = Provider<List<PremiumRoutine>>((ref) {
  final catalog = ref.watch(premiumRoutineCatalogProvider);
  return catalog.routinesFor(PremiumRoutineMode.rest);
});

final premiumSleepRoutinesProvider = Provider<List<PremiumRoutine>>((ref) {
  final catalog = ref.watch(premiumRoutineCatalogProvider);
  return catalog.routinesFor(PremiumRoutineMode.sleep);
});
