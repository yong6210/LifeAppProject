import 'package:isar/isar.dart';

part 'life_buddy_state_local.g.dart';

@collection
class LifeBuddyStateLocal {
  Id id = 0;

  int level = 1;

  double experience = 0;

  String mood = 'steady';

  List<EquippedSlot> equippedSlots = [];

  DateTime createdAt = DateTime.now().toUtc();

  DateTime updatedAt = DateTime.now().toUtc();
}

@embedded
class EquippedSlot {
  late String slot;
  late String itemId;
}
