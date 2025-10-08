import 'package:shared_preferences/shared_preferences.dart';

import 'package:life_app/models/settings.dart';
import 'package:life_app/services/backup/backup_metrics.dart';

class BackupBannerService {
  BackupBannerService._(this._prefs);

  static const _prefsKeyDismissedUntil = 'backup_banner_dismissed_until';
  static const _snoozeDuration = Duration(days: 3);

  final SharedPreferences _prefs;

  static Future<BackupBannerService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return BackupBannerService._(prefs);
  }

  Future<bool> shouldShow(Settings settings) async {
    if (!shouldEncourageBackup(settings)) return false;
    final dismissedMillis = _prefs.getInt(_prefsKeyDismissedUntil);
    if (dismissedMillis == null) return true;
    final dismissedUntil =
        DateTime.fromMillisecondsSinceEpoch(dismissedMillis, isUtc: true);
    return DateTime.now().toUtc().isAfter(dismissedUntil);
  }

  Future<void> snooze() async {
    final until = DateTime.now().toUtc().add(_snoozeDuration);
    await _prefs.setInt(
      _prefsKeyDismissedUntil,
      until.millisecondsSinceEpoch,
    );
  }
}
