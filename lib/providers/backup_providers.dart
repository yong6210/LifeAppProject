import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/l10n/l10n_loader.dart';
import 'package:life_app/providers/db_provider.dart';
import 'package:life_app/providers/settings_providers.dart';
import 'package:life_app/repositories/settings_repository.dart';
import 'package:life_app/services/backup/backup_service.dart';
import 'package:life_app/services/backup/encryption_key_manager.dart';
import 'package:life_app/services/backup/backup_reminder_service.dart';
import 'package:life_app/services/backup/backup_banner_service.dart';
import 'package:life_app/services/db.dart';
import 'package:share_plus/share_plus.dart';

final backupControllerProvider = AsyncNotifierProvider<BackupController, void>(
  BackupController.new,
);

class BackupController extends AsyncNotifier<void> {
  late BackupService _backupService;

  @override
  Future<void> build() async {
    final isar = await ref.watch(isarProvider.future);
    _backupService = BackupService(
      keyManager: EncryptionKeyManager(),
      settingsDataSource: IsarBackupSettingsDataSource(
        SettingsRepository(isar),
      ),
    );
    state = const AsyncData(null);
  }

  Future<void> performBackup() async {
    state = const AsyncLoading();
    try {
      final file = await _backupService.createEncryptedBackup();
      final l10n = await loadAppLocalizations();
      final xFile = XFile(
        file.path,
        mimeType: 'application/json',
        name: file.uri.pathSegments.last,
      );
      await Share.shareXFiles(
        [xFile],
        subject: l10n.tr('backup_share_subject'),
        text: l10n.tr('backup_share_text'),
      );
      state = const AsyncData(null);
      ref.invalidate(settingsFutureProvider);
    } catch (error, stack) {
      await _backupService.logFailure(action: 'backup', error: error);
      state = AsyncError(error, stack);
      ref.invalidate(settingsFutureProvider);
    }
  }

  Future<void> performRestore() async {
    state = const AsyncLoading();
    try {
      final l10n = await loadAppLocalizations();
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: l10n.tr('backup_picker_title'),
        type: FileType.custom,
        allowedExtensions: [_backupService.backupFileExtension],
      );
      if (result == null || result.files.isEmpty) {
        state = const AsyncData(null);
        return;
      }
      final path = result.files.single.path;
      if (path == null) {
        throw FormatException(
          l10n.tr('backup_picker_path_error'),
        );
      }
      final file = File(path);
      await _backupService.restoreFromFile(file);
      await DB.instance();
      state = const AsyncData(null);
      ref.invalidate(settingsFutureProvider);
    } catch (error, stack) {
      await _backupService.logFailure(action: 'restore', error: error);
      state = AsyncError(error, stack);
      ref.invalidate(settingsFutureProvider);
    }
  }
}
final backupReminderServiceProvider =
    FutureProvider<BackupReminderService>((ref) async {
  return BackupReminderService.create();
});

final backupBannerServiceProvider =
    FutureProvider<BackupBannerService>((ref) async {
  return BackupBannerService.create();
});
