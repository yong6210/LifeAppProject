import 'package:isar/isar.dart';

part 'session.g.dart';

@collection
class Session {
  Id id = Isar.autoIncrement;

  /// 'focus' | 'rest' | 'workout' | 'sleep'
  late String mode;

  /// 초 단위 기록 (예: 1500 = 25분)
  late int durationSeconds;

  late DateTime startTime;
  late DateTime endTime;

  String? note;
}
