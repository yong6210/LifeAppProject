import 'package:shared_preferences/shared_preferences.dart';

import 'package:life_app/models/settings.dart';
import 'package:life_app/services/backup/backup_metrics.dart';

class BackupReminderService {
  BackupReminderService._(this._prefs);

  static const _prefsKeyLastShown = 'backup_reminder_last_shown_at';
  static const _cooldown = Duration(days: 1);

  final SharedPreferences _prefs;

  static Future<BackupReminderService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return BackupReminderService._(prefs);
  }

  Future<bool> shouldNotify(Settings settings) async {
    if (!shouldEncourageBackup(settings)) {
      return false;
    }

    final now = DateTime.now().toUtc();

    final lastShownMillis = _prefs.getInt(_prefsKeyLastShown);
    if (lastShownMillis != null) {
      final lastShownAt = DateTime.fromMillisecondsSinceEpoch(
        lastShownMillis,
        isUtc: true,
      );
      if (now.difference(lastShownAt) < _cooldown) {
        return false;
      }
    }

    return true;
  }

  Future<void> markNotified() async {
    final now = DateTime.now().toUtc();
    await _prefs.setInt(_prefsKeyLastShown, now.millisecondsSinceEpoch);
  }
}
