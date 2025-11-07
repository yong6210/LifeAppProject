import 'package:life_app/services/analytics/analytics_service.dart';

class LifeBuddyAnalytics {
  const LifeBuddyAnalytics._();

  static Future<void> logQuestClaimSuccess({
    required String questId,
    required int coinsRewarded,
    required String source,
  }) {
    return AnalyticsService.logEvent('life_buddy_quest_claim_success', {
      'quest_id': questId,
      'coins_rewarded': coinsRewarded,
      'source': source,
    });
  }

  static Future<void> logQuestClaimFailure({
    required String questId,
    required String source,
    required String errorCode,
  }) {
    return AnalyticsService.logEvent('life_buddy_quest_claim_failed', {
      'quest_id': questId,
      'source': source,
      'error_code': errorCode,
    });
  }

  static Future<void> logDecorUnlockSuccess({
    required String decorId,
    required int costCoins,
    required bool requiresPremium,
  }) {
    return AnalyticsService.logEvent('life_buddy_decor_unlock_success', {
      'decor_id': decorId,
      'cost_coins': costCoins,
      'requires_premium': requiresPremium,
    });
  }

  static Future<void> logDecorUnlockFailure({
    required String decorId,
    required String errorCode,
    int? costCoins,
  }) {
    return AnalyticsService.logEvent('life_buddy_decor_unlock_failed', {
      'decor_id': decorId,
      'error_code': errorCode,
      if (costCoins != null) 'cost_coins': costCoins,
    });
  }
}
