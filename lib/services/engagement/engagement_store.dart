import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserEngagementState {
  const UserEngagementState({
    required this.coins,
    required this.dailyQuestCompleted,
    required this.streakDays,
    required this.totalCompletedDays,
    required this.premiumWeekPasses,
  });

  final int coins;
  final bool dailyQuestCompleted;
  final int streakDays;
  final int totalCompletedDays;
  final int premiumWeekPasses;

  UserEngagementState copyWith({
    int? coins,
    bool? dailyQuestCompleted,
    int? streakDays,
    int? totalCompletedDays,
    int? premiumWeekPasses,
  }) {
    return UserEngagementState(
      coins: coins ?? this.coins,
      dailyQuestCompleted: dailyQuestCompleted ?? this.dailyQuestCompleted,
      streakDays: streakDays ?? this.streakDays,
      totalCompletedDays: totalCompletedDays ?? this.totalCompletedDays,
      premiumWeekPasses: premiumWeekPasses ?? this.premiumWeekPasses,
    );
  }
}

class EngagementStore extends AsyncNotifier<UserEngagementState> {
  static const _keyCoins = 'engagement_coins';
  static const _keyQuestDate = 'engagement_daily_date';
  static const _keyStreak = 'engagement_streak_days';
  static const _keyTotalDays = 'engagement_total_days';
  static const _keyPremiumPasses = 'engagement_premium_passes';

  late SharedPreferences _prefs;

  @override
  Future<UserEngagementState> build() async {
    _prefs = await SharedPreferences.getInstance();
    return _readState();
  }

  Future<void> completeDailyQuest() async {
    final current = state.asData?.value ?? await future;
    if (current.dailyQuestCompleted) return;

    final todayKey = _todayKey();
    final updatedCoins = current.coins + 25;
    final updatedStreak = current.streakDays + 1;
    final updatedTotalDays = current.totalCompletedDays + 1;
    final earnedPass = updatedTotalDays % 30 == 0;
    final passes = earnedPass
        ? current.premiumWeekPasses + 1
        : current.premiumWeekPasses;

    await _prefs.setInt(_keyCoins, updatedCoins);
    await _prefs.setInt(_keyQuestDate, todayKey);
    await _prefs.setInt(_keyStreak, updatedStreak);
    await _prefs.setInt(_keyTotalDays, updatedTotalDays);
    await _prefs.setInt(_keyPremiumPasses, passes);

    state = AsyncData(
      current.copyWith(
        coins: updatedCoins,
        dailyQuestCompleted: true,
        streakDays: updatedStreak,
        totalCompletedDays: updatedTotalDays,
        premiumWeekPasses: passes,
      ),
    );
  }

  Future<bool> spendCoins(int amount) async {
    final current = state.asData?.value ?? await future;
    if (current.coins < amount) {
      return false;
    }
    final updated = current.coins - amount;
    await _prefs.setInt(_keyCoins, updated);
    state = AsyncData(current.copyWith(coins: updated));
    return true;
  }

  Future<void> setCoins(int coins) async {
    final current = state.asData?.value ?? await future;
    await _prefs.setInt(_keyCoins, coins);
    state = AsyncData(current.copyWith(coins: coins));
  }

  Future<void> consumePremiumPass() async {
    final current = state.asData?.value ?? await future;
    if (current.premiumWeekPasses <= 0) return;
    final passes = current.premiumWeekPasses - 1;
    await _prefs.setInt(_keyPremiumPasses, passes);
    state = AsyncData(current.copyWith(premiumWeekPasses: passes));
  }

  UserEngagementState _readState() {
    final todayKey = _todayKey();
    final lastQuestDay = _prefs.getInt(_keyQuestDate) ?? -1;
    final dailyCompleted = lastQuestDay == todayKey;
    return UserEngagementState(
      coins: _prefs.getInt(_keyCoins) ?? 0,
      dailyQuestCompleted: dailyCompleted,
      streakDays: _prefs.getInt(_keyStreak) ?? 0,
      totalCompletedDays: _prefs.getInt(_keyTotalDays) ?? 0,
      premiumWeekPasses: _prefs.getInt(_keyPremiumPasses) ?? 0,
    );
  }

  int _todayKey() {
    final now = DateTime.now();
    return now.year * 10000 + now.month * 100 + now.day;
  }
}

final engagementStoreProvider =
    AsyncNotifierProvider<EngagementStore, UserEngagementState>(
      EngagementStore.new,
    );
