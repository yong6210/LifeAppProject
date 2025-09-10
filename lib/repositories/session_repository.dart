import 'package:isar/isar.dart';
import '../models/session.dart';

class SessionRepository {
  final Isar isar;
  SessionRepository(this.isar);

  Stream<List<Session>> watchAll() {
    return isar.sessions.where().sortByStartTimeDesc().watch(fireImmediately: true);
  }

  Stream<List<Session>> watchInRange(DateTime start, DateTime end) {
    return isar.sessions
        .filter()
        .startTimeGreaterThan(start, include: true)
        .and()
        .startTimeLessThan(end, include: false)
        .sortByStartTimeDesc()
        .watch(fireImmediately: true);
  }

  Future<int> count() => isar.sessions.count();

  Future<void> add(Session s) async {
    await isar.writeTxn(() async {
      await isar.sessions.put(s);
    });
  }

  Future<void> deleteById(Id id) async {
    await isar.writeTxn(() async {
      await isar.sessions.delete(id);
    });
  }

  Future<void> clearAll() async {
    await isar.writeTxn(() async {
      await isar.sessions.clear();
    });
  }
}
