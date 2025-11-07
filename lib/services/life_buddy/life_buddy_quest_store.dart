import 'package:shared_preferences/shared_preferences.dart';

class LifeBuddyQuestStore {
  LifeBuddyQuestStore({SharedPreferences? preferences})
    : _preferences = preferences;

  static const defaultQuestId = 'daily_focus';
  static const _legacyKey = 'life_buddy_last_quest_claim_iso';
  static const _lastClaimPrefix = 'life_buddy_last_quest_claim_iso';

  SharedPreferences? _preferences;

  Future<SharedPreferences> _prefs() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<bool> hasClaimedToday(
    DateTime now, {
    String questId = defaultQuestId,
  }) async {
    final prefs = await _prefs();
    final key = _keyFor(questId);
    final raw = prefs.getString(key) ?? prefs.getString(_legacyKey);
    if (raw == null || raw.isEmpty) return false;
    final lastClaimDate = _normalizeStoredDate(raw);
    if (lastClaimDate == null) return false;
    final today = _dateKey(now);
    return lastClaimDate == today;
  }

  Future<void> markClaimed(
    DateTime now, {
    String questId = defaultQuestId,
  }) async {
    final prefs = await _prefs();
    await prefs.remove(_legacyKey);
    await prefs.setString(_keyFor(questId), _dateKey(now));
  }

  Future<void> clear({String? questId}) async {
    final prefs = await _prefs();
    if (questId != null) {
      await prefs.remove(_keyFor(questId));
      return;
    }
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key == _legacyKey || key.startsWith(_lastClaimPrefix)) {
        await prefs.remove(key);
      }
    }
  }

  static String _keyFor(String questId) =>
      questId.isEmpty ? _legacyKey : '${_lastClaimPrefix}_$questId';

  static String _dateKey(DateTime dateTime) {
    final utc = DateTime.utc(dateTime.year, dateTime.month, dateTime.day);
    return '${utc.year.toString().padLeft(4, '0')}-'
        '${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')}';
  }

  static String? _normalizeStoredDate(String raw) {
    if (raw.length >= 10 && raw[4] == '-' && raw[7] == '-') {
      return raw.substring(0, 10);
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return null;
    }
    return _dateKey(parsed);
  }
}
