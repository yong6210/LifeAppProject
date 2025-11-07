import 'package:isar/isar.dart';
import 'package:life_app/features/life_buddy/life_buddy_models.dart';
import 'package:life_app/models/change_log.dart';
import 'package:life_app/models/life_buddy_state_local.dart';

class LifeBuddyRepository {
  LifeBuddyRepository(this._isar);

  final Isar _isar;

  Future<LifeBuddyState> ensure() async {
    final existing = await _isar.lifeBuddyStateLocals.get(0);
    if (existing != null) {
      return _toDomain(existing);
    }

    final created = LifeBuddyStateLocal()
      ..id = 0
      ..createdAt = DateTime.now().toUtc()
      ..updatedAt = DateTime.now().toUtc();

    await _isar.writeTxn(() async {
      await _isar.lifeBuddyStateLocals.put(created);
    });
    return _toDomain(created);
  }

  Future<void> save(LifeBuddyState state) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.lifeBuddyStateLocals.get(0);
      final now = DateTime.now().toUtc();
      final record = LifeBuddyStateLocal()
        ..id = 0
        ..level = state.level
        ..experience = state.experience
        ..mood = state.mood.name
        ..equippedSlots = state.room.equipped.entries.map((entry) {
          return EquippedSlot()
            ..slot = entry.key.name
            ..itemId = entry.value;
        }).toList()
        ..createdAt = existing?.createdAt ?? now
        ..updatedAt = now;

      await _isar.lifeBuddyStateLocals.put(record);
      await _isar.changeLogs.put(
        ChangeLog()
          ..entity = LifeBuddyStateLocalSchema.name
          ..entityId = 0
          ..action = 'updated'
          ..occurredAt = now,
      );
    });
  }

  Stream<LifeBuddyState> watch() {
    return _isar.lifeBuddyStateLocals.watchObject(0, fireImmediately: true).map(
      (local) {
        if (local == null) {
          return const LifeBuddyState(
            level: 1,
            experience: 0,
            mood: LifeBuddyMood.steady,
            room: RoomLoadout(equipped: {}),
          );
        }
        return _toDomain(local);
      },
    );
  }

  Future<LifeBuddyState> current() async {
    final local = await _isar.lifeBuddyStateLocals.get(0);
    if (local == null) {
      return const LifeBuddyState(
        level: 1,
        experience: 0,
        mood: LifeBuddyMood.steady,
        room: RoomLoadout(equipped: {}),
      );
    }
    return _toDomain(local);
  }

  Future<void> replaceFromRemote(
    LifeBuddyState state, {
    DateTime? updatedAt,
  }) async {
    final remoteUpdatedAt = (updatedAt ?? DateTime.now()).toUtc();
    await _isar.writeTxn(() async {
      final existing = await _isar.lifeBuddyStateLocals.get(0);
      if (existing != null && existing.updatedAt.isAfter(remoteUpdatedAt)) {
        return;
      }
      final record = LifeBuddyStateLocal()
        ..id = 0
        ..level = state.level
        ..experience = state.experience
        ..mood = state.mood.name
        ..equippedSlots = state.room.equipped.entries.map((entry) {
          return EquippedSlot()
            ..slot = entry.key.name
            ..itemId = entry.value;
        }).toList()
        ..createdAt = existing?.createdAt ?? remoteUpdatedAt
        ..updatedAt = remoteUpdatedAt;
      await _isar.lifeBuddyStateLocals.put(record);
    });
  }

  LifeBuddyStateLocal? getLocalSync() {
    return _isar.lifeBuddyStateLocals.getSync(0);
  }

  Future<LifeBuddyState> saveAndReturn(LifeBuddyState state) async {
    await save(state);
    return state;
  }

  LifeBuddyState _toDomain(LifeBuddyStateLocal local) {
    return LifeBuddyState(
      level: local.level,
      experience: local.experience,
      mood: _decodeMood(local.mood),
      room: RoomLoadout(
        equipped: {
          for (final slot in local.equippedSlots)
            _decodeSlot(slot.slot): slot.itemId,
        },
      ),
    );
  }

  LifeBuddyMood _decodeMood(String name) {
    return LifeBuddyMood.values.firstWhere(
      (mood) => mood.name == name,
      orElse: () => LifeBuddyMood.steady,
    );
  }

  DecorSlot _decodeSlot(String name) {
    return DecorSlot.values.firstWhere(
      (slot) => slot.name == name,
      orElse: () => DecorSlot.accent,
    );
  }
}
