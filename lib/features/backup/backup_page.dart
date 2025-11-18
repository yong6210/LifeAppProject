import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:life_app/design/app_theme.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/models/settings.dart';
import 'package:life_app/providers/backup_providers.dart';
import 'package:life_app/providers/settings_providers.dart';
import 'package:life_app/widgets/glass_card.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF1a2332),
                    const Color(0xFF0f1419),
                    const Color(0xFF0a0d10),
                  ]
                : [
                    const Color(0xFFF0F4FF),
                    const Color(0xFFE8EFFF),
                    const Color(0xFFFFFFFF),
                  ],
          ),
        ),
        child: SafeArea(
          child: settingsAsync.when(
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
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    Row(
                      children: [
                        GlassCard(
                          onTap: () => Navigator.of(context).pop(),
                          padding: const EdgeInsets.all(12),
                          borderRadius: 12,
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: 20,
                            color: isDark ? Colors.white : AppTheme.electricViolet,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                AppTheme.electricViolet,
                                AppTheme.teal,
                              ],
                            ).createShader(bounds),
                            child: Text(
                              l10n.tr('backup_title'),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Last backup info
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      borderRadius: 20,
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: isDark ? AppTheme.teal : AppTheme.electricViolet,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              lastBackupText,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark ? Colors.white : theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (errorMessage != null)
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        borderRadius: 16,
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.withOpacity(0.2),
                            Colors.red.withOpacity(0.1),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                errorMessage,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (errorMessage != null) const SizedBox(height: 16),
                    _BackupActions(isLoading: isLoading, isDark: isDark),
                    const SizedBox(height: 24),
                    _PreferredProviderSection(settings: settings, isDark: isDark),
                    const SizedBox(height: 16),
                    _BackupHelpCard(isDark: isDark),
                    const SizedBox(height: 16),
                    _BackupHistoryList(
                      entries: settings.backupHistory,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              if (isLoading)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? AppTheme.teal : AppTheme.electricViolet,
                    ),
                  ),
                ),
            ],
          );
        },
          ),
        ),
      ),
    );
  }
}

class _BackupActions extends ConsumerWidget {
  const _BackupActions({required this.isLoading, required this.isDark});

  final bool isLoading;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            onTap: isLoading
                ? null
                : () async {
                    await ref
                        .read(backupControllerProvider.notifier)
                        .performBackup();
                  },
            padding: const EdgeInsets.all(20),
            borderRadius: 20,
            gradient: LinearGradient(
              colors: [
                AppTheme.electricViolet.withOpacity(0.8),
                AppTheme.teal.withOpacity(0.8),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_upload_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.tr('backup_action_backup'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            onTap: isLoading
                ? null
                : () async {
                    await ref
                        .read(backupControllerProvider.notifier)
                        .performRestore();
                  },
            padding: const EdgeInsets.all(20),
            borderRadius: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_download_outlined,
                  color: isDark ? AppTheme.teal : AppTheme.electricViolet,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.tr('backup_action_restore'),
                  style: TextStyle(
                    color: isDark ? AppTheme.teal : AppTheme.electricViolet,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
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
  const _PreferredProviderSection({required this.settings, required this.isDark});

  final Settings settings;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tr('backup_preferred_storage_title'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tr('backup_preferred_storage_help'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white70 : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
            RadioGroup<String>(
              groupValue: _normalizeProviderValue(
                settings.backupPreferredProvider,
              ),
              onChanged: (value) async {
                if (value == null) return;
                try {
                  await ref.read(
                    updateBackupPreferredProviderProvider(value).future,
                  );
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
    );
  }
}

class _BackupHelpCard extends StatelessWidget {
  const _BackupHelpCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: isDark ? AppTheme.teal : AppTheme.electricViolet,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                l10n.tr('backup_help_title'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildHelpItem(context, '🔒', l10n.tr('backup_help_encrypted')),
          const SizedBox(height: 8),
          _buildHelpItem(context, '☁️', l10n.tr('backup_help_choose_storage')),
          const SizedBox(height: 8),
          _buildHelpItem(context, '⚠️', l10n.tr('backup_help_restore_notice')),
        ],
      ),
    );
  }

  Widget _buildHelpItem(BuildContext context, String emoji, String text) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white70 : theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackupHistoryList extends StatelessWidget {
  const _BackupHistoryList({required this.entries, required this.isDark});

  final List<BackupLogEntry> entries;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (entries.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(40),
        borderRadius: 20,
        child: Center(
          child: Text(
            l10n.tr('backup_history_empty'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white70 : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Backup History',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        ...entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _BackupHistoryTile(entry: entry, l10n: l10n, isDark: isDark),
          );
        }),
      ],
    );
  }
}

class _BackupHistoryTile extends StatelessWidget {
  const _BackupHistoryTile({
    required this.entry,
    required this.l10n,
    required this.isDark,
  });

  final BackupLogEntry entry;
  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  success
                      ? l10n.tr('backup_history_status_success')
                      : l10n.tr('backup_history_status_failure'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? Colors.white70
                        : theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
