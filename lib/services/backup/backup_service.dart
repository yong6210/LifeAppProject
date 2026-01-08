import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:life_app/models/settings.dart';
import 'package:life_app/repositories/settings_repository.dart';
import 'package:life_app/services/analytics/analytics_service.dart';
import 'package:life_app/services/backup/encryption_key_manager.dart';
import 'package:life_app/services/backup/backup_metrics.dart';
import 'package:life_app/services/db.dart';

class BackupMetadata {
  BackupMetadata({required this.createdAt, required this.schemaVersion});

  final DateTime createdAt;
  final int schemaVersion;
}

abstract class BackupSettingsDataSource {
  Future<Settings> ensure();
  Future<void> update(void Function(Settings settings) mutate);
}

class IsarBackupSettingsDataSource implements BackupSettingsDataSource {
  IsarBackupSettingsDataSource(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Settings> ensure() => _repository.ensure();

  @override
  Future<void> update(void Function(Settings settings) mutate) async {
    await _repository.update(mutate);
  }
}

class BackupService {
  BackupService({
    required this.keyManager,
    required BackupSettingsDataSource settingsDataSource,
    Future<Uint8List> Function()? readDatabaseBytes,
    Future<void> Function(Uint8List bytes)? restoreDatabaseBytes,
  }) : _settingsDataSource = settingsDataSource,
       _readDatabaseBytes = readDatabaseBytes ?? _defaultReadDatabaseBytes,
       _restoreDatabaseBytes =
           restoreDatabaseBytes ?? _defaultRestoreDatabaseBytes;

  final EncryptionKeyManager keyManager;
  final BackupSettingsDataSource _settingsDataSource;
  final Future<Uint8List> Function() _readDatabaseBytes;
  final Future<void> Function(Uint8List bytes) _restoreDatabaseBytes;
  static const _fileExtension = 'lifeappbackup';

  String get backupFileExtension => _fileExtension;

  Future<File> createEncryptedBackup() async {
    return AnalyticsService.traceAsync<File>('backup_create', () async {
      File? backupFile;
      try {
        final dbFileBytes = await _readDatabaseBytes();
        if (dbFileBytes.isEmpty) {
          throw Exception('Database is empty - nothing to backup');
        }

        final settings = await _settingsDataSource.ensure();
        final now = DateTime.now().toUtc();
        final algorithm = AesGcm.with256bits();
        final key = await keyManager.obtainKey();
        final nonce = algorithm.newNonce();
        final secretBox = await algorithm.encrypt(
          dbFileBytes,
          secretKey: key,
          nonce: nonce,
        );

        final manifest = {
          'version': 1,
          'createdAt': now.toIso8601String(),
          'schemaVersion': settings.schemaVersion,
          'nonce': base64Encode(nonce),
          'ciphertext': base64Encode(secretBox.cipherText),
          'mac': base64Encode(secretBox.mac.bytes),
        };

        final sanitizedTimestamp = now.toIso8601String().replaceAll(':', '-');
        final fileName = 'life_app_backup_$sanitizedTimestamp.$_fileExtension';
        final tempDir = await getTemporaryDirectory();
        final backupFilePath = p.join(tempDir.path, fileName);
        backupFile = File(backupFilePath);

        await backupFile.writeAsString(jsonEncode(manifest));

        final fileSize = backupFile.lengthSync();
        final provider = settings.backupPreferredProvider;
        int? updatedStreak;
        await _settingsDataSource.update((value) {
          final previousStreak = calculateBackupStreak(value.backupHistory);
          value.lastBackupAt = now;
          _appendLog(
            settings: value,
            entry: BackupLogEntry()
              ..timestamp = now
              ..action = 'backup'
              ..status = 'success'
              ..provider = value.backupPreferredProvider
              ..bytes = fileSize,
          );
          final newStreak = calculateBackupStreak(value.backupHistory);
          if (newStreak > previousStreak) {
            updatedStreak = newStreak;
          }
        });

        await AnalyticsService.logEvent('backup_trigger', {
          'action': 'backup',
          'provider': provider,
          'bytes': fileSize,
        });

        if (updatedStreak != null) {
          await AnalyticsService.logEvent('backup_streak_progress', {
            'streak_weeks': updatedStreak,
          });
        }

        return backupFile;
      } catch (e) {
        // Clean up temporary file on error
        if (backupFile != null && await backupFile.exists()) {
          try {
            await backupFile.delete();
          } catch (_) {
            // Ignore cleanup errors
          }
        }

        // Log specific error types for better debugging
        String errorType = 'unknown';
        String errorMessage = e.toString();

        if (e is FileSystemException) {
          errorType = 'file_system';
          errorMessage = 'File system error: ${e.message}';
        } else if (e.toString().contains('empty')) {
          errorType = 'empty_database';
        } else if (e.toString().contains('encryption')) {
          errorType = 'encryption_failed';
        }

        await AnalyticsService.logEvent('backup_error', {
          'error_type': errorType,
          'error_message': errorMessage,
        });

        rethrow;
      }
    });
  }

