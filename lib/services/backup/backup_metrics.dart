import 'package:life_app/models/settings.dart';

int calculateBackupStreak(List<BackupLogEntry> history) {
  final now = DateTime.now().toUtc();
  const threshold = Duration(days: 7);
  var streak = 0;
  DateTime? previous;

  for (final entry in history) {
    if (entry.action != 'backup' || entry.status != 'success') continue;
    final timestamp = entry.timestamp.toUtc();
    if (streak == 0) {
      if (now.difference(timestamp) <= threshold) {
        streak = 1;
        previous = timestamp;
      } else {
        break;
      }
    } else {
      if (previous != null && previous.difference(timestamp) <= threshold) {
        streak += 1;
        previous = timestamp;
      } else {
        break;
      }
    }
  }
  return streak;
}

bool shouldEncourageBackup(Settings settings) {
  final lastBackup = settings.lastBackupAt?.toUtc();
  final now = DateTime.now().toUtc();
  if (lastBackup == null) {
    return true;
  }
  return now.difference(lastBackup) > const Duration(days: 7);
}
