import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:life_app/features/subscription/paywall_page.dart';
import 'package:life_app/models/settings.dart';
import 'package:life_app/features/backup/backup_page.dart';
import 'package:life_app/features/stats/stats_page.dart';
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
import 'package:life_app/design/ui_tokens.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/widgets/app_state_widgets.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final sidePadding = math.max(14.0, (screenWidth - 620) / 2);
    final compact = screenWidth < 380;

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
    void refreshSettings() => ref.invalidate(settingsFutureProvider);
    void refreshAccessibility() =>
        ref.invalidate(accessibilityControllerProvider);
    void refreshDiagnostics() => ref.invalidate(timerAccuracySamplesProvider);

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
        onRetry: refreshSettings,
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

    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFBF7),
              Color(0xFFF7F1E8),
              Color(0xFFF3F4FF),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -140,
              left: -90,
              child: IgnorePointer(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDAB9).withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 70,
              right: -80,
              child: IgnorePointer(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC3D6FF).withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      sidePadding,
                      compact ? 10 : 12,
                      sidePadding,
                      8,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(UiRadii.lg),
                        border: Border.all(color: UiBorders.sectionHeader),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.045),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          if (canPop) ...[
                            IconButton.filledTonal(
                              onPressed: () => Navigator.of(context).pop(),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFF3EEE5),
                                foregroundColor: const Color(0xFF36445A),
                              ),
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              color: Color(0xFF4A4FB2),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.tr('account_title'),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1F2633),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  l10n.tr('account_casual_subtitle'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: const Color(0xFF667289),
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3EEE6),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              l10n.tr('account_casual_badge'),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: const Color(0xFF4A4FB2),
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ],
                      ),
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
                      child: Scrollbar(
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(
                            sidePadding,
                            16,
                            sidePadding,
                            20,
                          ),
                          children: [
                            _AccountProgressHubCard(
                              l10n: l10n,
                              displayName: user == null
                                  ? l10n.tr('account_profile_guest')
                                  : (user.isAnonymous
                                      ? l10n.tr('account_profile_anonymous')
                                      : (user.email ??
                                          l10n.tr('account_profile_user'))),
                              uid: user?.uid,
                              settings: settingsAsync.asData?.value,
                              isPremium: isPremium,
                              onOpenStats: () {
                                Navigator.push<void>(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => const StatsPage(),
                                  ),
                                );
                              },
                              onManagePremium: () {
                                Navigator.push<void>(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => const PaywallPage(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _AccountSectionTitle(
                              title: l10n.tr('account_section_identity_title'),
                              subtitle:
                                  l10n.tr('account_section_identity_subtitle'),
                            ),
                            const SizedBox(height: 10),
                            settingsAsync.when(
                              loading: () => const _LoadingCard(),
                              error: (error, _) => _ErrorCard(
                                title: l10n.tr('account_checklist_title'),
                                message: error.toString(),
                                onRetry: refreshSettings,
                              ),
                              data: (settings) => _AccountQuestBoardCard(
                                l10n: l10n,
                                settings: settings,
                                isPremium: isPremium,
                                onOpenBackup: () {
                                  Navigator.push<void>(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => const BackupPage(),
                                    ),
                                  );
                                },
                                onOpenDataPolicy: () =>
                                    _showDataRetentionDisclosure(context),
                                onOpenPremium: () {
                                  Navigator.push<void>(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => const PaywallPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
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
                                      l10n.tr('error_login_failed', {
                                        'error': '$error',
                                      }),
                                    );
                                  }
                                }
                              },
                              onSignOut: () async {
                                try {
                                  await ref
                                      .read(authControllerProvider.notifier)
                                      .signOut();
                                } catch (error) {
                                  if (context.mounted) {
                                    _showError(
                                      context,
                                      l10n.tr('error_logout_failed', {
                                        'error': '$error',
                                      }),
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
                                  MaterialPageRoute<void>(
                                    builder: (_) => const PaywallPage(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _AccountSectionTitle(
                              title:
                                  l10n.tr('account_section_preferences_title'),
                              subtitle: l10n
                                  .tr('account_section_preferences_subtitle'),
                            ),
                            const SizedBox(height: 10),
                            languageSection,
                            const SizedBox(height: 16),
                            _DataDisclosureCard(
                              l10n: l10n,
                              onViewDetails: () =>
                                  _showDataRetentionDisclosure(context),
                            ),
                            const SizedBox(height: 16),
                            settingsAsync.when(
                              loading: () => const _LoadingCard(),
                              error: (error, _) => _ErrorCard(
                                title: l10n.tr('account_personalization_title'),
                                message: l10n.tr('generic_settings_error', {
                                  'error': '$error',
                                }),
                                onRetry: refreshSettings,
                              ),
                              data: (settings) => _PersonalizationSettingsCard(
                                l10n: l10n,
                                settings: settings,
                              ),
                            ),
                            const SizedBox(height: 16),
                            accessibilityAsync.when(
                              loading: () => const _LoadingCard(),
                              error: (error, _) => _ErrorCard(
                                title: l10n.tr('account_accessibility_title'),
                                message: '$error',
                                onRetry: refreshAccessibility,
                              ),
                              data: (state) => _AccessibilitySettingsCard(
                                l10n: l10n,
                                reducedMotion: state.reducedMotion,
                                onChanged: (value) async {
                                  await ref
                                      .read(accessibilityControllerProvider
                                          .notifier)
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
                            _AccountSectionTitle(
                              title: l10n.tr('account_section_safety_title'),
                              subtitle:
                                  l10n.tr('account_section_safety_subtitle'),
                            ),
                            const SizedBox(height: 10),
                            settingsAsync.when(
                              loading: () => _LoadingCard(
                                title: l10n.tr('backup_loading_title'),
                              ),
                              error: (error, _) => _ErrorCard(
                                title: l10n.tr('backup_error_title'),
                                message: error.toString(),
                                onRetry: refreshSettings,
                              ),
                              data: (settings) => FutureBuilder<bool>(
                                future: ref
                                    .read(backupBannerServiceProvider.future)
                                    .then((service) =>
                                        service.shouldShow(settings)),
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
                                        AnalyticsService.logEvent(
                                          'backup_banner_dismiss',
                                        );
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              l10n.tr(
                                                  'backup_banner_dismissed'),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    onRequestPremium: () async {
                                      AnalyticsService.logEvent(
                                          'premium_gate', {
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
                                onRetry: refreshDiagnostics,
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
                                  final csv = await service
                                      .exportAccuracySamplesAsCsv();
                                  if (csv.trim().isEmpty ||
                                      csv.trim() ==
                                          'recorded_at_utc,mode,segment_id,segment_label,skew_ms') {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.tr(
                                              'account_diagnostics_share_empty'),
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
                                      subject: l10n.tr(
                                        'account_diagnostics_share_subject',
                                      ),
                                      text: l10n.tr(
                                        'account_diagnostics_share_body',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            _AccountDeletionSection(
                              l10n: l10n,
                              isProcessing: deletionState.isLoading,
                              requiresReauth:
                                  deletionResult?.requiresReauthentication ??
                                      false,
                              errorMessage: deletionState.maybeWhen(
                                error: (error, _) => error.toString(),
                                orElse: () => null,
                              ),
                              onDelete: () =>
                                  _confirmAccountDeletion(context, ref),
                            ),
                          ],
                        ),
                      ),
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
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() {
                        acknowledged = !acknowledged;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: UiBorders.subtle),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: acknowledged,
                              onChanged: (value) => setState(() {
                                acknowledged = value ?? false;
                              }),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.tr('dialog_delete_checkbox'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _AccountProgressHubCard extends StatelessWidget {
  const _AccountProgressHubCard({
    required this.l10n,
    required this.displayName,
    required this.uid,
    required this.settings,
    required this.isPremium,
    required this.onOpenStats,
    required this.onManagePremium,
  });

  final AppLocalizations l10n;
  final String displayName;
  final String? uid;
  final Settings? settings;
  final bool isPremium;
  final VoidCallback onOpenStats;
  final VoidCallback onManagePremium;

  @override
  Widget build(BuildContext context) {
    final isCloudConnected = uid != null;
    final backupDays = settings?.lastBackupAt == null
        ? null
        : DateTime.now()
            .toUtc()
            .difference(settings!.lastBackupAt!.toUtc())
            .inDays;
    final planLabel = isPremium
        ? l10n.tr('subscription_premium')
        : l10n.tr('subscription_free');
    final syncLabel = isCloudConnected
        ? l10n.tr('account_sync_connected')
        : l10n.tr('account_sync_local');
    final backupLabel = backupDays == null
        ? l10n.tr('account_backup_none')
        : (backupDays <= 3
            ? l10n.tr('account_backup_fresh')
            : l10n.tr('account_backup_days_ago', {'days': '$backupDays'}));
    final safetyLabel = backupDays == null || backupDays > 7
        ? l10n.tr('account_safety_needs_check')
        : l10n.tr('account_safety_good');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F2537), Color(0xFF2E3C5A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shield_moon_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      '$planLabel • $syncLabel',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isPremium
                      ? l10n.tr('account_plan_badge_premium')
                      : l10n.tr('account_plan_badge_standard'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ProgressStat(
                icon: Icons.cloud_done_outlined,
                label: syncLabel,
              ),
              const SizedBox(width: 8),
              _ProgressStat(
                icon: Icons.backup_outlined,
                label: backupLabel,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.verified_user_outlined,
                  color: Colors.white.withValues(alpha: 0.9), size: 15),
              const SizedBox(width: 6),
              Text(
                safetyLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onOpenStats,
                  icon: const Icon(Icons.stacked_bar_chart_rounded),
                  label: Text(l10n.tr('stats_appbar_title')),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onManagePremium,
                  icon: const Icon(Icons.workspace_premium_outlined),
                  label: Text(l10n.tr('account_manage_plan')),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountSectionTitle extends StatelessWidget {
  const _AccountSectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF1F2633),
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF667289),
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _AccountQuestBoardCard extends StatelessWidget {
  const _AccountQuestBoardCard({
    required this.l10n,
    required this.settings,
    required this.isPremium,
    required this.onOpenBackup,
    required this.onOpenDataPolicy,
    required this.onOpenPremium,
  });

  final AppLocalizations l10n;
  final Settings settings;
  final bool isPremium;
  final VoidCallback onOpenBackup;
  final VoidCallback onOpenDataPolicy;
  final VoidCallback onOpenPremium;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    final backupDays = settings.lastBackupAt == null
        ? 999
        : now.difference(settings.lastBackupAt!.toUtc()).inDays;
    final backupDone = backupDays <= 3;
    final riskState = backupDays > 14
        ? _ChecklistRisk.high
        : (backupDays > 7 ? _ChecklistRisk.medium : _ChecklistRisk.low);
    final (riskLabel, riskDescription, riskColor) = switch (riskState) {
      _ChecklistRisk.high => (
          l10n.tr('account_checklist_risk_high_title'),
          l10n.tr('account_checklist_risk_high_body'),
          const Color(0xFFD16C3D),
        ),
      _ChecklistRisk.medium => (
          l10n.tr('account_checklist_risk_medium_title'),
          l10n.tr('account_checklist_risk_medium_body'),
          const Color(0xFF5D79B3),
        ),
      _ChecklistRisk.low => (
          l10n.tr('account_checklist_risk_low_title'),
          l10n.tr('account_checklist_risk_low_body'),
          const Color(0xFF4B68C7),
        ),
    };
    final needsBackupAction = riskState != _ChecklistRisk.low;

    final tasks = [
      _AccountQuestItem(
        title: l10n.tr('account_checklist_task_backup_title'),
        subtitle: backupDone
            ? l10n.tr('account_checklist_task_backup_done')
            : l10n.tr('account_checklist_task_backup_pending'),
        done: backupDone,
        color: const Color(0xFF4B8DF8),
        onTap: onOpenBackup,
      ),
      _AccountQuestItem(
        title: l10n.tr('account_checklist_task_policy_title'),
        subtitle: l10n.tr('account_checklist_task_policy_subtitle'),
        done: false,
        color: const Color(0xFF7B6DF2),
        onTap: onOpenDataPolicy,
      ),
      _AccountQuestItem(
        title: l10n.tr('account_checklist_task_plan_title'),
        subtitle: isPremium
            ? l10n.tr('account_checklist_task_plan_premium')
            : l10n.tr('account_checklist_task_plan_free'),
        done: isPremium,
        color: const Color(0xFFFF9A56),
        onTap: onOpenPremium,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6EAF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tr('account_checklist_title'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF243248),
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: riskColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        riskLabel,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: riskColor,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        riskDescription,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF5E6D85),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                if (needsBackupAction)
                  TextButton(
                    onPressed: onOpenBackup,
                    style: TextButton.styleFrom(
                      foregroundColor: riskColor,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(l10n.tr('account_checklist_backup_action')),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < tasks.length; i++) ...[
            _AccountQuestTile(item: tasks[i]),
            if (i != tasks.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _AccountQuestTile extends StatelessWidget {
  const _AccountQuestTile({required this.item});

  final _AccountQuestItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFCFDFF),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE7EBF5)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  item.done ? Icons.check_rounded : Icons.flag_outlined,
                  color: item.color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: const Color(0xFF2C3D55),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF60708B),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: item.color, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountQuestItem {
  const _AccountQuestItem({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool done;
  final Color color;
  final VoidCallback onTap;
}

enum _ChecklistRisk {
  low,
  medium,
  high,
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
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const BackupPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.cloud_upload_outlined),
                label: Text(l10n.tr('backup_banner_button')),
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
  final withinTarget =
      samples.where((sample) => sample.skewMs.abs() <= 60000).length;
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: UiBorders.subtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error_outline,
            color: isSuccess
                ? theme.colorScheme.primary
                : theme.colorScheme.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  actionLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timestamp,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.tr('backup_entry_storage', {'provider': entry.provider}),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (entry.bytes > 0)
                  Text(
                    l10n.tr('backup_entry_size', {
                      'size': _formatBytes(entry.bytes),
                    }),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (!isSuccess && entry.errorMessage != null)
                  Text(
                    l10n.tr('backup_entry_error', {
                      'message': entry.errorMessage!,
                    }),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
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
    final normalizedSelected =
        options.any((option) => option.code == selected) ? selected : 'system';

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
    return _AccountActionTile(
      icon: Icons.privacy_tip_outlined,
      title: l10n.tr('data_disclosure_title'),
      subtitle: l10n.tr('data_disclosure_subtitle'),
      onTap: onViewDetails,
    );
  }
}

class _PrivacyPolicyCard extends StatelessWidget {
  const _PrivacyPolicyCard({required this.l10n, required this.onOpen});

  final AppLocalizations l10n;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return _AccountActionTile(
      icon: Icons.description_outlined,
      title: l10n.tr('privacy_policy_title'),
      subtitle: l10n.tr('privacy_policy_subtitle'),
      onTap: onOpen,
    );
  }
}

class _OpenSourceLicensesCard extends StatelessWidget {
  const _OpenSourceLicensesCard({required this.l10n, required this.onOpen});

  final AppLocalizations l10n;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return _AccountActionTile(
      icon: Icons.code_outlined,
      title: l10n.tr('licenses_title'),
      subtitle: l10n.tr('licenses_subtitle'),
      onTap: onOpen,
    );
  }
}

class _AccountActionTile extends StatelessWidget {
  const _AccountActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(UiRadii.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(UiRadii.md),
            border: Border.all(color: UiBorders.subtle),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF1F2633),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF667289),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
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

    Future<void> handleToneSelection(String value) async {
      await handleAction(() async {
        await ref
            .read(settingsMutationControllerProvider.notifier)
            .setLifeBuddyTone(value);
        await AnalyticsService.logEvent(
          'personalization_tone_select',
          {'tone': value},
        );
      });
    }

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
            _AccountToggleTile(
              title: l10n.tr('account_personalization_enabled_title'),
              subtitle: l10n.tr('account_personalization_enabled_subtitle'),
              value: suggestionsEnabled,
              onChanged: (value) async {
                await handleAction(() async {
                  await ref
                      .read(settingsMutationControllerProvider.notifier)
                      .setRoutinePersonalizationEnabled(value);
                  await AnalyticsService.logEvent('personalization_toggle', {
                    'enabled': value,
                  });
                });
              },
            ),
            const SizedBox(height: 10),
            _AccountToggleTile(
              title: l10n.tr('account_personalization_sync_title'),
              subtitle: syncSubtitle(),
              value: syncEnabled,
              onChanged: suggestionsEnabled
                  ? (value) async {
                      await handleAction(() async {
                        await ref
                            .read(settingsMutationControllerProvider.notifier)
                            .setRoutinePersonalizationSync(value);
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
            const SizedBox(height: 10),
            _AccountToneOptionTile(
              title: l10n.tr('account_personalization_tone_friend'),
              subtitle: l10n.tr(
                'account_personalization_tone_friend_description',
              ),
              selected: tone == 'friend',
              onTap: () => handleToneSelection('friend'),
            ),
            const SizedBox(height: 8),
            _AccountToneOptionTile(
              title: l10n.tr('account_personalization_tone_coach'),
              subtitle: l10n.tr('account_personalization_tone_coach_description'),
              selected: tone == 'coach',
              onTap: () => handleToneSelection('coach'),
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
            _AccountToggleTile(
              title: l10n.tr('account_accessibility_reduced_motion'),
              subtitle: l10n.tr('account_accessibility_body'),
              value: reducedMotion,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountToggleTile extends StatelessWidget {
  const _AccountToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final theme = Theme.of(context);
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: UiBorders.subtle),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountToneOptionTile extends StatelessWidget {
  const _AccountToneOptionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = selected ? theme.colorScheme.primary : const Color(0xFF667289);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.45)
                  : UiBorders.subtle,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF1F2633),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF667289),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    return AppLoadingState(
      title: title,
      compact: true,
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppErrorState(
      title: title,
      message: message,
      retryLabel: onRetry != null ? context.l10n.tr('common_retry') : null,
      onRetry: onRetry,
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
  final formatted =
      size >= 10 ? size.toStringAsFixed(0) : size.toStringAsFixed(1);
  return '$formatted ${units[unitIndex]}';
}

String _formatDate(DateTime timestamp) {
  final local = timestamp.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
