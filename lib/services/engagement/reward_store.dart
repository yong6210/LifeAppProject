import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RewardState {
  const RewardState({
    required this.musicUnlocked,
    required this.premiumActiveUntil,
  });

  final bool musicUnlocked;
  final DateTime? premiumActiveUntil;

  bool get premiumActive =>
      premiumActiveUntil != null && premiumActiveUntil!.isAfter(DateTime.now());
}

class RewardStore extends AsyncNotifier<RewardState> {
  static const _keyMusicUnlocked = 'reward_music_unlocked';
  static const _keyPremiumUntil = 'reward_premium_until';

  late SharedPreferences _prefs;

  @override
  Future<RewardState> build() async {
    _prefs = await SharedPreferences.getInstance();
    return _readState();
  }

  Future<void> unlockMusicPack() async {
    await _prefs.setBool(_keyMusicUnlocked, true);
    state = AsyncData(
      RewardState(
        musicUnlocked: true,
        premiumActiveUntil: state.asData?.value.premiumActiveUntil,
      ),
    );
  }

  Future<void> activatePremiumForDays(int days) async {
    final until = DateTime.now().add(Duration(days: days));
    await _prefs.setString(_keyPremiumUntil, until.toIso8601String());
    state = AsyncData(
      RewardState(
        musicUnlocked: state.asData?.value.musicUnlocked ?? false,
        premiumActiveUntil: until,
      ),
    );
  }

  RewardState _readState() {
    final musicUnlocked = _prefs.getBool(_keyMusicUnlocked) ?? false;
    final untilRaw = _prefs.getString(_keyPremiumUntil);
    final premiumUntil = untilRaw == null ? null : DateTime.tryParse(untilRaw);
    return RewardState(
      musicUnlocked: musicUnlocked,
      premiumActiveUntil: premiumUntil,
    );
  }
}

final rewardStoreProvider = AsyncNotifierProvider<RewardStore, RewardState>(
  RewardStore.new,
);
