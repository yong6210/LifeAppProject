enum LifeBuddyMood { depleted, low, steady, thriving, radiant }

enum DecorSlot { bed, desk, lighting, wall, floor, accent }

enum LifeBuffType {
  focusXpMultiplier,
  restRecoveryMultiplier,
  sleepQualityBonus,
}

class DecorBuff {
  const DecorBuff({required this.type, required this.value});

  final LifeBuffType type;
  final double value;
}

class DecorItem {
  const DecorItem({
    required this.id,
    required this.slot,
    required this.name,
    required this.description,
    required this.costCoins,
    required this.unlockLevel,
    this.requiresPremium = false,
    this.buffs = const <DecorBuff>[],
  });

  final String id;
  final DecorSlot slot;
  final String name;
  final String description;
  final int costCoins;
  final int unlockLevel;
  final bool requiresPremium;
  final List<DecorBuff> buffs;
}

class RoomLoadout {
  const RoomLoadout({required this.equipped});

  final Map<DecorSlot, String> equipped;

  RoomLoadout unequip(DecorSlot slot) {
    final updated = Map<DecorSlot, String>.from(equipped)..remove(slot);
    return RoomLoadout(equipped: updated);
  }

  RoomLoadout equip(DecorSlot slot, String itemId) {
    final updated = Map<DecorSlot, String>.from(equipped)..[slot] = itemId;
    return RoomLoadout(equipped: updated);
  }
}

class LifeBuddyState {
  const LifeBuddyState({
    required this.level,
    required this.experience,
    required this.mood,
    required this.room,
  });

  final int level;
  final double experience;
  final LifeBuddyMood mood;
  final RoomLoadout room;

  LifeBuddyState copyWith({
    int? level,
    double? experience,
    LifeBuddyMood? mood,
    RoomLoadout? room,
  }) {
    return LifeBuddyState(
      level: level ?? this.level,
      experience: experience ?? this.experience,
      mood: mood ?? this.mood,
      room: room ?? this.room,
    );
  }
}
