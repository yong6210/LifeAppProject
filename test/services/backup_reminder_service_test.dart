import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:life_app/models/settings.dart';
import 'package:life_app/services/backup/backup_reminder_service.dart';

Settings _settings({DateTime? lastBackupAt}) {
  return Settings()
    ..lastBackupAt = lastBackupAt
    ..backupHistory = [];
}

void main() {
  group('BackupReminderService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('shouldNotify returns false when recent backup exists', () async {
      final service = await BackupReminderService.create();
      final recent = DateTime.now().toUtc().subtract(const Duration(days: 3));
      final result = await service.shouldNotify(_settings(lastBackupAt: recent));
      expect(result, isFalse);
    });

    test('shouldNotify returns true when backup stale', () async {
      final service = await BackupReminderService.create();
      final stale = DateTime.now().toUtc().subtract(const Duration(days: 10));
      final result = await service.shouldNotify(_settings(lastBackupAt: stale));
      expect(result, isTrue);
    });

    test('shouldNotify respects cooldown after markNotified', () async {
      final service = await BackupReminderService.create();
      final stale = DateTime.now().toUtc().subtract(const Duration(days: 10));
      expect(await service.shouldNotify(_settings(lastBackupAt: stale)), isTrue);
      await service.markNotified();
      expect(await service.shouldNotify(_settings(lastBackupAt: stale)), isFalse);
    });
  });
}
