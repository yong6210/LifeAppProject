import 'package:isar/isar.dart';

part 'routine.g.dart';

@collection
class Routine {
  Id id = Isar.autoIncrement;

  late String name;

  List<RoutineStep> steps = [];

  String colorTheme = 'default';

  DateTime createdAt = DateTime.now().toUtc();

  DateTime updatedAt = DateTime.now().toUtc();
}

@embedded
class RoutineStep {
  /// 'focus' | 'rest' | 'workout' | 'sleep'
  String mode = 'focus';

  int durationMinutes = 25;

  bool playSound = false;

  String? soundId;
}
