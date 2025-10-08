import 'package:isar/isar.dart';
import 'package:life_app/models/change_log.dart';

class ChangeLogRepository {
  ChangeLogRepository(this.isar);

  final Isar isar;

  Stream<List<ChangeLog>> watchUnprocessed({int limit = 100}) {
    return isar.changeLogs
        .filter()
        .processedEqualTo(false)
        .sortByOccurredAt()
        .limit(limit)
        .watch(fireImmediately: true);
  }

  Future<List<ChangeLog>> fetchUnprocessed({int limit = 100}) {
    return isar.changeLogs
        .filter()
        .processedEqualTo(false)
        .sortByOccurredAt()
        .limit(limit)
        .findAll();
  }

  Future<void> markProcessed(List<int> ids) async {
    if (ids.isEmpty) return;
    await isar.writeTxn(() async {
      for (final id in ids) {
        final log = await isar.changeLogs.get(id);
        if (log == null) continue;
        log.processed = true;
        await isar.changeLogs.put(log);
      }
    });
  }

  Future<void> clearProcessed() async {
    await isar.writeTxn(() async {
      await isar.changeLogs.filter().processedEqualTo(true).deleteAll();
    });
  }
}
