import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:life_app/design/app_theme.dart';
import 'package:life_app/features/subscription/paywall_page.dart';
import 'package:life_app/models/settings.dart';
import 'package:life_app/features/backup/backup_page.dart';
import 'package:life_app/providers/account_providers.dart';
import 'package:life_app/providers/accessibility_providers.dart';
import 'package:life_app/providers/auth_providers.dart';
import 'package:life_app/providers/diagnostics_providers.dart';
import 'package:life_app/providers/settings_providers.dart';
import 'package:life_app/providers/backup_providers.dart';
import 'package:life_app/services/account/account_deletion_service.dart';
import 'package:life_app/services/analytics/analytics_service.dart';
import 'package:life_app/services/backup/backup_metrics.dart';
import 'package:life_app/services/diagnostics/timer_diagnostics_service.dart';
import 'package:life_app/services/subscription/revenuecat_service.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authControllerProvider);
    final premiumStatus = ref.watch(premiumStatusProvider);
    final isPremium = premiumStatus.isPremium;
    final settingsAsync = ref.watch(settingsFutureProvider);
    final accessibilityAsync = ref.watch(accessibilityControllerProvider);
    final timerDiagnosticsAsync = ref.watch(timerAccuracySamplesProvider);
    final deletionState = ref.watch(accountDeletionControllerProvider);
    final deletionResult = deletionState.asData?.value;
    final isAuthLoading = authAsync.isLoading;
    final user = authAsync.value;
    final l10n = context.l10n;

    final Widget languageSection = settingsAsync.when<Widget>(
      data: (settings) {
        final selected =
            (settings.locale.isEmpty || settings.locale == 'system')
            ? 'system'
            : settings.locale;
        final AppLocaleController localeController = ref.read(
          appLocaleControllerProvider.notifier,
        );
        return _LanguagePreferenceCard(
          l10n: l10n,
          selected: selected,
          onChanged: (code, label) async {
            await localeController.setLocale(code);
            if (!context.mounted) return;
            final message = l10n.tr('account_language_updated', {
              'language': label,
            });
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
          },
        );
      },
      loading: () => _LoadingCard(title: l10n.tr('account_language_title')),
      error: (error, _) => _ErrorCard(
        title: l10n.tr('account_language_title'),
        message: '$error',
      ),
    );

    ref.listen<AsyncValue<AccountDeletionResult?>>(
      accountDeletionControllerProvider,
      (previous, next) {
        next.whenOrNull(
          data: (result) {
            if (result == null || !context.mounted) return;
            final message = result.requiresReauthentication
                ? l10n.tr('account_delete_requires_reauth_snackbar')
                : l10n.tr('account_delete_success');
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
          },
          error: (error, _) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.tr('account_delete_error', {'error': '$error'}),
                ),
              ),
            );
          },
        );
      },
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF000000),
                    const Color(0xFF1A1A1A),
                  ]
                : [
                    const Color(0xFFD8E5E0), // Darker pastel mint
                    const Color(0xFFD0E4D8), // Darker pastel sage green
                    const Color(0xFFD8E0DD), // Darker pastel aqua
                  ],
            stops: isDark ? const [0.0, 1.0] : const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.teal, AppTheme.eucalyptus],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.tr('account_title'),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(revenueCatControllerProvider.notifier)
              .refreshCustomerInfo();
          ref.invalidate(settingsFutureProvider);
          await ref.read(settingsFutureProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _AccountStatusCard(
              l10n: l10n,
              user: user,
              isLoading: isAuthLoading,
              onSignIn: () async {
                try {
                  await ref
                      .read(authControllerProvider.notifier)
                      .signInAnonymously();
                } catch (error) {
                  if (context.mounted) {
                    _showError(
                      context,
                      l10n.tr('error_login_failed', {'error': '$error'}),
                    );
                  }
                }
              },
              onSignOut: () async {
                try {
                  await ref.read(authControllerProvider.notifier).signOut();
                } catch (error) {
                  if (context.mounted) {
                    _showError(
                      context,
                      l10n.tr('error_logout_failed', {'error': '$error'}),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            _SubscriptionStatusCard(
              l10n: l10n,
              status: premiumStatus,
              onManageSubscription: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const PaywallPage()),
                );
              },
            ),
            const SizedBox(height: 16),
            languageSection,
            const SizedBox(height: 16),
            _DataDisclosureCard(
              l10n: l10n,
              onViewDetails: () => _showDataRetentionDisclosure(context),
            ),
            const SizedBox(height: 16),
            settingsAsync.when(
              loading: () => const _LoadingCard(),
              error: (error, _) => _ErrorCard(
                title: l10n.tr('account_personalization_title'),
                message: l10n.tr('generic_settings_error', {'error': '$error'}),
              ),
              data: (settings) =>
                  _PersonalizationSettingsCard(l10n: l10n, settings: settings),
            ),
            const SizedBox(height: 16),
            accessibilityAsync.when(
              loading: () => const _LoadingCard(),
              error: (error, _) => _ErrorCard(
                title: l10n.tr('account_accessibility_title'),
                message: '$error',
              ),
              data: (state) => _AccessibilitySettingsCard(
                l10n: l10n,
                reducedMotion: state.reducedMotion,
                onChanged: (value) async {
                  await ref
                      .read(accessibilityControllerProvider.notifier)
                      .setReducedMotion(value);
                },
              ),
            ),
            const SizedBox(height: 16),
            _PrivacyPolicyCard(
              l10n: l10n,
              onOpen: () => _showPrivacyPolicy(context),
            ),
            const SizedBox(height: 16),
            _OpenSourceLicensesCard(
              l10n: l10n,
              onOpen: () => _showLicenses(context),
            ),
            const SizedBox(height: 16),
            settingsAsync.when(
              loading: () =>
                  _LoadingCard(title: l10n.tr('backup_loading_title')),
              error: (error, _) => _ErrorCard(
                title: l10n.tr('backup_error_title'),
                message: error.toString(),
              ),
              data: (settings) => FutureBuilder<bool>(
                future: ref
                    .read(backupBannerServiceProvider.future)
                    .then((service) => service.shouldShow(settings)),
                builder: (context, snapshot) {
                  final showBanner = snapshot.data ?? false;
                  return _BackupHistoryCard(
                    l10n: l10n,
                    settings: settings,
                    isPremium: isPremium,
                    showReminderBanner: showBanner,
                    onDismissReminder: () async {
                      final service = await ref.read(
                        backupBannerServiceProvider.future,
                      );
                      await service.snooze();
                      if (context.mounted) {
                        AnalyticsService.logEvent('backup_banner_dismiss');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.tr('backup_banner_dismissed')),
                          ),
                        );
                      }
                    },
                    onRequestPremium: () async {
                      AnalyticsService.logEvent('premium_gate', {
                        'feature': 'backup_history',
                      });
                      await Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const PaywallPage(),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            timerDiagnosticsAsync.when(
              loading: () => const _LoadingCard(),
              error: (error, _) => _ErrorCard(
                title: l10n.tr('account_diagnostics_title'),
                message: error.toString(),
              ),
              data: (samples) => _TimerDiagnosticsCard(
                l10n: l10n,
                samples: samples,
                locale: Localizations.localeOf(context),
                onClear: () async {
                  final service = await ref.read(
                    timerDiagnosticsServiceProvider.future,
                  );
                  await service.clearAccuracySamples();
                  ref.invalidate(timerAccuracySamplesProvider);
                },
                onShare: () async {
                  final service = await ref.read(
                    timerDiagnosticsServiceProvider.future,
                  );
                  final csv = await service.exportAccuracySamplesAsCsv();
                  if (csv.trim().isEmpty ||
                      csv.trim() ==
                          'recorded_at_utc,mode,segment_id,segment_label,skew_ms') {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.tr('account_diagnostics_share_empty'),
                        ),
                      ),
                    );
                    return;
                  }
                  final dir = await getTemporaryDirectory();
                  final filename =
                      'life_app_timer_accuracy_${DateTime.now().millisecondsSinceEpoch}.csv';
                  final file = File(p.join(dir.path, filename));
                  await file.writeAsString(csv, flush: true);
                  await SharePlus.instance.share(
                    ShareParams(
                      files: [
                        XFile(
                          file.path,
                          mimeType: 'text/csv',
                          name: 'timer_accuracy.csv',
                        ),
                      ],
                      subject: l10n.tr('account_diagnostics_share_subject'),
                      text: l10n.tr('account_diagnostics_share_body'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _AccountDeletionSection(
              l10n: l10n,
              isProcessing: deletionState.isLoading,
              requiresReauth: deletionResult?.requiresReauthentication ?? false,
              errorMessage: deletionState.maybeWhen(
                error: (error, _) => error.toString(),
                orElse: () => null,
              ),
              onDelete: () => _confirmAccountDeletion(context, ref),
            ),
          ],
        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmAccountDeletion(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (ref.read(accountDeletionControllerProvider).isLoading) {
      return;
    }
    final l10n = context.l10n;
    var acknowledged = false;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.tr('dialog_delete_title')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.tr('dialog_delete_body')),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: acknowledged,
                    onChanged: (value) => setState(() {
                      acknowledged = value ?? false;
                    }),
                    title: Text(l10n.tr('dialog_delete_checkbox')),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.tr('dialog_cancel')),
                ),
                FilledButton(
                  onPressed: acknowledged
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.error.withValues(alpha: 0.9),
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  child: Text(l10n.tr('dialog_confirm_delete')),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true) {
      await ref
          .read(accountDeletionControllerProvider.notifier)
          .deleteAccount();
    }
  }

  Future<void> _showDataRetentionDisclosure(BuildContext context) async {
    AnalyticsService.logEvent('data_retention_view');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, controller) {
            final sheetL10n = context.l10n;
            return Padding(
              padding: const EdgeInsets.all(24),
              child: ListView(
                controller: controller,
                children: [
                  Text(
                    sheetL10n.tr('data_retention_heading'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(sheetL10n.tr('data_retention_local')),
                  const SizedBox(height: 8),
                  Text(sheetL10n.tr('data_retention_light_sync')),
                  const SizedBox(height: 8),
                  Text(sheetL10n.tr('data_retention_backup')),
                  const SizedBox(height: 8),
                  Text(sheetL10n.tr('data_retention_telemetry')),
                  const SizedBox(height: 16),
                  Text(sheetL10n.tr('data_retention_footer')),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showPrivacyPolicy(BuildContext context) async {
    AnalyticsService.logEvent('privacy_policy_view');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, controller) {
            final sheetL10n = context.l10n;
            return Padding(
              padding: const EdgeInsets.all(24),
              child: ListView(
                controller: controller,
                children: [
                  Text(
                    sheetL10n.tr('privacy_summary_heading'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(sheetL10n.tr('privacy_summary_data')),
                  const SizedBox(height: 8),
                  Text(sheetL10n.tr('privacy_summary_telemetry')),
                  const SizedBox(height: 8),
                  Text(sheetL10n.tr('privacy_summary_backup')),
                  const SizedBox(height: 12),
                  Text(sheetL10n.tr('privacy_summary_more')),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showLicenses(BuildContext context) {
    AnalyticsService.logEvent('licenses_view');
    showLicensePage(
      context: context,
      applicationName: context.l10n.tr('app_title'),
      applicationVersion: '0.1.0',
      applicationLegalese: 'Third-party components © respective owners',
    );
  }
}

class _AccountStatusCard extends StatelessWidget {
  const _AccountStatusCard({
    required this.l10n,
    required this.user,
    required this.isLoading,
    required this.onSignIn,
    required this.onSignOut,
  });

  final AppLocalizations l10n;
  final User? user;
  final bool isLoading;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final isSignedIn = user != null;
    final isAnonymous = user?.isAnonymous ?? true;
    final displayUid = user?.uid ?? '-';
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tr('account_status_title'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.tr('account_uid_label', {'uid': displayUid}),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isSignedIn
                  ? (isAnonymous
                        ? l10n.tr('account_status_anonymous')
                        : l10n.tr('account_status_logged_in'))
                  : l10n.tr('account_status_logged_out'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: (!isSignedIn)
                      ? FilledButton.icon(
                          onPressed: isLoading ? null : onSignIn,
                          icon: const Icon(Icons.login),
                          label: Text(
                            isLoading
                                ? l10n.tr('account_processing')
                                : l10n.tr('account_login_button'),
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: isLoading ? null : onSignOut,
                          icon: const Icon(Icons.logout),
                          label: Text(
                            isLoading
                                ? l10n.tr('account_processing')
                                : l10n.tr('account_logout_button'),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.tr('account_upgrade_hint'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionStatusCard extends StatelessWidget {
  const _SubscriptionStatusCard({
    required this.l10n,
    required this.status,
    required this.onManageSubscription,
  });

  final AppLocalizations l10n;
  final PremiumStatus status;
  final VoidCallback onManageSubscription;

  @override
  Widget build(BuildContext context) {
    final isPremium = status.isPremium;
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tr('subscription_title'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isPremium
                      ? Icons.workspace_premium
                      : Icons.workspace_premium_outlined,
                  color: isPremium
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  isPremium
                      ? l10n.tr('subscription_premium')
                      : l10n.tr('subscription_free'),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (status.isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.tr('subscription_checking'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            if (!status.revenueCatAvailable && status.hasCachedValue)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.wifi_off,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.tr('subscription_offline_notice'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (status.isInGracePeriod && status.gracePeriodEndsAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 18,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.tr('subscription_grace_notice', {
                            'date': _formatDate(status.gracePeriodEndsAt!),
                          }),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (status.isExpired && status.expirationDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.tr('subscription_expired_notice', {
                            'date': _formatDate(status.expirationDate!),
                          }),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onManageSubscription,
              child: Text(
                isPremium
                    ? l10n.tr('subscription_manage')
                    : l10n.tr('subscription_explore'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupHistoryCard extends StatelessWidget {
  const _BackupHistoryCard({
    required this.l10n,
    required this.settings,
    required this.isPremium,
    required this.showReminderBanner,
    required this.onDismissReminder,
    required this.onRequestPremium,
  });

  final AppLocalizations l10n;
  final Settings settings;
  final bool isPremium;
  final bool showReminderBanner;
  final VoidCallback onDismissReminder;
  final VoidCallback onRequestPremium;

  @override
  Widget build(BuildContext context) {
    final history = settings.backupHistory;
    final theme = Theme.of(context);
    final summary = _buildSummary(l10n, history);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tr('backup_history_title'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            summary,
            if (showReminderBanner) ...[
              const SizedBox(height: 12),
              _BackupReminderBanner(l10n: l10n, onDismissed: onDismissReminder),
            ],
            const SizedBox(height: 8),
            Text(
              l10n.tr('backup_preferred_label', {
                'provider': settings.backupPreferredProvider,
              }),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (!isPremium) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.tr('backup_premium_header'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.tr('backup_premium_message'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Semantics(
                        button: true,
                        label: l10n.tr('backup_upgrade_semantics_label'),
                        hint: l10n.tr('backup_upgrade_semantics_hint'),
                        child: FilledButton.tonal(
                          onPressed: onRequestPremium,
                          child: Text(l10n.tr('backup_upgrade_button')),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (history.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.tr('backup_history_recent_only'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                _BackupEntryTile(entry: history.first),
              ],
            ] else if (history.isEmpty)
              Text(
                l10n.tr('backup_history_empty'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              ...history
                  .take(10)
                  .map((entry) => _BackupEntryTile(entry: entry)),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimerDiagnosticsCard extends StatelessWidget {
  const _TimerDiagnosticsCard({
    required this.l10n,
    required this.samples,
    required this.locale,
    required this.onClear,
    required this.onShare,
  });

  final AppLocalizations l10n;
  final List<TimerAccuracySample> samples;
  final Locale locale;
  final Future<void> Function() onClear;
  final Future<void> Function() onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat.yMd(locale.toLanguageTag()).add_Hm();
    final visibleSamples = samples.take(8).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.tr('account_diagnostics_title'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.tr('account_diagnostics_share'),
                  onPressed: samples.isEmpty
                      ? null
                      : () {
                          unawaited(onShare());
                        },
                  icon: const Icon(Icons.ios_share_outlined),
                ),
                IconButton(
                  tooltip: l10n.tr('account_diagnostics_clear'),
                  onPressed: samples.isEmpty
                      ? null
                      : () {
                          unawaited(onClear());
                        },
                  icon: const Icon(Icons.delete_sweep_outlined),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tr('account_diagnostics_body'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (samples.isNotEmpty)
              _DiagnosticsSummary(l10n: l10n, samples: samples),
            if (samples.isNotEmpty) const SizedBox(height: 12),
            if (samples.isEmpty)
              Text(
                l10n.tr('account_diagnostics_no_samples'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ListBody(
                children: visibleSamples
                    .map(
                      (sample) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.tr('account_diagnostics_entry', {
                                'timestamp': dateFormatter.format(
                                  sample.recordedAt.toLocal(),
                                ),
                                'mode': _diagnosticsModeLabel(
                                  sample.mode,
                                  l10n,
                                ),
                                'segment': sample.segmentLabel,
                              }),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              _formatSkew(sample.skewMs, l10n),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            if (samples.length > visibleSamples.length) ...[
              const SizedBox(height: 8),
              Text(
                l10n.tr('account_diagnostics_more_available', {
                  'count': (samples.length - visibleSamples.length).toString(),
                }),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatSkew(int skewMs, AppLocalizations l10n) {
    final magnitude = skewMs.abs();
    final value = magnitude >= 1000
        ? l10n.tr('account_diagnostics_value_seconds', {
            'seconds': (magnitude / 1000).toStringAsFixed(
              magnitude >= 10000 ? 0 : 1,
            ),
          })
        : l10n.tr('account_diagnostics_value_millis', {
            'millis': magnitude.toString(),
          });
    return skewMs >= 0
        ? l10n.tr('account_diagnostics_skew_late', {'value': value})
        : l10n.tr('account_diagnostics_skew_early', {'value': value});
  }
}

String _diagnosticsModeLabel(String mode, AppLocalizations l10n) {
  switch (mode) {
    case 'focus':
      return l10n.tr('timer_mode_focus');
    case 'rest':
      return l10n.tr('timer_mode_rest');
    case 'workout':
      return l10n.tr('timer_mode_workout');
    case 'sleep':
      return l10n.tr('timer_mode_sleep');
    default:
      return mode;
  }
}

class _DiagnosticsSummary extends StatelessWidget {
  const _DiagnosticsSummary({required this.l10n, required this.samples});

  final AppLocalizations l10n;
  final List<TimerAccuracySample> samples;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = computeDiagnosticsStats(samples);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tr('account_diagnostics_summary_heading', {
              'count': '${stats.count}',
            }),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tr('account_diagnostics_summary_avg', {
              'value': _formatSignedValue(stats.averageSkewMs, l10n),
            }),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            l10n.tr('account_diagnostics_summary_max', {
              'value': _formatUnsignedValue(stats.maxDeviationMs, l10n),
            }),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            l10n.tr('account_diagnostics_summary_within_target', {
              'percent': stats.withinTargetPercent.toStringAsFixed(
                stats.withinTargetPercent % 1 == 0 ? 0 : 1,
              ),
            }),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class DiagnosticsStats {
  DiagnosticsStats({
    required this.count,
    required this.averageSkewMs,
    required this.maxDeviationMs,
    required this.withinTargetPercent,
  });

  final int count;
  final double averageSkewMs;
  final double maxDeviationMs;
  final double withinTargetPercent;
}

@visibleForTesting
DiagnosticsStats computeDiagnosticsStats(List<TimerAccuracySample> samples) {
  final count = samples.length;
  if (count == 0) {
    return DiagnosticsStats(
      count: 0,
      averageSkewMs: 0,
      maxDeviationMs: 0,
      withinTargetPercent: 0,
    );
  }
  final sum = samples.fold<int>(0, (acc, sample) => acc + sample.skewMs);
  final avg = sum / count;
  final maxDeviation = samples
      .map((sample) => sample.skewMs.abs())
      .fold<int>(0, (max, value) => math.max(max, value))
      .toDouble();
  final withinTarget = samples
      .where((sample) => sample.skewMs.abs() <= 60000)
      .length;
  final percent = withinTarget == 0
      ? 0.0
      : (withinTarget / count * 100).clamp(0, 100).toDouble();
  return DiagnosticsStats(
    count: count,
    averageSkewMs: avg,
    maxDeviationMs: maxDeviation,
    withinTargetPercent: percent,
  );
}

String _formatSignedValue(double skewMs, AppLocalizations l10n) {
  if (skewMs == 0) {
    return l10n.tr('account_diagnostics_value_zero');
  }
  final sign = skewMs > 0 ? '+' : '−';
  final magnitude = _formatUnsignedValue(skewMs.abs(), l10n);
  return '$sign$magnitude';
}

String _formatUnsignedValue(double skewMs, AppLocalizations l10n) {
  final absMs = skewMs.abs();
  if (absMs >= 1000) {
    final seconds = absMs / 1000;
    final precision = seconds >= 10 ? 0 : 1;
    return l10n.tr('account_diagnostics_value_seconds', {
      'seconds': seconds.toStringAsFixed(precision),
    });
  }
  return l10n.tr('account_diagnostics_value_millis', {
    'millis': absMs.round().toString(),
  });
}

class _BackupEntryTile extends StatelessWidget {
  const _BackupEntryTile({required this.entry});

  final BackupLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final isSuccess = entry.status == 'success';
    final l10n = context.l10n;
    final actionLabel = entry.action == 'backup'
        ? l10n.tr('backup_entry_backup')
        : l10n.tr('backup_entry_restore');
    final timestamp = _formatDate(entry.timestamp);
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isSuccess ? Icons.check_circle : Icons.error_outline,
        color: isSuccess ? theme.colorScheme.primary : theme.colorScheme.error,
      ),
      isThreeLine: true,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            actionLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            timestamp,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            softWrap: true,
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tr('backup_entry_storage', {'provider': entry.provider}),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (entry.bytes > 0)
            Text(
              l10n.tr('backup_entry_size', {'size': _formatBytes(entry.bytes)}),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (!isSuccess && entry.errorMessage != null)
            Text(
              l10n.tr('backup_entry_error', {'message': entry.errorMessage!}),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }
}

Widget _buildSummary(AppLocalizations l10n, List<BackupLogEntry> history) {
  if (history.isEmpty) {
    return Builder(
      builder: (context) => Text(
        l10n.tr('backup_summary_never'),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
  final lastSuccess = history.firstWhere(
    (entry) => entry.action == 'backup' && entry.status == 'success',
    orElse: () => history.first,
  );
  final formattedDate = _formatDate(lastSuccess.timestamp);
  final streak = calculateBackupStreak(history);
  final streakLabel = streak <= 1
      ? l10n.tr('backup_summary_streak_single')
      : l10n.tr('backup_summary_streak', {'count': '$streak'});
  return Builder(
    builder: (context) {
      final theme = Theme.of(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tr('backup_summary_last_backup', {'date': formattedDate}),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            streakLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (streak >= 3) ...[
            const SizedBox(height: 8),
            Semantics(
              label: l10n.tr('backup_summary_badge_semantics'),
              child: Chip(
                label: Text(
                  l10n.tr('backup_summary_badge', {'count': '$streak'}),
                ),
                avatar: Icon(
                  Icons.emoji_events,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ],
      );
    },
  );
}

class _BackupReminderBanner extends StatelessWidget {
  const _BackupReminderBanner({required this.l10n, required this.onDismissed});

  final AppLocalizations l10n;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tr('backup_banner_title'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.tr('backup_banner_body'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () {
              AnalyticsService.logEvent('backup_banner_tap');
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(builder: (_) => const BackupPage()),
              );
            },
            child: Text(l10n.tr('backup_banner_button')),
          ),
          TextButton(
            onPressed: () {
              AnalyticsService.logEvent('backup_banner_dismiss_tap');
              onDismissed();
            },
            child: Text(l10n.tr('backup_banner_dismiss')),
          ),
        ],
      ),
    );
  }
}

class _AccountDeletionSection extends StatelessWidget {
  const _AccountDeletionSection({
    required this.l10n,
    required this.isProcessing,
    required this.requiresReauth,
    required this.onDelete,
    this.errorMessage,
  });

  final AppLocalizations l10n;
  final bool isProcessing;
  final bool requiresReauth;
  final String? errorMessage;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tr('account_delete_card_title'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tr('account_delete_card_body'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (requiresReauth) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.tr('account_delete_requires_reauth'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.tr('account_delete_error', {'error': errorMessage!}),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: isProcessing ? null : onDelete,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              child: Text(
                isProcessing
                    ? l10n.tr('account_delete_processing')
                    : l10n.tr('account_delete_button'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguagePreferenceCard extends StatelessWidget {
  const _LanguagePreferenceCard({
    required this.l10n,
    required this.selected,
    required this.onChanged,
  });

  final AppLocalizations l10n;
  final String selected;
  final void Function(String code, String label) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = [
      _LanguageOption('system', l10n.tr('account_language_system')),
      _LanguageOption('en', l10n.tr('account_language_english')),
      _LanguageOption('ko', l10n.tr('account_language_korean')),
    ];
    final normalizedSelected = options.any((option) => option.code == selected)
        ? selected
        : 'system';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tr('account_language_title'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tr('account_language_description'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: [
                for (final option in options)
                  ButtonSegment<String>(
                    value: option.code,
                    label: Text(option.label),
                  ),
              ],
              selected: {normalizedSelected},
              showSelectedIcon: false,
              onSelectionChanged: (values) {
                if (values.isEmpty) return;
                final code = values.first;
                if (code == normalizedSelected) return;
                final option = options.firstWhere(
                  (element) => element.code == code,
                );
                onChanged(code, option.label);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption {
  const _LanguageOption(this.code, this.label);

  final String code;
  final String label;
}

class _DataDisclosureCard extends StatelessWidget {
  const _DataDisclosureCard({required this.l10n, required this.onViewDetails});

  final AppLocalizations l10n;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainerHighest,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(
          Icons.privacy_tip_outlined,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          l10n.tr('data_disclosure_title'),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          l10n.tr('data_disclosure_subtitle'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.keyboard_arrow_right,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onTap: onViewDetails,
      ),
    );
  }
}

class _PrivacyPolicyCard extends StatelessWidget {
  const _PrivacyPolicyCard({required this.l10n, required this.onOpen});

  final AppLocalizations l10n;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainerHighest,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(
          Icons.description_outlined,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          l10n.tr('privacy_policy_title'),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          l10n.tr('privacy_policy_subtitle'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.keyboard_arrow_right,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onTap: onOpen,
      ),
    );
  }
}

class _OpenSourceLicensesCard extends StatelessWidget {
  const _OpenSourceLicensesCard({required this.l10n, required this.onOpen});

  final AppLocalizations l10n;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainerHighest,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(Icons.code_outlined, color: theme.colorScheme.primary),
        title: Text(
          l10n.tr('licenses_title'),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          l10n.tr('licenses_subtitle'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.keyboard_arrow_right,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onTap: onOpen,
      ),
    );
  }
}

class _PersonalizationSettingsCard extends ConsumerWidget {
  const _PersonalizationSettingsCard({
    required this.l10n,
    required this.settings,
  });

  final AppLocalizations l10n;
  final Settings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsEnabled = settings.routinePersonalizationEnabled;
    final syncEnabled = settings.routinePersonalizationSyncEnabled;
    final tone = settings.lifeBuddyTone;

    Future<void> handleAction(Future<void> Function() run) async {
      try {
        await run();
      } catch (error) {
        if (!context.mounted) return;
        final message = l10n.tr('generic_settings_error', {'error': '$error'});
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }

    String syncSubtitle() {
      final base = l10n.tr('account_personalization_sync_subtitle');
      if (suggestionsEnabled) {
        return base;
      }
      final disabled = l10n.tr('account_personalization_sync_disabled');
      return '$base\n$disabled';
    }

    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tr('account_personalization_title'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tr('account_personalization_body'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: suggestionsEnabled,
              title: Text(l10n.tr('account_personalization_enabled_title')),
              subtitle: Text(
                l10n.tr('account_personalization_enabled_subtitle'),
              ),
              onChanged: (value) async {
                await handleAction(() async {
                  await ref.read(
                    setRoutinePersonalizationEnabledProvider(value).future,
                  );
                  await AnalyticsService.logEvent('personalization_toggle', {
                    'enabled': value,
                  });
                });
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: syncEnabled,
              title: Text(l10n.tr('account_personalization_sync_title')),
              subtitle: Text(syncSubtitle()),
              onChanged: suggestionsEnabled
                  ? (value) async {
                      await handleAction(() async {
                        await ref.read(
                          setRoutinePersonalizationSyncProvider(value).future,
                        );
                        await AnalyticsService.logEvent(
                          'personalization_sync_toggle',
                          {'enabled': value},
                        );
                      });
                    }
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.tr('account_personalization_tone_title'),
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            RadioGroup<String>(
              groupValue: tone,
              onChanged: (value) async {
                if (value == null) return;
                await handleAction(() async {
                  await ref.read(setLifeBuddyToneProvider(value).future);
                  await AnalyticsService.logEvent(
                    'personalization_tone_select',
                    {'tone': value},
                  );
                });
              },
              child: Column(
                children: [
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: 'friend',
                    title: Text(l10n.tr('account_personalization_tone_friend')),
                    subtitle: Text(
                      l10n.tr(
                        'account_personalization_tone_friend_description',
                      ),
                    ),
                  ),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: 'coach',
                    title: Text(l10n.tr('account_personalization_tone_coach')),
                    subtitle: Text(
                      l10n.tr('account_personalization_tone_coach_description'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessibilitySettingsCard extends StatelessWidget {
  const _AccessibilitySettingsCard({
    required this.l10n,
    required this.reducedMotion,
    required this.onChanged,
  });

  final AppLocalizations l10n;
  final bool reducedMotion;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tr('account_accessibility_title'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tr('account_accessibility_body'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: reducedMotion,
              onChanged: onChanged,
              title: Text(l10n.tr('account_accessibility_reduced_motion')),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainerHighest,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: title != null
            ? Text(
                title!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              )
            : null,
        subtitle: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: LinearProgressIndicator(minHeight: 4),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainerHighest,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(Icons.error_outline, color: theme.colorScheme.error),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  var size = bytes.toDouble();
  var unitIndex = 0;
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }
  final formatted = size >= 10
      ? size.toStringAsFixed(0)
      : size.toStringAsFixed(1);
  return '$formatted ${units[unitIndex]}';
}

String _formatDate(DateTime timestamp) {
  final local = timestamp.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
