import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/session.dart';
import '../repositories/session_repository.dart';
import '../utils/date_range.dart';
import 'db_provider.dart';

final sessionRepoProvider = Provider<SessionRepository>((ref) {
  final isar = ref.watch(isarProvider).requireValue;
  return SessionRepository(isar);
});

enum SessionFilter { all, today, week }

final sessionFilterProvider = StateProvider<SessionFilter>((_) => SessionFilter.all);

final sessionsStreamProvider = StreamProvider<List<Session>>((ref) {
  final repo = ref.watch(sessionRepoProvider);
  final filter = ref.watch(sessionFilterProvider);
  switch (filter) {
    case SessionFilter.all:
      return repo.watchAll();
    case SessionFilter.today:
      final r = todayRange();
      return repo.watchInRange(r.start, r.end);
    case SessionFilter.week:
      final r = thisWeekRange();
      return repo.watchInRange(r.start, r.end);
  }
});

final addDemoSessionProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(sessionRepoProvider);
  final now = DateTime.now();
  final s = Session()
    ..mode = 'focus'
    ..durationSeconds = 25 * 60
    ..startTime = now
    ..endTime = now.add(const Duration(minutes: 25))
    ..note = 'demo';
  await repo.add(s);
});

final deleteSessionProvider = FutureProvider.family<void, Id>((ref, id) async {
  final repo = ref.watch(sessionRepoProvider);
  await repo.deleteById(id);
});
