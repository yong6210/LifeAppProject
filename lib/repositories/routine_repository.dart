import 'package:isar/isar.dart';
import 'package:life_app/models/routine.dart';

class RoutineRepository {
  RoutineRepository(this.isar);

  final Isar isar;

  Stream<List<Routine>> watchAll() {
    return isar.routines.where().sortByCreatedAtDesc().watch(
      fireImmediately: true,
    );
  }

  Future<List<Routine>> getAll() async {
    return isar.routines.where().sortByCreatedAtDesc().findAll();
  }

  Future<Routine?> getById(int id) async {
    return isar.routines.get(id);
  }

  Future<int> upsert(Routine routine) async {
    routine.updatedAt = DateTime.now().toUtc();
    return isar.writeTxn(() async {
      routine.id = await isar.routines.put(routine);
      return routine.id;
    });
  }

  Future<void> delete(int id) async {
    await isar.writeTxn(() async {
      await isar.routines.delete(id);
    });
  }

  Future<void> clear() async {
    await isar.writeTxn(() async {
      await isar.routines.clear();
    });
  }
}
