import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/models/settings.dart';
import 'package:life_app/providers/backup_providers.dart';
import 'package:life_app/providers/settings_providers.dart';

class BackupPage extends ConsumerWidget {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    ref.listen<AsyncValue<void>>(backupControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.tr('backup_error_message', {'error': error.toString()}),
              ),
            ),
          );
        },
        data: (_) {
          if (previous?.isLoading == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.tr('backup_success_toast'))),
            );
          }
        },
      );
    });

    final backupState = ref.watch(backupControllerProvider);
    final isLoading = backupState.isLoading;
    final errorMessage = backupState.whenOrNull(
      error: (error, _) => error.toString(),
    );

    final settingsAsync = ref.watch(settingsFutureProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tr('backup_title'))),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            l10n.tr('backup_settings_error', {'error': error.toString()}),
          ),
        ),
        data: (settings) {
          final lastBackupText = settings.lastBackupAt == null
              ? l10n.tr('backup_last_backup_never')
              : l10n.tr('backup_last_backup', {
                  'timestamp': DateFormat.yMd(
                    Localizations.localeOf(context).toLanguageTag(),
                  ).add_Hm().format(settings.lastBackupAt!.toLocal()),
                });
          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lastBackupText,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          errorMessage,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    _BackupActions(isLoading: isLoading),
                    const SizedBox(height: 24),
                    _PreferredProviderSection(settings: settings),
                    const SizedBox(height: 16),
                    const _BackupHelpCard(),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _BackupHistoryList(
                        entries: settings.backupHistory,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const Align(
                  alignment: Alignment.topCenter,
                  child: LinearProgressIndicator(),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BackupActions extends ConsumerWidget {
  const _BackupActions({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: isLoading
              ? null
              : () async {
                  await ref
                      .read(backupControllerProvider.notifier)
                      .performBackup();
                },
          icon: const Icon(Icons.cloud_upload_outlined),
          label: Text(l10n.tr('backup_action_backup')),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          onPressed: isLoading
              ? null
              : () async {
                  await ref
                      .read(backupControllerProvider.notifier)
                      .performRestore();
                },
          icon: const Icon(Icons.cloud_download_outlined),
          label: Text(l10n.tr('backup_action_restore')),
        ),
      ],
    );
  }
}

class _BackupProviderOption {
  const _BackupProviderOption({
    required this.value,
    required this.labelKey,
    this.descriptionKey,
  });

  final String value;
  final String labelKey;
  final String? descriptionKey;

  String label(AppLocalizations l10n) => l10n.tr(labelKey);

  String? description(AppLocalizations l10n) {
    if (descriptionKey == null) return null;
    return l10n.tr(descriptionKey!, {'provider': label(l10n)});
  }
}

const _backupProviders = <_BackupProviderOption>[
  _BackupProviderOption(
    value: '자동',
    labelKey: 'backup_provider_auto',
    descriptionKey: 'backup_provider_auto_description',
  ),
  _BackupProviderOption(
    value: 'Life App Vault',
    labelKey: 'backup_provider_vault',
    descriptionKey: 'backup_provider_vault_description',
  ),
  _BackupProviderOption(
    value: 'Google Drive',
    labelKey: 'backup_provider_google_drive',
  ),
  _BackupProviderOption(
    value: 'iCloud Drive',
    labelKey: 'backup_provider_icloud_drive',
  ),
  _BackupProviderOption(
    value: 'Device-only',
    labelKey: 'backup_provider_device',
    descriptionKey: 'backup_provider_device_description',
  ),
  _BackupProviderOption(
    value: '기타',
    labelKey: 'backup_provider_other',
    descriptionKey: 'backup_provider_other_description',
  ),
];

String _displayProviderLabel(AppLocalizations l10n, String value) {
  final normalized = _normalizeProviderValue(value);
  for (final option in _backupProviders) {
    if (option.value == normalized) {
      return option.label(l10n);
    }
  }
  return value;
}

String _normalizeProviderValue(String value) {
  switch (value) {
    case 'Dropbox':
    case 'OneDrive':
      return '기타';
    case 'Device-only export':
      return 'Device-only';
    default:
      return value;
  }
}

class _PreferredProviderSection extends ConsumerWidget {
  const _PreferredProviderSection({required this.settings});

  final Settings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tr('backup_preferred_storage_title'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tr('backup_preferred_storage_help'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            RadioGroup<String>(
              groupValue: _normalizeProviderValue(
                settings.backupPreferredProvider,
              ),
              onChanged: (value) async {
                if (value == null) return;
                try {
                  await ref
                      .read(settingsMutationControllerProvider.notifier)
                      .updateBackupPreferredProvider(value);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.tr('backup_preferred_updated', {
                            'provider': _displayProviderLabel(l10n, value),
                          }),
                        ),
                      ),
                    );
                  }
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.tr('backup_preferred_update_error', {
                            'error': error.toString(),
                          }),
                        ),
                      ),
                    );
                  }
                }
              },
              child: Column(
                children: _backupProviders.map((option) {
                  return RadioListTile<String>(
                    title: Text(option.label(l10n)),
                    subtitle: option.description(l10n) != null
                        ? Text(option.description(l10n)!)
                        : null,
                    value: option.value,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupHelpCard extends StatelessWidget {
  const _BackupHelpCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tr('backup_help_title'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(l10n.tr('backup_help_encrypted')),
            Text(l10n.tr('backup_help_choose_storage')),
            Text(l10n.tr('backup_help_restore_notice')),
          ],
        ),
      ),
    );
  }
}

class _BackupHistoryList extends StatelessWidget {
  const _BackupHistoryList({required this.entries});

  final List<BackupLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (entries.isEmpty) {
      return Center(child: Text(l10n.tr('backup_history_empty')));
    }

    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _BackupHistoryTile(entry: entry, l10n: l10n);
      },
    );
  }
}

class _BackupHistoryTile extends StatelessWidget {
  const _BackupHistoryTile({required this.entry, required this.l10n});

  final BackupLogEntry entry;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final success = entry.status == 'success';
    final icon = entry.action == 'backup'
        ? Icons.cloud_upload_outlined
        : Icons.cloud_download_outlined;
    final color = success ? Colors.green : Colors.redAccent;
    final locale = Localizations.localeOf(context);
    final formatter = DateFormat.yMd(locale.toLanguageTag()).add_Hm();
    final timestamp = formatter.format(entry.timestamp.toLocal());
    final actionLabel = entry.action == 'backup'
        ? l10n.tr('backup_history_action_backup')
        : l10n.tr('backup_history_action_restore');
    final subtitle = <String?>[
      l10n.tr('backup_history_entry_header', {
        'action': actionLabel,
        'timestamp': timestamp,
      }),
      if (entry.bytes > 0)
        l10n.tr('backup_history_entry_size', {
          'size': _formatBytes(entry.bytes),
        }),
      l10n.tr('backup_history_entry_destination', {
        'provider': _displayProviderLabel(l10n, entry.provider),
      }),
      if (!success && entry.errorMessage != null)
        l10n.tr('backup_history_entry_error', {'error': entry.errorMessage!}),
    ].whereType<String>().join('\n');

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        success
            ? l10n.tr('backup_history_status_success')
            : l10n.tr('backup_history_status_failure'),
        style: TextStyle(color: color),
      ),
      subtitle: Text(subtitle),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  final exponent = min((log(bytes) / log(1024)).floor(), units.length - 1);
  final size = bytes / pow(1024, exponent);
  return '${size.toStringAsFixed(size >= 10 ? 0 : 1)} ${units[exponent]}';
}
