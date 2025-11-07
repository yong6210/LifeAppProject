import 'dart:math';

import 'package:life_app/features/life_buddy/life_buddy_config.dart';
import 'package:life_app/features/life_buddy/life_buddy_models.dart';

class LifeBuddyService {
  LifeBuddyService({List<DecorItem>? catalog})
    : _catalogById = {
        for (final item in catalog ?? kDecorCatalog) item.id: item,
      };

  final Map<String, DecorItem> _catalogById;

  LifeBuddyMood evaluateMood({
    required int focusMinutes,
    required int sleepMinutes,
    required int restMinutes,
  }) {
    final totalScore = focusMinutes + sleepMinutes + restMinutes;
    if (totalScore <= 0) {
      return LifeBuddyMood.depleted;
    }
    final focusShare = focusMinutes / totalScore;
    final sleepShare = sleepMinutes / totalScore;
    final restShare = restMinutes / totalScore;

    if (sleepShare < 0.25 || totalScore < 60) {
      return LifeBuddyMood.depleted;
    }
    if (sleepShare < 0.35 || focusShare > 0.55) {
      return LifeBuddyMood.low;
    }
    if (sleepShare > 0.45 && restShare > 0.15 && totalScore >= 240) {
      return LifeBuddyMood.radiant;
    }
    if (sleepShare > 0.4 && totalScore >= 180) {
      return LifeBuddyMood.thriving;
    }
    return LifeBuddyMood.steady;
  }

  Map<LifeBuffType, double> aggregateBuffs(RoomLoadout loadout) {
    final Map<LifeBuffType, double> totals = {};
    for (final entry in loadout.equipped.entries) {
      final item = _catalogById[entry.value];
      if (item == null) continue;
      for (final buff in item.buffs) {
        totals.update(
          buff.type,
          (value) => value + buff.value,
          ifAbsent: () => buff.value,
        );
      }
    }
    return totals;
  }

  Map<LifeBuffType, double> aggregateCollectionBuffs(
    Iterable<String> decorIds,
  ) {
    final Map<LifeBuffType, double> totals = {};
    for (final id in {...decorIds}) {
      final item = _catalogById[id];
      if (item == null) continue;
      for (final buff in item.buffs) {
        totals.update(
          buff.type,
          (value) => value + buff.value,
          ifAbsent: () => buff.value,
        );
      }
    }
    return totals;
  }

  double effectiveMultiplier(
    LifeBuffType type,
    RoomLoadout loadout, {
    double base = 1.0,
  }) {
    final totals = aggregateBuffs(loadout);
    final additive = totals[type] ?? 0.0;
    return base + additive;
  }

  double experienceForNextLevel(int level) {
    const base = 100.0;
    return base * pow(level, 1.25);
  }

  DecorItem? lookupDecor(String itemId) => _catalogById[itemId];

  Iterable<DecorItem> catalogForSlot(DecorSlot slot) =>
      _catalogById.values.where((item) => item.slot == slot);

  List<DecorItem> upcomingDecor({required int currentLevel, int limit = 3}) {
    final sorted =
        _catalogById.values
            .where((item) => item.unlockLevel > currentLevel)
            .toList()
          ..sort((a, b) {
            final levelCompare = a.unlockLevel.compareTo(b.unlockLevel);
            if (levelCompare != 0) return levelCompare;
            return a.costCoins.compareTo(b.costCoins);
          });
    if (limit <= 0) {
      return sorted;
    }
    return sorted.take(limit).toList();
  }
}
