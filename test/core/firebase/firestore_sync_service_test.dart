import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:life_app/core/firebase/firestore_paths.dart';
import 'package:life_app/core/firebase/firestore_sync_service.dart';
import 'package:life_app/models/change_log.dart';
import 'package:life_app/models/daily_summary_local.dart';
import 'package:life_app/models/settings.dart';
import 'package:life_app/repositories/change_log_repository.dart';
import 'package:life_app/repositories/daily_summary_repository.dart';
import 'package:life_app/repositories/settings_repository.dart';

void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  late Directory tempDir;
  late Isar isar;
  late SettingsRepository settingsRepository;
  late DailySummaryRepository dailySummaryRepository;
  late ChangeLogRepository changeLogRepository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('isar_test_');
    isar = await Isar.open([
      SettingsSchema,
      ChangeLogSchema,
      DailySummaryLocalSchema,
    ], directory: tempDir.path);
    settingsRepository = SettingsRepository(isar);
    dailySummaryRepository = DailySummaryRepository(isar);
    changeLogRepository = ChangeLogRepository(isar);
    await settingsRepository.ensure();
  });

  tearDown(() async {
    await isar.close();
    await tempDir.delete(recursive: true);
  });

  group('FirestoreSyncService sleep mixer sync', () {
    test('syncPendingChanges pushes mixer fields', () async {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'test-user'),
      );
      final firestore = FakeFirebaseFirestore();
      final service = FirestoreSyncService(
        auth: auth,
        firestore: firestore,
        settingsRepository: settingsRepository,
        dailySummaryRepository: dailySummaryRepository,
        changeLogRepository: changeLogRepository,
      );

      await settingsRepository.update((settings) {
        settings
          ..sleepMixerPresetId = 'rain_light'
          ..sleepMixerWhiteLevel = 0.65
          ..sleepMixerPinkLevel = 0.2
          ..sleepMixerBrownLevel = 0.1
          ..sleepSmartAlarmWindowMinutes = 35
          ..sleepSmartAlarmIntervalMinutes = 6
          ..sleepSmartAlarmExactFallback = false;
      });

      await service.syncPendingChanges();

      final doc = await firestore
          .doc(FirestorePaths.settingsDoc('test-user'))
          .get();
      final data = doc.data()!;
      expect(data['sleepMixerPresetId'], 'rain_light');
      expect(data['sleepMixerWhiteLevel'], closeTo(0.65, 1e-9));
      expect(data['sleepMixerPinkLevel'], closeTo(0.2, 1e-9));
      expect(data['sleepMixerBrownLevel'], closeTo(0.1, 1e-9));
      expect(data['sleepSmartAlarmWindowMinutes'], 35);
      expect(data['sleepSmartAlarmIntervalMinutes'], 6);
      expect(data['sleepSmartAlarmExactFallback'], isFalse);
    });

    test('pullInitialData applies mixer fields from remote', () async {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'pull-user'),
      );
      final firestore = FakeFirebaseFirestore();
      final service = FirestoreSyncService(
        auth: auth,
        firestore: firestore,
        settingsRepository: settingsRepository,
        dailySummaryRepository: dailySummaryRepository,
        changeLogRepository: changeLogRepository,
      );

      final path = FirestorePaths.settingsDoc('pull-user');
      await firestore.doc(path).set({
        'sleepMixerPresetId': 'forest_birds',
        'sleepMixerWhiteLevel': 0.45,
        'sleepMixerPinkLevel': 0.35,
        'sleepMixerBrownLevel': 0.1,
        'sleepSmartAlarmWindowMinutes': 28,
        'sleepSmartAlarmIntervalMinutes': 4,
        'sleepSmartAlarmExactFallback': true,
      });

      await settingsRepository.update((settings) {
        settings
          ..sleepMixerPresetId = 'custom_mix'
          ..sleepMixerWhiteLevel = 0.1
          ..sleepMixerPinkLevel = 0.1
          ..sleepMixerBrownLevel = 0.1
          ..sleepSmartAlarmWindowMinutes = 5
          ..sleepSmartAlarmIntervalMinutes = 1
          ..sleepSmartAlarmExactFallback = false;
      });

      await service.pullInitialData();

      final updated = await settingsRepository.get();
      expect(updated.sleepMixerPresetId, 'forest_birds');
      expect(updated.sleepMixerWhiteLevel, closeTo(0.45, 1e-9));
      expect(updated.sleepMixerPinkLevel, closeTo(0.35, 1e-9));
      expect(updated.sleepSmartAlarmExactFallback, isTrue);
      expect(updated.sleepSmartAlarmWindowMinutes, 28);
      expect(updated.sleepSmartAlarmIntervalMinutes, 4);
    });
  });
}
