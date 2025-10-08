import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/models/routine.dart';
import 'package:life_app/providers/db_provider.dart';
import 'package:life_app/repositories/routine_repository.dart';

final routineRepositoryProvider = FutureProvider<RoutineRepository>((
  ref,
) async {
  final isar = await ref.watch(isarProvider.future);
  return RoutineRepository(isar);
});

final routinesStreamProvider = StreamProvider<List<Routine>>((ref) {
  final repoAsync = ref.watch(routineRepositoryProvider);
  return repoAsync.when(
    data: (repo) => repo.watchAll(),
    loading: () => Stream.value(const <Routine>[]),
    error: (err, stack) => Stream.error(err, stack),
  );
});
