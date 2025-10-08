import 'package:isar/isar.dart';

part 'change_log.g.dart';

@collection
class ChangeLog {
  Id id = Isar.autoIncrement;

  late String entity;

  late int entityId;

  /// 'created' | 'updated' | 'deleted'
  @Index()
  late String action;

  DateTime occurredAt = DateTime.now().toUtc();

  bool processed = false;
}
