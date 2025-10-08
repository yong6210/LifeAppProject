import 'package:isar/isar.dart';
import 'package:life_app/models/daily_summary_local.dart';

class DailySummaryRepository {
  DailySummaryRepository(this.isar);

  final Isar isar;

  Stream<List<DailySummaryLocal>> watchBetween(DateTime start, DateTime end) {
    return isar.dailySummaryLocals
        .where()
        .filter()
        .dateBetween(start, end)
        .watch(fireImmediately: true);
  }

  Future<List<DailySummaryLocal>> fetchBetween(DateTime start, DateTime end) {
    return isar.dailySummaryLocals
        .where()
        .filter()
        .dateBetween(start, end)
        .findAll();
  }

  Future<DailySummaryLocal?> get(DateTime date, String deviceId) {
    return isar.dailySummaryLocals.getByDateDeviceId(date, deviceId);
  }

  Future<DailySummaryLocal?> getById(int id) {
    return isar.dailySummaryLocals.get(id);
  }

  Future<void> upsert(DailySummaryLocal summary) async {
    summary.updatedAt = summary.updatedAt.toUtc();
    if (summary.updatedAt.isBefore(DateTime.utc(1970))) {
      summary.updatedAt = DateTime.now().toUtc();
    }
    await isar.writeTxn(() async {
      summary.id = await isar.dailySummaryLocals.put(summary);
    });
  }
}
