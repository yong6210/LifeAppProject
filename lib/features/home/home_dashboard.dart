import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:life_app/design/app_theme.dart';
import 'package:life_app/features/account/account_page.dart';
import 'package:life_app/features/backup/backup_page.dart';
import 'package:life_app/features/stats/stats_page.dart';
import 'package:life_app/features/subscription/paywall_page.dart';
import 'package:life_app/features/timer/figma_timer_tab.dart';
import 'package:life_app/features/workout/figma_workout_tab.dart';
import 'package:life_app/features/sleep/figma_sleep_tab.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/providers/auth_providers.dart';
import 'package:life_app/providers/session_providers.dart';
import 'package:life_app/providers/settings_providers.dart';
import 'package:life_app/providers/sleep_analysis_providers.dart';
import 'package:life_app/providers/stats_providers.dart';
import 'package:life_app/providers/sync_providers.dart';
import 'package:life_app/widgets/glass_card.dart';
import 'package:life_app/widgets/modern_animations.dart';

class HomeDashboardTab extends ConsumerWidget {
  const HomeDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final backgroundColors = [
      theme.colorScheme.surface,
      theme.colorScheme.surfaceContainerLowest,
    ];

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
    final workoutGoalMinutes =
        (settings?.workoutMinutes ?? 20).clamp(0, 180).toInt();
    final sleepGoalMinutes =
        (settings?.sleepMinutes ?? 30).clamp(0, 600).toInt();
    final focusRemaining = (focusGoalMinutes - todaySummary.focus)
        .clamp(0, focusGoalMinutes)
        .toInt();
    final workoutRemaining = (workoutGoalMinutes - todaySummary.workout)
        .clamp(0, workoutGoalMinutes)
        .toInt();
    final sleepRemaining = (sleepGoalMinutes - todaySummary.sleep)
        .clamp(0, sleepGoalMinutes)
        .toInt();

    final banner = _buildSyncBanner(
      context: context,
      syncState: syncState,
      authState: authState,
      l10n: l10n,
    );

