import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_app/models/settings.dart';
import 'package:life_app/services/backup/backup_service.dart';
import 'package:life_app/services/backup/encryption_key_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakeSecureStorage implements SecureStorage {
  final Map<String, String?> _storage = {};

  @override
  Future<String?> read({required String key}) async => _storage[key];

  @override
  Future<void> write({required String key, required String? value}) async {
    _storage[key] = value;
  }
}

class _FakeSettingsDataSource implements BackupSettingsDataSource {
  _FakeSettingsDataSource(this._settings);

  final Settings _settings;

  @override
  Future<Settings> ensure() async => _settings;

  @override
  Future<void> update(void Function(Settings settings) mutate) async {
    mutate(_settings);
  }
}

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.tempPath);

  final String tempPath;

  @override
  Future<String?> getTemporaryPath() async => tempPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Uint8List databaseBytes;
  late _FakeSettingsDataSource dataSource;
  late BackupService service;
  late _FakeSecureStorage secureStorage;
  late Directory tempDir;
  late PathProviderPlatform originalPathProvider;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('backup_service_test');
    originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance =
        _FakePathProviderPlatform(tempDir.path);

    databaseBytes = Uint8List.fromList('initial-db'.codeUnits);
    dataSource = _FakeSettingsDataSource(Settings()..schemaVersion = 1);
    secureStorage = _FakeSecureStorage();
    service = BackupService(
      keyManager: EncryptionKeyManager(storage: secureStorage),
      settingsDataSource: dataSource,
      readDatabaseBytes: () async => Uint8List.fromList(databaseBytes),
      restoreDatabaseBytes: (bytes) async {
        databaseBytes = Uint8List.fromList(bytes);
      },
    );
  });

  tearDown(() {
    PathProviderPlatform.instance = originalPathProvider;
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('creates encrypted backup and restores successfully', () async {
    dataSource.update((settings) {
      settings.theme = 'dark';
      settings.focusMinutes = 35;
    });

    final backupFile = await service.createEncryptedBackup();
    expect(backupFile.existsSync(), isTrue);
    expect(p.extension(backupFile.path), '.${service.backupFileExtension}');
    expect(dataSource.ensure().then((s) => s.lastBackupAt), completion(isNotNull));

    // mutate local state after backup
    dataSource.update((settings) {
      settings.theme = 'light';
      settings.focusMinutes = 20;
    });
    databaseBytes = Uint8List.fromList('mutated-db'.codeUnits);

    await service.restoreFromFile(backupFile);

    final restoredSettings = await dataSource.ensure();
    expect(restoredSettings.theme, 'light'); // restore flow does not overwrite theme
    expect(restoredSettings.lastBackupAt, isNotNull);
    expect(String.fromCharCodes(databaseBytes), 'initial-db');

    final metadata = await service.readMetadata(backupFile);
    expect(metadata.schemaVersion, restoredSettings.schemaVersion);
  });
}
