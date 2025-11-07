import 'package:flutter_test/flutter_test.dart';

import 'package:life_app/models/settings.dart';
import 'package:life_app/services/backup/backup_metrics.dart';

BackupLogEntry _entry({
  required DateTime timestamp,
  String status = 'success',
  String action = 'backup',
}) {
  return BackupLogEntry()
    ..timestamp = timestamp
    ..status = status
    ..action = action
    ..provider = 'Drive';
}

void main() {
  group('calculateBackupStreak', () {
    test('returns zero when no recent backup', () {
      final history = [
        _entry(
          timestamp: DateTime.now().toUtc().subtract(const Duration(days: 10)),
        ),
      ];
      expect(calculateBackupStreak(history), 0);
    });

    test('counts consecutive weekly backups', () {
      final now = DateTime.now().toUtc();
      final history = [
        _entry(timestamp: now.subtract(const Duration(days: 3))),
        _entry(timestamp: now.subtract(const Duration(days: 6))),
        _entry(timestamp: now.subtract(const Duration(days: 13))),
      ];
      expect(calculateBackupStreak(history), 3);
    });

    test('stops streak when gap exceeds threshold', () {
      final now = DateTime.now().toUtc();
      final history = [
        _entry(timestamp: now.subtract(const Duration(days: 3))),
        _entry(timestamp: now.subtract(const Duration(days: 14))),
        _entry(timestamp: now.subtract(const Duration(days: 22))),
      ];
      expect(calculateBackupStreak(history), 1);
    });

    test('ignores non-backup entries', () {
      final now = DateTime.now().toUtc();
      final history = [
        _entry(timestamp: now.subtract(const Duration(days: 3))),
        _entry(
          timestamp: now.subtract(const Duration(days: 5)),
          status: 'failure',
        ),
        _entry(
          timestamp: now.subtract(const Duration(days: 9)),
          action: 'restore',
        ),
        _entry(timestamp: now.subtract(const Duration(days: 11))),
      ];
      expect(calculateBackupStreak(history), 1);
    });
  });

  group('_shouldEncourageBackup', () {
    test('returns true when never backed up', () {
      final settings = Settings()..lastBackupAt = null;
      expect(shouldEncourageBackup(settings), isTrue);
    });

    test('returns false when backup recent', () {
      final settings = Settings()
        ..lastBackupAt = DateTime.now().toUtc().subtract(
          const Duration(days: 2),
        );
      expect(shouldEncourageBackup(settings), isFalse);
    });

    test('returns true when backup stale', () {
      final settings = Settings()
        ..lastBackupAt = DateTime.now().toUtc().subtract(
          const Duration(days: 10),
        );
      expect(shouldEncourageBackup(settings), isTrue);
    });
  });
}
