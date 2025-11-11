import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:life_app/design/app_theme.dart';
import 'package:life_app/features/account/account_page.dart';
import 'package:life_app/features/backup/backup_page.dart';
import 'package:life_app/features/stats/stats_page.dart';
import 'package:life_app/features/subscription/paywall_page.dart';
import 'package:life_app/features/timer/timer_page.dart';
import 'package:life_app/features/workout/workout_navigator_page.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/providers/auth_providers.dart';
import 'package:life_app/providers/session_providers.dart';
import 'package:life_app/providers/settings_providers.dart';
import 'package:life_app/providers/sleep_analysis_providers.dart';
import 'package:life_app/providers/stats_providers.dart';
import 'package:life_app/providers/sync_providers.dart';
import 'package:life_app/widgets/modern_animations.dart';

class HomeDashboardTab extends ConsumerWidget {
  const HomeDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);

    final now = DateTime.now();
    final greeting = l10n.tr(_greetingKeyForHour(now.hour));
    final greetingSubtitle = l10n.tr('home_dashboard_greeting_subtitle');
    final dateLabel = DateFormat(
      'EEE, MMM d',
      locale.toLanguageTag(),
    ).format(now);

    final authState = ref.watch(authControllerProvider);
    final settingsAsync = ref.watch(settingsFutureProvider);
    final settings = settingsAsync.asData?.value;
    final todaySummary = ref
        .watch(todaySummaryProvider)
        .maybeWhen(data: (value) => value, orElse: () => const TodaySummary());
    final syncState = ref.watch(syncControllerProvider);
    final streakDays = ref
        .watch(streakCountProvider)
        .maybeWhen(data: (value) => value, orElse: () => 0);

    final focusGoalMinutes = ((settings?.focusMinutes ?? 25) * 4)
        .clamp(0, 600)
        .toInt();

    final banner = _buildSyncBanner(
      context: context,
      syncState: syncState,
      authState: authState,
      l10n: l10n,
    );

    void openTimer(String mode, {bool autoStart = false}) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => TimerPage(initialMode: mode, autoStart: autoStart),
        ),
      );
    }

    void openStats() {
      Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const StatsPage()),
      );
    }

    void openWorkout() {
      Navigator.push<void>(context, WorkoutNavigatorPage.route());
    }

    void openAccount() {
      Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const AccountPage()),
      );
    }

    void openBackup() {
      Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const BackupPage()),
      );
    }

    void openPremium() {
      Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const PaywallPage()),
      );
    }

    final quickActions = [
      _QuickActionConfig(
        emoji: '⏱️',
        label: l10n.tr('timer_mode_focus'),
        accent: AppTheme.accentBlue,
        onTap: () => openTimer('focus', autoStart: true),
      ),
      _QuickActionConfig(
        emoji: '💪',
        label: l10n.tr('timer_mode_workout'),
        accent: AppTheme.accentGreen,
        onTap: openWorkout,
      ),
      _QuickActionConfig(
        emoji: '🌙',
        label: l10n.tr('timer_mode_sleep'),
        accent: AppTheme.accentPurple,
        onTap: () => openTimer('sleep', autoStart: true),
      ),
    ];

    final routineCards = [
      _RoutineCardData(
        title: l10n.tr('timer_mode_focus'),
        description: l10n.tr('home_dashboard_card_focus_description'),
        minutes: todaySummary.focus,
        accent: AppTheme.accentBlue,
        icon: Icons.timer_outlined,
        primaryLabel: l10n.tr('home_dashboard_action_start'),
        secondaryLabel: l10n.tr('home_dashboard_action_customize'),
        onPrimary: () => openTimer('focus', autoStart: true),
        onSecondary: () => openTimer('focus'),
      ),
      _RoutineCardData(
        title: l10n.tr('timer_mode_workout'),
        description: l10n.tr('home_dashboard_card_workout_description'),
        minutes: todaySummary.workout,
        accent: AppTheme.accentGreen,
        icon: Icons.fitness_center_outlined,
        primaryLabel: l10n.tr('home_dashboard_action_explore'),
        secondaryLabel: l10n.tr('home_dashboard_action_customize'),
        onPrimary: openWorkout,
        onSecondary: openWorkout,
      ),
      _RoutineCardData(
        title: l10n.tr('timer_mode_sleep'),
        description: l10n.tr('home_dashboard_card_sleep_description'),
        minutes: todaySummary.sleep,
        accent: AppTheme.accentPurple,
        icon: Icons.nights_stay_outlined,
        primaryLabel: l10n.tr('home_dashboard_action_start'),
        secondaryLabel: l10n.tr('home_dashboard_action_customize'),
        onPrimary: () => openTimer('sleep', autoStart: true),
        onSecondary: () => openTimer('sleep'),
      ),
    ];

    return SafeArea(
      child: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: () async {
          ref.invalidate(settingsFutureProvider);
          ref.invalidate(todaySummaryProvider);
          ref.invalidate(latestSleepSoundSummaryProvider);
          ref.invalidate(streakCountProvider);
        },
        child: ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DashboardAppBar(
                    appName: l10n.tr('app_title'),
                    dateLabel: dateLabel,
                    onOpenStats: openStats,
                    onOpenSettings: openAccount,
                  ),
                  const SizedBox(height: 28),
                  _GreetingSection(
                    greeting: greeting,
                    subtitle: greetingSubtitle,
                  ),
                  if (banner != null) ...[const SizedBox(height: 24), banner],
                  const SizedBox(height: 36),
                  _SectionLabel(
                    text: l10n.tr('home_dashboard_quick_start_title'),
                  ),
                  const SizedBox(height: 20),
                  _QuickActionsRow(actions: quickActions),
                  const SizedBox(height: 36),
                  _SectionLabel(text: l10n.tr('home_dashboard_routines_title')),
                  const SizedBox(height: 20),
                  _RoutineCarousel(
                    cards: routineCards,
                    locale: locale,
                    l10n: l10n,
                    streakDays: streakDays,
                  ),
                  const SizedBox(height: 36),
                  _SectionLabel(text: l10n.tr('home_dashboard_progress_title')),
                  const SizedBox(height: 20),
                  _DailyProgressCard(
                    l10n: l10n,
                    locale: locale,
                    focusMinutes: todaySummary.focus,
                    workoutMinutes: todaySummary.workout,
                    sleepMinutes: todaySummary.sleep,
                    focusTarget: focusGoalMinutes,
                  ),
                  const SizedBox(height: 36),
                  _SectionLabel(
                    text: l10n.tr('home_dashboard_integrations_title'),
                  ),
                  const SizedBox(height: 20),
                  _IntegrationsRow(
                    wearablesTitle: l10n.tr(
                      'home_dashboard_integrations_wearables_title',
                    ),
                    wearablesSubtitle: l10n.tr(
                      'home_dashboard_integrations_wearables_subtitle',
                    ),
                    backupTitle: l10n.tr(
                      'home_dashboard_integrations_backup_title',
                    ),
                    backupSubtitle: l10n.tr(
                      'home_dashboard_integrations_backup_subtitle',
                    ),
                    onOpenWearables: openAccount,
                    onOpenBackup: openBackup,
                  ),
                  const SizedBox(height: 36),
                  _PremiumUpsellCard(
                    title: l10n.tr('home_dashboard_premium_title'),
                    subtitle: l10n.tr('home_dashboard_premium_subtitle'),
                    ctaLabel: l10n.tr('home_dashboard_premium_cta'),
                    onTap: openPremium,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget? _buildSyncBanner({
  required BuildContext context,
  required AsyncValue<void> syncState,
  required AsyncValue<User?> authState,
  required AppLocalizations l10n,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final theme = Theme.of(context);

  Widget buildBanner({
    required IconData icon,
    required String text,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: textColor.withValues(alpha: 0.2), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  if (syncState.hasError) {
    return buildBanner(
      icon: Icons.warning_amber_rounded,
      text: l10n.tr('home_sync_error'),
      backgroundColor: colorScheme.errorContainer,
      textColor: colorScheme.onErrorContainer,
    );
  }
  if (authState.value == null) {
    return buildBanner(
      icon: Icons.cloud_sync_outlined,
      text: l10n.tr('home_sync_signed_out'),
      backgroundColor: colorScheme.primaryContainer,
      textColor: colorScheme.onPrimaryContainer,
    );
  }
  if (syncState.isLoading) {
    return buildBanner(
      icon: Icons.sync_rounded,
      text: l10n.tr('home_sync_in_progress'),
      backgroundColor: colorScheme.secondaryContainer,
      textColor: colorScheme.onSecondaryContainer,
    );
  }
  return null;
}

class _DashboardAppBar extends StatelessWidget {
  const _DashboardAppBar({
    required this.appName,
    required this.dateLabel,
    required this.onOpenStats,
    required this.onOpenSettings,
  });

  final String appName;
  final String dateLabel;
  final VoidCallback onOpenStats;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme;
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Text(
              'L',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appName,
                style: textStyle.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(dateLabel, style: textStyle.bodySmall),
            ],
          ),
        ),
        _IconCircleButton(icon: Icons.bar_chart_rounded, onTap: onOpenStats),
        const SizedBox(width: 8),
        _IconCircleButton(icon: Icons.settings_outlined, onTap: onOpenSettings),
      ],
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: theme.colorScheme.onSurface, size: 22),
          ),
        ),
      ),
    );
  }
}

