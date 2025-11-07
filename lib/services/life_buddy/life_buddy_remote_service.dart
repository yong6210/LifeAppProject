import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LifeBuddyRemoteService {
  LifeBuddyRemoteService({FirebaseFunctions? functions})
    : _functions = functions;

  final FirebaseFunctions? _functions;

  FirebaseFunctions get _instance => _functions ?? FirebaseFunctions.instance;

  Future<ClaimQuestResult> claimDailyQuest(String questId) async {
    try {
      final callable = _instance.httpsCallable('claimDailyQuest');
      final response = await callable.call<Map<String, dynamic>>({
        'questId': questId,
      });
      final data = Map<String, dynamic>.from(response.data);
      final rewardRaw = data['reward'];
      final rewardData = rewardRaw is Map<String, dynamic>
          ? Map<String, dynamic>.from(rewardRaw)
          : const <String, dynamic>{};
      return ClaimQuestResult(
        ok: data['ok'] == true,
        questId: data['questId'] as String? ?? questId,
        coinsRewarded: (rewardData['coins'] as num?)?.toInt() ?? 0,
      );
    } on FirebaseFunctionsException catch (error) {
      if (!_shouldUseFallback(error)) {
        rethrow;
      }
      return _claimDailyQuestFallback(questId);
    }
  }

  Future<UnlockDecorResult> unlockDecor(String decorId) async {
    final callable = _instance.httpsCallable('unlockDecorItem');
    final response = await callable.call<Map<String, dynamic>>({'decorId': decorId});
    final data = Map<String, dynamic>.from(response.data);
    return UnlockDecorResult(
      ok: data['ok'] == true,
      decorId: data['decorId'] as String? ?? decorId,
      remainingCoins: (data['remainingCoins'] as num?)?.toInt(),
      requiresPremium: data['requiresPremium'] == true,
    );
  }

  bool _shouldUseFallback(FirebaseFunctionsException error) {
    final normalizedCode = error.code.toLowerCase();
    if (normalizedCode != 'unimplemented' && normalizedCode != 'not-found') {
      return false;
    }
    final projectId = _instance.app.options.projectId;
    return projectId.contains('life-app-dev') || projectId.contains('life-app-ed218');
  }

  Future<ClaimQuestResult> _claimDailyQuestFallback(String questId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseFunctionsException(
        code: 'unauthenticated',
        message: 'User must be signed in to claim quest rewards.',
      );
    }

    final firestore = FirebaseFirestore.instance;
    final inventoryRef = firestore.doc('users/${user.uid}/decor_inventory/state');

    try {
      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(inventoryRef);
        final data = snapshot.data() ?? <String, dynamic>{};
        final claimedRaw = data['claimedQuests'];
        final claimed = <String>{};
        if (claimedRaw is Iterable) {
          for (final item in claimedRaw) {
            if (item is String) {
              claimed.add(item);
            }
          }
        }
        if (claimed.contains(questId)) {
          throw FirebaseFunctionsException(
            code: 'failed-precondition',
            message: 'Quest already claimed.',
          );
        }

        final currentCoins = (data['softCurrency'] as num?)?.toInt() ?? 0;
        final updatedCoins = currentCoins + _defaultQuestRewardCoins;
        final updatedClaimed = [...claimed, questId];

        transaction.set(
          inventoryRef,
          {
            'softCurrency': updatedCoins,
            'claimedQuests': updatedClaimed,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });

      return ClaimQuestResult(
        ok: true,
        questId: questId,
        coinsRewarded: _defaultQuestRewardCoins,
      );
    } on FirebaseFunctionsException {
      rethrow;
    } on FirebaseException catch (error) {
      throw FirebaseFunctionsException(
        code: error.code,
        message: error.message ?? 'Unknown Firestore error',
        details: null,
      );
    }
  }
}

const _defaultQuestRewardCoins = 20;

class ClaimQuestResult {
  const ClaimQuestResult({
    required this.ok,
    required this.questId,
    required this.coinsRewarded,
  });

  final bool ok;
  final String questId;
  final int coinsRewarded;
}

class UnlockDecorResult {
  const UnlockDecorResult({
    required this.ok,
    required this.decorId,
    this.remainingCoins,
    required this.requiresPremium,
  });

  final bool ok;
  final String decorId;
  final int? remainingCoins;
  final bool requiresPremium;
}