    void openFocus() {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => const FigmaTimerTab(initialMode: 'focus'),
        ),
      );
    }

    void openWorkout() {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => const FigmaWorkoutTab(),
        ),
      );
    }

    void openSleep() {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => const FigmaSleepTab(),
        ),
      );
    }

    void openStats() {
      Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const StatsPage()),
      );
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

    final routineCards = [
      _RoutineCardData(
        title: l10n.tr('timer_mode_focus'),
        description: l10n.tr('home_dashboard_card_focus_description'),
        minutes: todaySummary.focus,
        accent: AppTheme.accentBlue,
        icon: Icons.timer_rounded,
        primaryLabel: l10n.tr('home_dashboard_action_start'),
        secondaryLabel: l10n.tr('home_dashboard_action_customize'),
        onPrimary: openFocus,
        onSecondary: openFocus,
      ),
      _RoutineCardData(
        title: l10n.tr('timer_mode_workout'),
        description: l10n.tr('home_dashboard_card_workout_description'),
        minutes: todaySummary.workout,
        accent: AppTheme.accentGreen,
        icon: Icons.fitness_center_rounded,
        primaryLabel: l10n.tr('home_dashboard_action_start'),
        secondaryLabel: l10n.tr('home_dashboard_action_customize'),
        onPrimary: openWorkout,
        onSecondary: openWorkout,
      ),
      _RoutineCardData(
        title: l10n.tr('timer_mode_sleep'),
        description: l10n.tr('home_dashboard_card_sleep_description'),
        minutes: todaySummary.sleep,
        accent: AppTheme.accentPurple,
        icon: Icons.nights_stay_rounded,
        primaryLabel: l10n.tr('home_dashboard_action_start'),
        secondaryLabel: l10n.tr('home_dashboard_action_customize'),
        onPrimary: openSleep,
        onSecondary: openSleep,
      ),
    ];

    final nextAction = () {
      if (focusRemaining > 0) {
        return _NextActionData(
          title: l10n.tr('home_dashboard_next_action_focus_title'),
          subtitle: l10n.tr('home_dashboard_next_action_focus_subtitle', {
            'minutes': '$focusRemaining',
          }),
          ctaLabel: l10n.tr('home_dashboard_next_action_cta_focus'),
          accent: AppTheme.accentBlue,
          icon: Icons.psychology_rounded,
          onTap: openFocus,
        );
      }
      if (workoutRemaining > 0) {
        return _NextActionData(
          title: l10n.tr('home_dashboard_next_action_workout_title'),
          subtitle: l10n.tr('home_dashboard_next_action_workout_subtitle', {
            'minutes': '$workoutRemaining',
          }),
          ctaLabel: l10n.tr('home_dashboard_next_action_cta_workout'),
          accent: AppTheme.accentGreen,
          icon: Icons.fitness_center_rounded,
          onTap: openWorkout,
        );
      }
      if (sleepRemaining > 0) {
        return _NextActionData(
          title: l10n.tr('home_dashboard_next_action_sleep_title'),
          subtitle: l10n.tr('home_dashboard_next_action_sleep_subtitle', {
            'minutes': '$sleepRemaining',
          }),
          ctaLabel: l10n.tr('home_dashboard_next_action_cta_sleep'),
          accent: AppTheme.accentPurple,
          icon: Icons.nights_stay_rounded,
          onTap: openSleep,
        );
      }
      return _NextActionData(
        title: l10n.tr('home_dashboard_next_action_complete_title'),
        subtitle: l10n.tr('home_dashboard_next_action_complete_subtitle'),
        ctaLabel: l10n.tr('home_dashboard_next_action_cta_complete'),
        accent: AppTheme.eucalyptus,
        icon: Icons.emoji_events_rounded,
        onTap: openStats,
      );
    }();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: backgroundColors,
          ),
        ),
        child: SafeArea(
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                _DashboardAppBar(
                  appName: l10n.tr('app_title'),
                  dateLabel: dateLabel,
                  onOpenStats: openStats,
                  onOpenSettings: openAccount,
                ),
                const SizedBox(height: 20),
                _GreetingSection(
                  greeting: greeting,
                  subtitle: greetingSubtitle,
                ),
                if (banner != null) ...[const SizedBox(height: 20), banner],
                const SizedBox(height: 24),
                _NextActionCard(
                  title: l10n.tr('home_dashboard_next_action_title'),
                  data: nextAction,
                ),
                const SizedBox(height: 28),
                _SectionLabel(
                  key: const Key('home_section_progress'),
                  text: l10n.tr('home_dashboard_progress_title'),
                ),
                const SizedBox(height: 16),
                _DailyProgressCard(
                  l10n: l10n,
                  locale: locale,
                  focusMinutes: todaySummary.focus,
                  workoutMinutes: todaySummary.workout,
                  sleepMinutes: todaySummary.sleep,
                  focusTarget: focusGoalMinutes,
                ),
                const SizedBox(height: 28),
                _SectionLabel(
                  key: const Key('home_section_routines'),
                  text: l10n.tr('home_dashboard_routines_title'),
                ),
                const SizedBox(height: 16),
                _RoutineCarousel(
                  cards: routineCards,
                  locale: locale,
                  l10n: l10n,
                  streakDays: streakDays,
                ),
                const SizedBox(height: 28),
                _SectionLabel(
                  key: const Key('home_section_integrations'),
                  text: l10n.tr('home_dashboard_integrations_title'),
                ),
                const SizedBox(height: 16),
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
                  actionLabel: l10n.tr('home_dashboard_open_action'),
                  onOpenWearables: openAccount,
                  onOpenBackup: openBackup,
                ),
                const SizedBox(height: 36),
                _PremiumUpsellCard(
                  key: const Key('home_section_premium'),
                  title: l10n.tr('home_dashboard_premium_title'),
                  subtitle: l10n.tr('home_dashboard_premium_subtitle'),
                  badgeLabel: l10n.tr('home_dashboard_premium_badge'),
                  ctaLabel: l10n.tr('home_dashboard_premium_cta'),
                  onTap: openPremium,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
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
  const _SectionLabel({required this.text, super.key});

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

class _NextActionData {
  const _NextActionData({
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.accent,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String ctaLabel;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;
}

class _NextActionCard extends StatelessWidget {
  const _NextActionCard({
    required this.title,
    required this.data,
  });

  final String title;
  final _NextActionData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          data.accent.withValues(alpha: 0.14),
          data.accent.withValues(alpha: 0.05),
        ],
      ),
      shadowColor: data.accent,
      shadowOpacity: 0.18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      data.accent,
                      data.accent.withValues(alpha: 0.75),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: data.accent.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(data.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: data.onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: data.accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  textStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(data.ctaLabel),
              ),
            ],
          ),
        ],
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
      height: 330,
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
        child: GlassCard(
          padding: const EdgeInsets.all(26),
          borderRadius: 24,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              data.accent.withValues(alpha: 0.05),
            ],
          ),
          shadowColor: data.accent,
          shadowOpacity: 0.18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          data.accent,
                          data.accent.withValues(alpha: 0.75),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: data.accent.withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(data.icon, color: Colors.white, size: 30),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: data.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: data.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.tr('home_dashboard_routine_duration_label', {
                            'minutes': '${data.minutes}',
                          }),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: data.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                data.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: data.accent,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  height: 1.6,
                ),
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
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      data.accent,
                      data.accent.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: data.accent.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: data.onPrimary,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            data.primaryLabel,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
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
    final theme = Theme.of(context);
    final total = focusMinutes + workoutMinutes + sleepMinutes;
    final focusProgress = focusTarget <= 0 ? 0.0 : (focusMinutes / focusTarget).clamp(0.0, 1.0);
    final workoutProgress = (workoutMinutes / 60).clamp(0.0, 1.0);
    final sleepProgress = (sleepMinutes / 480).clamp(0.0, 1.0);
    final overallProgress = ((focusProgress + workoutProgress + sleepProgress) / 3 * 100).round();
    final focusTargetLabel = l10n.tr('home_dashboard_target_minutes', {
      'minutes': '$focusTarget',
    });
    final workoutTargetLabel = l10n.tr('home_dashboard_target_minutes', {
      'minutes': '60',
    });
    final sleepTargetLabel = l10n.tr('home_dashboard_target_hours', {
      'hours': '8',
    });

    return GlassCard(
      padding: const EdgeInsets.all(28),
      borderRadius: 28,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          Colors.white.withValues(alpha: 0.9),
        ],
      ),
      shadowColor: AppTheme.accentBlue,
      shadowOpacity: 0.15,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tr('home_dashboard_progress_title'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.tr('home_dashboard_today_activity'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentBlue,
                      AppTheme.accentBlue.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentBlue.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      l10n.tr('duration_minutes_only', {'minutes': '$total'}),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CircularProgressMetric(
                label: l10n.tr('timer_mode_focus'),
                value: focusMinutes,
                targetLabel: focusTargetLabel,
                progress: focusProgress,
                color: AppTheme.accentBlue,
                icon: Icons.psychology_rounded,
              ),
              _CircularProgressMetric(
                label: l10n.tr('timer_mode_workout'),
                value: workoutMinutes,
                targetLabel: workoutTargetLabel,
                progress: workoutProgress,
                color: AppTheme.accentGreen,
                icon: Icons.fitness_center_rounded,
              ),
              _CircularProgressMetric(
                label: l10n.tr('timer_mode_sleep'),
                value: (sleepMinutes / 60).round(),
                targetLabel: sleepTargetLabel,
                progress: sleepProgress,
                color: AppTheme.accentPurple,
                icon: Icons.nights_stay_rounded,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.accentBlue.withValues(alpha: 0.1),
                  AppTheme.accentGreen.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.trending_up_rounded,
                    color: overallProgress >= 70
                        ? AppTheme.accentGreen
                        : overallProgress >= 40
                            ? Colors.orange
                            : Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.tr('home_dashboard_overall_progress_title'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      l10n.tr('home_dashboard_overall_progress_complete', {
                        'percent': '$overallProgress',
                      }),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularProgressMetric extends StatelessWidget {
  const _CircularProgressMetric({
    required this.label,
    required this.value,
    required this.targetLabel,
    required this.progress,
    required this.color,
    required this.icon,
  });

  final String label;
  final int value;
  final String targetLabel;
  final double progress;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeCap: StrokeCap.round,
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '$value',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          targetLabel,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
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
    required this.actionLabel,
    required this.onOpenWearables,
    required this.onOpenBackup,
  });

  final String wearablesTitle;
  final String wearablesSubtitle;
  final String backupTitle;
  final String backupSubtitle;
  final String actionLabel;
  final VoidCallback onOpenWearables;
  final VoidCallback onOpenBackup;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _IntegrationCard(
            icon: Icons.wifi_tethering_rounded,
            title: wearablesTitle,
            subtitle: wearablesSubtitle,
            actionLabel: actionLabel,
            onTap: onOpenWearables,
            gradientColors: const [
              Color(0xFF667EEA), // Purple-blue
              Color(0xFF764BA2), // Deep purple
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _IntegrationCard(
            icon: Icons.cloud_upload_rounded,
            title: backupTitle,
            subtitle: backupSubtitle,
            actionLabel: actionLabel,
            onTap: onOpenBackup,
            gradientColors: const [
              Color(0xFFF093FB), // Pink
              Color(0xFFF5576C), // Coral
            ],
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
    required this.actionLabel,
    required this.onTap,
    required this.gradientColors,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors,
      ),
      shadowColor: gradientColors.first,
      shadowOpacity: 0.25,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.3),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                actionLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PremiumUpsellCard extends StatelessWidget {
  const _PremiumUpsellCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.ctaLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String badgeLabel;
  final String ctaLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(28),
      borderRadius: 28,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFD89B), // Gold
          Color(0xFFFF6B95), // Pink
          Color(0xFF9B59B6), // Purple
        ],
        stops: [0.0, 0.5, 1.0],
      ),
      shadowColor: const Color(0xFFFF6B95),
      shadowOpacity: 0.35,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white.withValues(alpha: 0.3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      badgeLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.95),
              fontWeight: FontWeight.w500,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFFFF6B95),
                            Color(0xFF9B59B6),
                          ],
                        ).createShader(bounds),
                        child: Text(
                          ctaLabel,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFFFF6B95),
                            Color(0xFF9B59B6),
                          ],
                        ).createShader(bounds),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