class _GreetingSection extends StatelessWidget {
  const _GreetingSection({required this.greeting, required this.subtitle});

  final String greeting;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FadeInAnimation(
      duration: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.actions});

  final List<_QuickActionConfig> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          Expanded(child: _QuickActionButton(config: actions[i])),
          if (i != actions.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _QuickActionConfig {
  const _QuickActionConfig({
    required this.emoji,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final Color accent;
  final VoidCallback onTap;
}

class _QuickActionButton extends StatefulWidget {
  const _QuickActionButton({required this.config});

  final _QuickActionConfig config;

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.config.accent;
    final theme = Theme.of(context);
    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: _pressed ? 0.96 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: theme.colorScheme.surface,
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.config.onTap,
            onTapDown: (_) => _setPressed(true),
            onTapCancel: () => _setPressed(false),
            onTapUp: (_) => _setPressed(false),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: accent.withValues(alpha: 0.12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.config.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.config.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoutineCarousel extends StatelessWidget {
  const _RoutineCarousel({
    required this.cards,
    required this.locale,
    required this.l10n,
    required this.streakDays,
  });

  final List<_RoutineCardData> cards;
  final Locale locale;
  final AppLocalizations l10n;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemBuilder: (context, index) => _RoutineCard(
          data: cards[index],
          locale: locale,
          l10n: l10n,
          streakDays: streakDays,
        ),
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemCount: cards.length,
      ),
    );
  }
}

class _RoutineCardData {
  const _RoutineCardData({
    required this.title,
    required this.description,
    required this.minutes,
    required this.accent,
    required this.icon,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
  });

  final String title;
  final String description;
  final int minutes;
  final Color accent;
  final IconData icon;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({
    required this.data,
    required this.locale,
    required this.l10n,
    required this.streakDays,
  });

  final _RoutineCardData data;
  final Locale locale;
  final AppLocalizations l10n;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayLabel = l10n.tr('home_dashboard_routine_stat_today', {
      'value': _formatMinutesLabel(data.minutes, locale: locale),
    });
    final streakLabel = l10n.tr('home_dashboard_routine_stat_streak', {
      'days': '$streakDays',
    });
    return SlideInAnimation(
      delay: const Duration(milliseconds: 100),
      child: SizedBox(
        width: 300,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: theme.colorScheme.surface,
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: data.accent.withValues(alpha: 0.12),
                ),
                child: Icon(data.icon, color: data.accent, size: 26),
              ),
              const SizedBox(height: 20),
              Text(
                data.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data.description,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  _RoutineStatChip(
                    icon: Icons.schedule_rounded,
                    label: todayLabel,
                    color: data.accent,
                  ),
                  const SizedBox(width: 8),
                  _RoutineStatChip(
                    icon: Icons.local_fire_department_outlined,
                    label: streakLabel,
                    color: data.accent,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: data.onPrimary,
                style: FilledButton.styleFrom(
                  backgroundColor: data.accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  data.primaryLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutineStatChip extends StatelessWidget {
  const _RoutineStatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyProgressCard extends StatelessWidget {
  const _DailyProgressCard({
    required this.l10n,
    required this.locale,
    required this.focusMinutes,
    required this.workoutMinutes,
    required this.sleepMinutes,
    required this.focusTarget,
  });

  final AppLocalizations l10n;
  final Locale locale;
  final int focusMinutes;
  final int workoutMinutes;
  final int sleepMinutes;
  final int focusTarget;

  @override
  Widget build(BuildContext context) {
    final total = focusMinutes + workoutMinutes + sleepMinutes;
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.tr('home_dashboard_progress_title'),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.tr('duration_minutes_only', {'minutes': '$total'}),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _MetricProgressRow(
            label: l10n.tr('timer_mode_focus'),
            minutes: focusMinutes,
            target: focusTarget,
            locale: locale,
            color: AppTheme.accentBlue,
          ),
          const SizedBox(height: 20),
          _MetricProgressRow(
            label: l10n.tr('timer_mode_workout'),
            minutes: workoutMinutes,
            target: 60,
            locale: locale,
            color: AppTheme.accentGreen,
          ),
          const SizedBox(height: 20),
          _MetricProgressRow(
            label: l10n.tr('timer_mode_sleep'),
            minutes: sleepMinutes,
            target: 480,
            locale: locale,
            color: AppTheme.accentPurple,
          ),
        ],
      ),
    );
  }
}

class _MetricProgressRow extends StatelessWidget {
  const _MetricProgressRow({
    required this.label,
    required this.minutes,
    required this.target,
    required this.locale,
    required this.color,
  });

  final String label;
  final int minutes;
  final int target;
  final Locale locale;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = target <= 0 ? 0.0 : (minutes / target).clamp(0.0, 1.0);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '${_formatMinutesLabel(minutes, locale: locale)} / '
              '${_formatMinutesLabel(target, locale: locale)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _IntegrationsRow extends StatelessWidget {
  const _IntegrationsRow({
    required this.wearablesTitle,
    required this.wearablesSubtitle,
    required this.backupTitle,
    required this.backupSubtitle,
    required this.onOpenWearables,
    required this.onOpenBackup,
  });

  final String wearablesTitle;
  final String wearablesSubtitle;
  final String backupTitle;
  final String backupSubtitle;
  final VoidCallback onOpenWearables;
  final VoidCallback onOpenBackup;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _IntegrationCard(
            icon: Icons.wifi_tethering,
            title: wearablesTitle,
            subtitle: wearablesSubtitle,
            onTap: onOpenWearables,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _IntegrationCard(
            icon: Icons.cloud_upload_outlined,
            title: backupTitle,
            subtitle: backupSubtitle,
            onTap: onOpenBackup,
          ),
        ),
      ],
    );
  }
}

class _IntegrationCard extends StatelessWidget {
  const _IntegrationCard({
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 24),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumUpsellCard extends StatelessWidget {
  const _PremiumUpsellCard({
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: theme.colorScheme.primary,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              ctaLabel,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

String _greetingKeyForHour(int hour) {
  if (hour < 12) {
    return 'home_dashboard_greeting_morning';
  }
  if (hour < 18) {
    return 'home_dashboard_greeting_afternoon';
  }
  return 'home_dashboard_greeting_evening';
}

String _formatMinutesLabel(int minutes, {Locale? locale}) {
  final languageCode = locale?.languageCode ?? 'ko';
  if (minutes <= 0) {
    return languageCode == 'ko' ? '0분' : '0 min';
  }
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (languageCode == 'ko') {
    if (hours > 0 && mins > 0) {
      return '$hours시간 $mins분';
    } else if (hours > 0) {
      return '$hours시간';
    }
    return '$mins분';
  }
  if (hours > 0 && mins > 0) {
    return '${hours}h ${mins}m';
  } else if (hours > 0) {
    return '${hours}h';
  }
  return '${mins}m';
}
