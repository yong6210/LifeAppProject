import 'package:isar/isar.dart';

part 'daily_summary_local.g.dart';

@collection
class DailySummaryLocal {
  Id id = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('deviceId')], unique: true)
  late DateTime date;

  late String deviceId;

  int focusMinutes = 0;
  int restMinutes = 0;
  int workoutMinutes = 0;
  int sleepMinutes = 0;

  DateTime updatedAt = DateTime.now().toUtc();
}