  Future<void> restoreFromFile(File backupFile) async {
    await AnalyticsService.traceAsync<void>('backup_restore', () async {
      final manifestMap =
          jsonDecode(await backupFile.readAsString()) as Map<String, dynamic>;

      final cipherText = base64Decode(manifestMap['ciphertext'] as String);
      final nonce = base64Decode(manifestMap['nonce'] as String);
      final macBytes = base64Decode(manifestMap['mac'] as String);
      final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));

      final algorithm = AesGcm.with256bits();
      final key = await keyManager.obtainKey();
      final plainBytes = await algorithm.decrypt(secretBox, secretKey: key);

      await _restoreDatabaseBytes(Uint8List.fromList(plainBytes));

      String provider = 'unknown';
      await _settingsDataSource.update((settings) {
        final now = DateTime.now().toUtc();
        settings.lastBackupAt = now;
        provider = settings.backupPreferredProvider;
        _appendLog(
          settings: settings,
          entry: BackupLogEntry()
            ..timestamp = now
            ..action = 'restore'
            ..status = 'success'
            ..provider = settings.backupPreferredProvider
            ..bytes = plainBytes.length,
        );
      });

      await AnalyticsService.logEvent('backup_trigger', {
        'action': 'restore',
        'provider': provider,
        'bytes': plainBytes.length,
      });
    });
  }

  Future<BackupMetadata> readMetadata(File backupFile) async {
    final manifestMap =
        jsonDecode(await backupFile.readAsString()) as Map<String, dynamic>;
    return BackupMetadata(
      createdAt: DateTime.parse(manifestMap['createdAt'] as String),
      schemaVersion: (manifestMap['schemaVersion'] as num).toInt(),
    );
  }

  Future<void> logFailure({
    required String action,
    required Object error,
  }) async {
    await _settingsDataSource.update((settings) {
      _appendLog(
        settings: settings,
        entry: BackupLogEntry()
          ..timestamp = DateTime.now().toUtc()
          ..action = action
          ..status = 'failure'
          ..provider = settings.backupPreferredProvider
          ..errorMessage = error.toString(),
      );
    });
    await AnalyticsService.logEvent('backup_failure', {
      'action': action,
      'error': error.toString(),
    });
  }

  void _appendLog({
    required Settings settings,
    required BackupLogEntry entry,
    int maxEntries = 20,
  }) {
    settings.backupHistory.insert(0, entry);
    while (settings.backupHistory.length > maxEntries) {
      settings.backupHistory.removeLast();
    }
  }
}

Future<Uint8List> _defaultReadDatabaseBytes() async {
  final isar = await DB.instance();
  final tempDir = await getTemporaryDirectory();
  final tempCopyPath = p.join(tempDir.path, 'life_app_backup_temp.isar');
  await isar.copyToFile(tempCopyPath);
  final bytes = await File(tempCopyPath).readAsBytes();
  await File(tempCopyPath).delete();
  return Uint8List.fromList(bytes);
}

Future<void> _defaultRestoreDatabaseBytes(Uint8List bytes) async {
  await DB.replaceWithBytes(bytes);
}
