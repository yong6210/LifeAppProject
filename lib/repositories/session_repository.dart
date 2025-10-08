import 'dart:math' as math;

import 'package:isar/isar.dart';
import 'package:life_app/models/change_log.dart';
import 'package:life_app/models/daily_summary_local.dart';
import 'package:life_app/models/session.dart';

DateTime _dayStart(DateTime value) =>
    DateTime(value.year, value.month, value.day);

ChangeLog _changeLogFor(Session session, String action) => ChangeLog()
  ..entity = SessionSchema.name
  ..entityId = session.id
  ..action = action
  ..occurredAt = DateTime.now().toUtc();

class SessionRepository {
  SessionRepository(this.isar);

  final Isar isar;

  Future<void> add(Session session) async {
    final now = DateTime.now().toUtc();
    session.createdAt = now;
    session.updatedAt = now;
    session.localDate = _dayStart(session.startedAt);

    await isar.writeTxn(() async {
      session.id = await isar.sessions.put(session);
      await _upsertDailySummary(session, increment: true);
      await isar.changeLogs.put(_changeLogFor(session, 'created'));
    });
  }

  Stream<List<Session>> watchAll() {
    final query = isar.sessions.where().sortByStartedAtDesc();
    return query.watch().asyncMap((_) => query.findAll());
  }

  Stream<List<Session>> watchInRange(DateTime start, DateTime end) {
    final query = isar.sessions.where().filter().startedAtBetween(start, end);
    return query.watch().asyncMap((_) => query.findAll());
  }

  Future<int> count() => isar.sessions.count();

  Future<void> deleteById(int id) async {
    await isar.writeTxn(() async {
      final session = await isar.sessions.get(id);
      if (session == null) return;
      await isar.sessions.delete(id);
      await _upsertDailySummary(session, increment: false);
      await isar.changeLogs.put(_changeLogFor(session, 'deleted'));
    });
  }

  Future<void> clearAll() async {
    await isar.writeTxn(() async {
      await isar.sessions.clear();
      await isar.dailySummaryLocals.clear();
      await isar.changeLogs.clear();
    });
  }

  Future<void> _upsertDailySummary(
    Session session, {
    required bool increment,
  }) async {
    final summary = await isar.dailySummaryLocals.getByDateDeviceId(
      session.localDate,
      session.deviceId,
    );

    final duration = (session.endedAt ?? session.startedAt)
        .difference(session.startedAt)
        .inMinutes;
    final minutes = math.max(duration, 0);
    final delta = increment ? minutes : -minutes;

    final target =
        summary ??
        (DailySummaryLocal()
          ..date = session.localDate
          ..deviceId = session.deviceId);

    switch (session.type) {
      case 'focus':
        target.focusMinutes = _bounded(target.focusMinutes + delta);
        break;
      case 'rest':
        target.restMinutes = _bounded(target.restMinutes + delta);
        break;
      case 'workout':
        target.workoutMinutes = _bounded(target.workoutMinutes + delta);
        break;
      case 'sleep':
        target.sleepMinutes = _bounded(target.sleepMinutes + delta);
        break;
      default:
        break;
    }
    target.updatedAt = DateTime.now().toUtc();

    target.id = await isar.dailySummaryLocals.put(target);
    await isar.changeLogs.put(
      ChangeLog()
        ..entity = DailySummaryLocalSchema.name
        ..entityId = target.id
        ..action = 'updated'
        ..occurredAt = DateTime.now().toUtc(),
    );
  }

  int _bounded(int value) => math.max(value, 0);
}
