import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/features/life_buddy/life_buddy_models.dart';
import 'package:life_app/features/life_buddy/life_buddy_service.dart';
import 'package:life_app/providers/life_buddy_providers.dart';
import 'package:life_app/providers/stats_providers.dart';
import 'package:life_app/repositories/life_buddy_repository.dart';

final lifeBuddyStateProvider =
    AsyncNotifierProvider<LifeBuddyStateController, LifeBuddyState>(
      LifeBuddyStateController.new,
    );

class LifeBuddyStateController extends AsyncNotifier<LifeBuddyState> {
  late final LifeBuddyService _service;
  late final LifeBuddyRepository _repository;
  StreamSubscription<LifeBuddyState>? _subscription;

  @override
  Future<LifeBuddyState> build() async {
    _service = ref.read(lifeBuddyServiceProvider);
    _repository = await ref.watch(lifeBuddyRepositoryProvider.future);

    ref.listen<AsyncValue<SummaryTotals>>(dailyTotalsProvider, (
      previous,
      next,
    ) {
      next.whenData(_updateMoodFromTotals);
    });

    final initial = await _repository.ensure();

    _subscription = _repository.watch().listen((value) {
      state = AsyncData(value);
    });
    ref.onDispose(() {
      _subscription?.cancel();
    });

    return initial;
  }

  Future<void> _updateMoodFromTotals(SummaryTotals totals) async {
    final current = state.value;
    if (current == null) return;
    final mood = _service.evaluateMood(
      focusMinutes: totals.focusMinutes,
      sleepMinutes: totals.sleepMinutes,
      restMinutes: totals.restMinutes,
    );
    if (current.mood != mood) {
      final updated = current.copyWith(mood: mood);
      await _persist(updated);
    }
  }

  Future<void> addExperience(double delta) async {
    if (delta <= 0) return;
    final current = state.value;
    if (current == null) return;
    var level = current.level;
    var xp = current.experience + delta;
    var threshold = _service.experienceForNextLevel(level);
    while (xp >= threshold) {
      xp -= threshold;
      level += 1;
      threshold = _service.experienceForNextLevel(level);
    }
    final updated = current.copyWith(level: level, experience: xp);
    await _persist(updated);
  }

  bool canEquip(DecorItem item, {required bool isPremiumUser}) {
    final current = state.value;
    if (current == null) return false;
    if (item.requiresPremium && !isPremiumUser) return false;
    return current.level >= item.unlockLevel;
  }

  Future<void> equipItem(DecorItem item, {required bool isPremiumUser}) async {
    final current = state.value;
    if (current == null) return;
    if (!canEquip(item, isPremiumUser: isPremiumUser)) {
      return;
    }
    final updated = current.copyWith(
      room: current.room.equip(item.slot, item.id),
    );
    await _persist(updated);
  }

  Future<void> unequipSlot(DecorSlot slot) async {
    final current = state.value;
    if (current == null) return;
    if (!current.room.equipped.containsKey(slot)) return;
    final updated = current.copyWith(room: current.room.unequip(slot));
    await _persist(updated);
  }

  Future<void> _persist(LifeBuddyState updated) async {
    state = AsyncData(updated);
    await _repository.save(updated);
  }
}

final lifeBuddyBuffsProvider = Provider<Map<LifeBuffType, double>>((ref) {
  final service = ref.watch(lifeBuddyServiceProvider);
  final stateAsync = ref.watch(lifeBuddyStateProvider);
  final inventoryAsync = ref.watch(lifeBuddyInventoryProvider);

  Map<LifeBuffType, double> fallback() {
    return stateAsync.maybeWhen(
      data: (state) => service.aggregateBuffs(state.room),
      orElse: () => const <LifeBuffType, double>{},
    );
  }

  return inventoryAsync.maybeWhen(
    data: (inventory) {
      final totals = service.aggregateCollectionBuffs(inventory.ownedDecorIds);
      if (totals.isEmpty) {
        return fallback();
      }
      return totals;
    },
    orElse: fallback,
  );
});
