import 'package:flutter_test/flutter_test.dart';
import 'package:life_app/features/life_buddy/life_buddy_models.dart';
import 'package:life_app/features/life_buddy/life_buddy_service.dart';

void main() {
  final service = LifeBuddyService();

  group('LifeBuddyService mood evaluation', () {
    test('returns depleted when total activity is too low', () {
      final mood = service.evaluateMood(
        focusMinutes: 10,
        sleepMinutes: 20,
        restMinutes: 5,
      );
      expect(mood, LifeBuddyMood.depleted);
    });

    test('returns radiant for well-balanced day', () {
      final mood = service.evaluateMood(
        focusMinutes: 180,
        sleepMinutes: 360,
        restMinutes: 110,
      );
      expect(mood, LifeBuddyMood.radiant);
    });

    test('returns thriving when sleep share is high enough', () {
      final mood = service.evaluateMood(
        focusMinutes: 120,
        sleepMinutes: 340,
        restMinutes: 40,
      );
      expect(mood, LifeBuddyMood.thriving);
    });
  });

  group('LifeBuddyService buffs', () {
    test('aggregates buffs from equipped decor', () {
      final loadout = RoomLoadout(
        equipped: {
          DecorSlot.bed: 'bed_basic',
          DecorSlot.accent: 'plant_companion',
        },
      );
      final buffs = service.aggregateBuffs(loadout);
      expect(buffs[LifeBuffType.sleepQualityBonus], closeTo(0.04, 1e-6));
      expect(buffs[LifeBuffType.restRecoveryMultiplier], closeTo(0.03, 1e-6));
    });

    test('effectiveMultiplier returns base plus aggregate', () {
      final loadout = RoomLoadout(
        equipped: {
          DecorSlot.desk: 'desk_focus',
          DecorSlot.wall: 'poster_motivation',
        },
      );
      final multiplier = service.effectiveMultiplier(
        LifeBuffType.focusXpMultiplier,
        loadout,
      );
      expect(multiplier, closeTo(1.08, 1e-6));
    });

    test('aggregateCollectionBuffs sums owned decor buffs', () {
      final totals = service.aggregateCollectionBuffs({
        'bed_basic',
        'plant_companion',
      });
      expect(totals[LifeBuffType.sleepQualityBonus], closeTo(0.04, 1e-6));
      expect(totals[LifeBuffType.restRecoveryMultiplier], closeTo(0.03, 1e-6));
    });

    test('aggregateCollectionBuffs ignores unknown or duplicate ids', () {
      final totals = service.aggregateCollectionBuffs(
        ['desk_focus', 'desk_focus', 'unknown_item'],
      );
      expect(totals[LifeBuffType.focusXpMultiplier], closeTo(0.05, 1e-6));
      expect(totals.containsKey(LifeBuffType.sleepQualityBonus), isFalse);
    });
  });

  group('LifeBuddyService upcomingDecor', () {
    test('returns items above current level in ascending order', () {
      final items = service.upcomingDecor(currentLevel: 2, limit: 3);
      expect(items, hasLength(3));
      expect(items.first.id, 'poster_motivation');
      expect(items.first.unlockLevel, greaterThan(2));
      expect(
        items[1].unlockLevel,
        greaterThanOrEqualTo(items.first.unlockLevel),
      );
    });

    test('honors limit parameter and allows unlimited when <= 0', () {
      final limited = service.upcomingDecor(currentLevel: 4, limit: 1);
      expect(limited, hasLength(1));
      final unlimited = service.upcomingDecor(currentLevel: 4, limit: 0);
      expect(unlimited.length, greaterThanOrEqualTo(limited.length));
    });
  });
}
