import 'package:isar/isar.dart';

part 'session.g.dart';

@collection
class Session {
  Id id = Isar.autoIncrement;

  /// 'focus' | 'rest' | 'workout' | 'sleep'
  @Index()
  late String type;

  @Index()
  late DateTime startedAt;

  DateTime? endedAt;

  @Index()
  late DateTime localDate;

  @Index(type: IndexType.hash)
  late String deviceId;

  @Index(type: IndexType.hash)
  String? navigatorRouteId;

  String? navigatorTargetType;

  double? navigatorTargetValue;

  bool? navigatorVoiceEnabled;

  List<String> tags = [];

  String? note;

  DateTime createdAt = DateTime.now().toUtc();

  DateTime updatedAt = DateTime.now().toUtc();
}
