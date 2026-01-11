import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:life_app/features/life_buddy/life_buddy_service.dart';
import 'package:life_app/providers/db_provider.dart';
import 'package:life_app/repositories/life_buddy_repository.dart';
import 'package:life_app/services/life_buddy/life_buddy_quest_store.dart';
import 'package:life_app/services/life_buddy/life_buddy_remote_service.dart';
import 'package:life_app/providers/auth_providers.dart';

final lifeBuddyServiceProvider = Provider<LifeBuddyService>((ref) {
  return LifeBuddyService();
});

final lifeBuddyRepositoryProvider = FutureProvider<LifeBuddyRepository>((
  ref,
) async {
  final isar = await ref.watch(isarProvider.future);
  return LifeBuddyRepository(isar);
});

final lifeBuddyRemoteServiceProvider = Provider<LifeBuddyRemoteService>((ref) {
  return LifeBuddyRemoteService();
});

final lifeBuddyQuestClaimingProvider = Provider<ValueNotifier<bool>>((ref) {
  final notifier = ValueNotifier<bool>(false);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final lifeBuddyQuestStoreProvider = Provider<LifeBuddyQuestStore>((ref) {
  return LifeBuddyQuestStore();
});

final lifeBuddyQuestStatusProvider = FutureProvider<bool>((ref) async {
  final store = ref.watch(lifeBuddyQuestStoreProvider);
  final claimed = await store.hasClaimedToday(
    DateTime.now(),
    questId: LifeBuddyQuestStore.defaultQuestId,
  );
  return !claimed;
});

class LifeBuddyInventory {
  const LifeBuddyInventory({
    required this.ownedDecorIds,
    required this.coins,
    required this.isPremiumUser,
  });

  factory LifeBuddyInventory.initial() => const LifeBuddyInventory(
    ownedDecorIds: {'bed_basic'},
    coins: 0,
    isPremiumUser: false,
  );

  factory LifeBuddyInventory.fromMap(Map<String, dynamic>? data) {
    final ownedRaw = data?['owned'];
    final owned = <String>{'bed_basic'};
    if (ownedRaw is Iterable) {
      for (final value in ownedRaw) {
        if (value is String && value.isNotEmpty) {
          owned.add(value);
        }
      }
    }
    final coins = (data?['softCurrency'] as num?)?.toInt() ?? 0;
    final isPremiumUser = data?['isPremiumUser'] == true;
    return LifeBuddyInventory(
      ownedDecorIds: owned,
      coins: coins >= 0 ? coins : 0,
      isPremiumUser: isPremiumUser,
    );
  }

  final Set<String> ownedDecorIds;
  final int coins;
  final bool isPremiumUser;

  LifeBuddyInventory copyWith({
    Set<String>? ownedDecorIds,
    int? coins,
    bool? isPremiumUser,
  }) {
    return LifeBuddyInventory(
      ownedDecorIds: ownedDecorIds ?? this.ownedDecorIds,
      coins: coins ?? this.coins,
      isPremiumUser: isPremiumUser ?? this.isPremiumUser,
    );
  }
}

class LifeBuddyInventoryController extends AsyncNotifier<LifeBuddyInventory> {
  @override
  Future<LifeBuddyInventory> build() async {
    return _fetchInventory();
  }

  Future<LifeBuddyInventory> _fetchInventory() async {
    final auth = ref.read(firebaseAuthProvider);
    if (auth == null) {
      return LifeBuddyInventory.initial();
    }
    final user = auth.currentUser;
    if (user == null) {
      return LifeBuddyInventory.initial();
    }
    try {
      final doc = await FirebaseFirestore.instance
          .doc('users/${user.uid}/decor_inventory/state')
          .get();
      return LifeBuddyInventory.fromMap(doc.data());
    } on FirebaseException {
      return LifeBuddyInventory.initial();
    } catch (_) {
      return LifeBuddyInventory.initial();
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final inventory = await _fetchInventory();
      state = AsyncData(inventory);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> applyUnlock({
    required String decorId,
    int? remainingCoins,
  }) async {
    final current = state.asData?.value ?? await future;
    final updatedOwned = {...current.ownedDecorIds, decorId};
    final updated = current.copyWith(
      ownedDecorIds: updatedOwned,
      coins: remainingCoins ?? current.coins,
    );
    state = AsyncData(updated);
  }

  Future<void> applyQuestReward(int coins) async {
    if (coins == 0) return;
    final current = state.asData?.value ?? await future;
    final updatedCoins = current.coins + coins;
    state = AsyncData(
      current.copyWith(coins: updatedCoins < 0 ? 0 : updatedCoins),
    );
  }
}

final lifeBuddyInventoryProvider =
    AsyncNotifierProvider<LifeBuddyInventoryController, LifeBuddyInventory>(
      LifeBuddyInventoryController.new,
    );

final lifeBuddyUnlockingDecorProvider = StateProvider<String?>((ref) => null);
