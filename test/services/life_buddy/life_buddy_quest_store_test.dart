import 'package:flutter_test/flutter_test.dart';
import 'package:life_app/services/life_buddy/life_buddy_quest_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('tracks claims per quest id independently', () async {
    final store = LifeBuddyQuestStore();
    final now = DateTime(2025, 1, 2, 8);

    await store.markClaimed(now, questId: LifeBuddyQuestStore.defaultQuestId);
    expect(
      await store.hasClaimedToday(
        now,
        questId: LifeBuddyQuestStore.defaultQuestId,
      ),
      isTrue,
    );
    expect(
      await store.hasClaimedToday(now, questId: 'weekend_relax'),
      isFalse,
    );

    await store.markClaimed(now, questId: 'weekend_relax');
    expect(
      await store.hasClaimedToday(now, questId: 'weekend_relax'),
      isTrue,
    );

    final tomorrow = now.add(const Duration(days: 1));
    expect(
      await store.hasClaimedToday(
        tomorrow,
        questId: LifeBuddyQuestStore.defaultQuestId,
      ),
      isFalse,
    );
  });

  test('honors legacy single-key storage for default quest', () async {
    final legacyDate = DateTime(2025, 1, 3);
    SharedPreferences.setMockInitialValues({
      'life_buddy_last_quest_claim_iso': legacyDate.toIso8601String(),
    });
    final store = LifeBuddyQuestStore();

    expect(
      await store.hasClaimedToday(
        legacyDate,
        questId: LifeBuddyQuestStore.defaultQuestId,
      ),
      isTrue,
    );

    await store.markClaimed(legacyDate, questId: 'alternate_quest');
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('life_buddy_last_quest_claim_iso'),
      isNull,
    );
  });

  test('clear clears specific quest or all quests', () async {
    final store = LifeBuddyQuestStore();
    final now = DateTime(2025, 2, 1);

    await store.markClaimed(now, questId: 'quest_a');
    await store.markClaimed(now, questId: 'quest_b');

    await store.clear(questId: 'quest_a');
    expect(await store.hasClaimedToday(now, questId: 'quest_a'), isFalse);
    expect(await store.hasClaimedToday(now, questId: 'quest_b'), isTrue);

    await store.clear();
    expect(await store.hasClaimedToday(now, questId: 'quest_b'), isFalse);
  });
}
