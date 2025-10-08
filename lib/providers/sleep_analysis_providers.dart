import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:life_app/services/audio/sleep_sound_analyzer.dart';
import 'package:life_app/services/audio/sleep_sound_store.dart';

/// Provides the most recently persisted [SleepSoundSummary]. If no analysis has
/// been recorded yet, `null` is returned so the UI can show an empty state.
final latestSleepSoundSummaryProvider =
    FutureProvider<SleepSoundSummary?>((ref) async {
  final store = ref.watch(sleepSoundSummaryStoreProvider);
  return store.loadLatest();
});

/// Persists a new [SleepSoundSummary] so it becomes available via
/// [latestSleepSoundSummaryProvider]. This can be invoked after
/// [SleepSoundAnalyzer.stop] completes.
final saveSleepSoundSummaryProvider =
    FutureProvider.family<void, SleepSoundSummary>((ref, summary) async {
  final store = ref.watch(sleepSoundSummaryStoreProvider);
  await store.saveLatest(summary);
});
