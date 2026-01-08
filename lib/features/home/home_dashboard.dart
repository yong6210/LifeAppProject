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
        icon: Icons.timer_outlined,
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
        icon: Icons.fitness_center_outlined,
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
        icon: Icons.nights_stay_outlined,
        primaryLabel: l10n.tr('home_dashboard_action_start'),
        secondaryLabel: l10n.tr('home_dashboard_action_customize'),
        onPrimary: openSleep,
        onSecondary: openSleep,
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFD8E5E0), // Darker pastel mint
              const Color(0xFFD0E4D8), // Darker pastel sage green
              const Color(0xFFD8E0DD), // Darker pastel aqua
            ],
            stops: const [0.0, 0.5, 1.0],
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
                const SizedBox(height: 28),
                _SectionLabel(text: l10n.tr('home_dashboard_progress_title')),
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
                _SectionLabel(text: l10n.tr('home_dashboard_routines_title')),
                const SizedBox(height: 16),
                _RoutineCarousel(
                  cards: routineCards,
                  locale: locale,
                  l10n: l10n,
                  streakDays: streakDays,
                ),
                const SizedBox(height: 28),
                _SectionLabel(
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
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                data.accent.withValues(alpha: 0.05),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: data.accent.withValues(alpha: 0.2),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(26),
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
                          '${data.minutes}분',
                          style: TextStyle(
                            fontSize: 12,
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
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: data.accent,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
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
    final total = focusMinutes + workoutMinutes + sleepMinutes;
    final focusProgress = focusTarget <= 0 ? 0.0 : (focusMinutes / focusTarget).clamp(0.0, 1.0);
    final workoutProgress = (workoutMinutes / 60).clamp(0.0, 1.0);
    final sleepProgress = (sleepMinutes / 480).clamp(0.0, 1.0);
    final overallProgress = ((focusProgress + workoutProgress + sleepProgress) / 3 * 100).round();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.white.withValues(alpha: 0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentBlue.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppTheme.accentGreen.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
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
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Today\'s Activity',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
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
                target: focusTarget,
                progress: focusProgress,
                color: AppTheme.accentBlue,
                icon: Icons.psychology_rounded,
              ),
              _CircularProgressMetric(
                label: l10n.tr('timer_mode_workout'),
                value: workoutMinutes,
                target: 60,
                progress: workoutProgress,
                color: AppTheme.accentGreen,
                icon: Icons.fitness_center_rounded,
              ),
              _CircularProgressMetric(
                label: l10n.tr('timer_mode_sleep'),
                value: (sleepMinutes / 60).round(),
                target: 8,
                progress: sleepProgress,
                color: AppTheme.accentPurple,
                icon: Icons.nights_stay_rounded,
                isSleep: true,
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
                      'Overall Progress',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$overallProgress% Complete',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
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
    required this.target,
    required this.progress,
    required this.color,
    required this.icon,
    this.isSleep = false,
  });

  final String label;
  final int value;
  final int target;
  final double progress;
  final Color color;
  final IconData icon;
  final bool isSleep;

  @override
  Widget build(BuildContext context) {
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
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          isSleep ? '/ ${target}h' : '/ $target min',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
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
            gradientColors: const [
              Color(0xFF667EEA), // Purple-blue
              Color(0xFF764BA2), // Deep purple
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _IntegrationCard(
            icon: Icons.cloud_upload_outlined,
            title: backupTitle,
            subtitle: backupSubtitle,
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
    required this.onTap,
    required this.gradientColors,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Open',
                  style: TextStyle(
                    fontSize: 14,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
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
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B95).withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        padding: const EdgeInsets.all(28),
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
                    Icons.auto_awesome,
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
                  child: const Row(
                    children: [
                      Icon(Icons.stars, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'PREMIUM',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
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
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 15,
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
                            style: const TextStyle(
                              fontSize: 17,
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
