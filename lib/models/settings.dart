import 'package:isar/isar.dart';

part 'settings.g.dart';

@collection
class Settings {
  /// 단일 레코드만 쓸 거라 id=0 고정
  Id id = 0;

  bool darkMode = true;
  String language = 'ko';
  int pomodoroMinutes = 25;
  int restMinutes = 5;
}
