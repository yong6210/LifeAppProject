import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/features/life_buddy/life_buddy_models.dart';
import 'package:life_app/features/life_buddy/life_buddy_quest_ui.dart';
import 'package:life_app/features/life_buddy/life_buddy_page.dart';
import 'package:life_app/features/life_buddy/life_buddy_state_controller.dart';
import 'package:life_app/features/life_buddy/life_buddy_service.dart';
import 'package:life_app/providers/life_buddy_providers.dart';
import 'package:life_app/services/life_buddy/life_buddy_remote_service.dart';
import 'package:life_app/services/life_buddy/life_buddy_quest_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:life_app/services/subscription/revenuecat_service.dart';

class _FakeLifeBuddyController extends LifeBuddyStateController {
  _FakeLifeBuddyController(this._state);

  final LifeBuddyState _state;

  @override
  Future<LifeBuddyState> build() async => _state;
}

class _FakeRemoteService extends LifeBuddyRemoteService {
  bool called = false;
  String? lastQuestId;

  @override
  Future<ClaimQuestResult> claimDailyQuest(String questId) async {
    called = true;
    lastQuestId = questId;
    return ClaimQuestResult(ok: true, questId: questId, coinsRewarded: 20);
  }
}

class _FakeQuestStore extends LifeBuddyQuestStore {
  bool claimed = false;
  String? markedQuestId;

  _FakeQuestStore() : super();

  @override
  Future<bool> hasClaimedToday(
    DateTime now, {
    String questId = LifeBuddyQuestStore.defaultQuestId,
  }) async => claimed;

  @override
  Future<void> markClaimed(
    DateTime now, {
    String questId = LifeBuddyQuestStore.defaultQuestId,
  }) async {
    claimed = true;
    markedQuestId = questId;
  }

  @override
  Future<void> clear({String? questId}) async {
    claimed = false;
    markedQuestId = null;
  }
}

class _FakeInventoryController extends LifeBuddyInventoryController {
  _FakeInventoryController(this._inventory);

  final LifeBuddyInventory _inventory;

  @override
  Future<LifeBuddyInventory> build() async => _inventory;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const sampleState = LifeBuddyState(
    level: 5,
    experience: 40,
    mood: LifeBuddyMood.radiant,
    room: RoomLoadout(equipped: {DecorSlot.bed: 'bed_basic'}),
  );

  final sampleBuffs = {
    LifeBuffType.focusXpMultiplier: 0.1,
    LifeBuffType.sleepQualityBonus: 0.05,
  };

  const premiumStatus = PremiumStatus(
    isPremium: true,
    usesCachedValue: false,
    hasCachedValue: true,
    isLoading: false,
    revenueCatAvailable: true,
    isInGracePeriod: false,
    gracePeriodEndsAt: null,
    expirationDate: null,
    isExpired: false,
  );

  const sampleInventory = LifeBuddyInventory(
    ownedDecorIds: {'bed_basic', 'desk_focus'},
    coins: 250,
    isPremiumUser: true,
  );

  testWidgets('LifeBuddyPage renders mood, level, and buffs', (tester) async {
    final remoteService = _FakeRemoteService();
    final questStore = _FakeQuestStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lifeBuddyStateProvider.overrideWith(
            () => _FakeLifeBuddyController(sampleState),
          ),
          lifeBuddyBuffsProvider.overrideWithValue(sampleBuffs),
          lifeBuddyServiceProvider.overrideWithValue(LifeBuddyService()),
          premiumStatusProvider.overrideWithValue(premiumStatus),
          lifeBuddyRemoteServiceProvider.overrideWithValue(remoteService),
          lifeBuddyQuestClaimingProvider.overrideWithValue(
            ValueNotifier(false),
          ),
          lifeBuddyQuestStoreProvider.overrideWithValue(questStore),
          lifeBuddyQuestStatusProvider.overrideWith(
            (ref) async => !questStore.claimed,
          ),
          lifeBuddyInventoryProvider.overrideWith(
            () => _FakeInventoryController(sampleInventory),
          ),
        ],
        child: const MaterialApp(home: LifeBuddyPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('라이프 버디'), findsOneWidget);
    expect(find.text('레벨 5'), findsWidgets);
    expect(find.text('집중 XP +10%'), findsOneWidget);
    expect(find.text('나의 코인 현황'), findsOneWidget);
    expect(find.text('일일 퀘스트 보상 받기'), findsWidgets);
    expect(find.text('다가오는 해금 보상'), findsOneWidget);

    final questButton = find.text('일일 퀘스트 보상 받기').first;
    await tester.ensureVisible(questButton);
    final buttonWidget = tester.widget<FilledButton>(
      find.ancestor(of: questButton, matching: find.byType(FilledButton)),
    );
    buttonWidget.onPressed?.call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(remoteService.called, isTrue);
    expect(remoteService.lastQuestId, LifeBuddyQuestStore.defaultQuestId);
    expect(questStore.claimed, isTrue);
    expect(questStore.markedQuestId, LifeBuddyQuestStore.defaultQuestId);
  });

  testWidgets('Quest claim button disables when already claimed', (
    tester,
  ) async {
    final questStore = _FakeQuestStore()..claimed = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lifeBuddyStateProvider.overrideWith(
            () => _FakeLifeBuddyController(sampleState),
          ),
          lifeBuddyBuffsProvider.overrideWithValue(sampleBuffs),
          lifeBuddyServiceProvider.overrideWithValue(LifeBuddyService()),
          premiumStatusProvider.overrideWithValue(premiumStatus),
          lifeBuddyRemoteServiceProvider.overrideWithValue(
            _FakeRemoteService(),
          ),
          lifeBuddyQuestClaimingProvider.overrideWithValue(
            ValueNotifier(false),
          ),
          lifeBuddyQuestStoreProvider.overrideWithValue(questStore),
          lifeBuddyQuestStatusProvider.overrideWith((ref) async => false),
          lifeBuddyInventoryProvider.overrideWith(
            () => _FakeInventoryController(sampleInventory),
          ),
        ],
        child: const MaterialApp(home: LifeBuddyPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('오늘 보상은 이미 받았어요.'), findsWidgets);
    expect(find.text('다가오는 해금 보상'), findsOneWidget);
    final questButton = find.byType(QuestClaimButton).first;
    final questButtonWidget = tester.widget<QuestClaimButton>(questButton);
    expect(questButtonWidget.canClaim, isFalse);

    final filledButton = find.descendant(
      of: questButton,
      matching: find.byType(FilledButton),
    );
    final buttonWidget = tester.widget<FilledButton>(filledButton);
    expect(buttonWidget.onPressed, isNull);
  });
}
