import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:life_app/models/settings.dart';
import 'package:life_app/services/backup/backup_banner_service.dart';

Settings _settings(DateTime? lastBackup) {
  return Settings()..lastBackupAt = lastBackup;
}

void main() {
  group('BackupBannerService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns true when backup is stale', () async {
      final service = await BackupBannerService.create();
      final stale = DateTime.now().toUtc().subtract(const Duration(days: 8));
      expect(await service.shouldShow(_settings(stale)), isTrue);
    });

    test('returns false when backup recent', () async {
      final service = await BackupBannerService.create();
      final recent = DateTime.now().toUtc().subtract(const Duration(days: 3));
      expect(await service.shouldShow(_settings(recent)), isFalse);
    });

    test('snooze prevents banner temporarily', () async {
      final service = await BackupBannerService.create();
      final stale = DateTime.now().toUtc().subtract(const Duration(days: 10));
      expect(await service.shouldShow(_settings(stale)), isTrue);
      await service.snooze();
      expect(await service.shouldShow(_settings(stale)), isFalse);
    });
  });
}
