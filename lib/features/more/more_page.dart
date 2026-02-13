import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:life_app/features/backup/backup_page.dart';
import 'package:life_app/features/journal/journal_page.dart';
import 'package:life_app/features/sleep/sleep_session_page.dart';
import 'package:life_app/features/stats/stats_page.dart';
import 'package:life_app/features/timer/focus_session_page.dart';
import 'package:life_app/features/timer/guided_session_picker_page.dart';
import 'package:life_app/features/workout/workout_session_page.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/models/settings.dart';
import 'package:life_app/providers/session_providers.dart';
import 'package:life_app/providers/settings_providers.dart';
import 'package:life_app/services/analytics/analytics_service.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final sidePadding = math.max(16.0, (screenWidth - 620) / 2);
    final topPadding = screenWidth < 380 ? 10.0 : 14.0;
    final canPop = Navigator.of(context).canPop();

    final settings = ref.watch(settingsFutureProvider).maybeWhen(
          data: (value) => value,
          orElse: Settings.new,
        );
    final today = ref
        .watch(todaySummaryProvider)
        .maybeWhen(data: (value) => value, orElse: TodaySummary.new);

    final focusGoal = settings.focusMinutes > 0 ? settings.focusMinutes : 25;
    const workoutGoal = 30;
    const sleepGoalMinutes = 8 * 60;

    final focusRate = (today.focus / focusGoal).clamp(0.0, 1.0);
    final workoutRate = (today.workout / workoutGoal).clamp(0.0, 1.0);
    final sleepRate = (today.sleep / sleepGoalMinutes).clamp(0.0, 1.0);

    final totalRate =
        ((focusRate + workoutRate + sleepRate) / 3).clamp(0.0, 1.0);

    final focusRemaining = (focusGoal - today.focus).clamp(0, focusGoal);
    final workoutRemaining =
        (workoutGoal - today.workout).clamp(0, workoutGoal);
    final sleepRemaining =
        (sleepGoalMinutes - today.sleep).clamp(0, sleepGoalMinutes);

    final backupDays = settings.lastBackupAt == null
        ? null
        : DateTime.now()
            .toUtc()
            .difference(settings.lastBackupAt!.toUtc())
            .inDays;

    final nowActions = [
      _HubAction(
        title: l10n.tr('more_hub_action_focus_title'),
        subtitle: focusRate >= 1
            ? l10n.tr('more_hub_action_focus_subtitle_done')
            : l10n.tr('more_hub_action_focus_subtitle_pending'),
        status: focusRate >= 1
            ? l10n.tr('more_hub_status_done')
            : l10n.tr('more_hub_status_minutes_left', {
                'minutes': '$focusRemaining',
              }),
        icon: Icons.timer_outlined,
        color: _HubPalette.focus,
        tag: l10n.tr('more_hub_tag_now'),
        semanticLabel: l10n.tr('more_hub_action_focus_title'),
        onTap: () => _openFocus(context, source: 'now_focus'),
      ),
      _HubAction(
        title: l10n.tr('more_hub_action_workout_title'),
        subtitle: workoutRate >= 1
            ? l10n.tr('more_hub_action_workout_subtitle_done')
            : l10n.tr('more_hub_action_workout_subtitle_pending'),
        status: workoutRate >= 1
            ? l10n.tr('more_hub_status_done')
            : l10n.tr('more_hub_status_minutes_left', {
                'minutes': '$workoutRemaining',
              }),
        icon: Icons.directions_run_rounded,
        color: _HubPalette.workout,
        tag: l10n.tr('more_hub_tag_recommended'),
        semanticLabel: l10n.tr('more_hub_action_workout_title'),
        onTap: () => _openWorkout(context, source: 'now_workout'),
      ),
      _HubAction(
        title: l10n.tr('more_hub_action_sleep_title'),
        subtitle: sleepRate >= 1
            ? l10n.tr('more_hub_action_sleep_subtitle_done')
            : l10n.tr('more_hub_action_sleep_subtitle_pending'),
        status: sleepRate >= 1
            ? l10n.tr('more_hub_status_done')
            : l10n.tr('more_hub_status_hours_left', {
                'hours': (sleepRemaining / 60).toStringAsFixed(1),
              }),
        icon: Icons.nights_stay_outlined,
        color: _HubPalette.sleep,
        tag: l10n.tr('more_hub_tag_evening'),
        semanticLabel: l10n.tr('more_hub_action_sleep_title'),
        onTap: () => _openSleep(context, source: 'now_sleep'),
      ),
      _HubAction(
        title: l10n.tr('more_hub_action_guided_title'),
        subtitle: l10n.tr('more_hub_action_guided_subtitle'),
        status: l10n.tr('more_hub_action_guided_status'),
        icon: Icons.route_outlined,
        color: _HubPalette.guided,
        tag: l10n.tr('more_hub_tag_recommended'),
        semanticLabel: l10n.tr('more_hub_action_guided_title'),
        onTap: () => _openGuidedSessions(context, source: 'now_guided'),
      ),
    ];

    final trackingActions = [
      _HubAction(
        title: l10n.tr('more_hub_action_journal_title'),
        subtitle: l10n.tr('more_hub_action_journal_subtitle'),
        status: l10n.tr('more_hub_action_journal_status'),
        icon: Icons.menu_book_rounded,
        color: _HubPalette.journal,
        tag: l10n.tr('more_hub_tag_record'),
        semanticLabel: l10n.tr('more_hub_action_journal_title'),
        onTap: () => _openJournal(context, source: 'tracking_journal'),
      ),
      _HubAction(
        title: l10n.tr('more_hub_action_stats_title'),
        subtitle: l10n.tr('more_hub_action_stats_subtitle'),
        status: l10n.tr('more_hub_action_stats_status', {
          'percent': '${(totalRate * 100).round()}',
        }),
        icon: Icons.stacked_bar_chart_rounded,
        color: _HubPalette.stats,
        tag: l10n.tr('more_hub_tag_analysis'),
        semanticLabel: l10n.tr('more_hub_action_stats_title'),
        onTap: () => _openStats(context, source: 'tracking_stats'),
      ),
    ];

    final dataActions = [
      _HubAction(
        title: l10n.tr('more_hub_action_backup_title'),
        subtitle: l10n.tr('more_hub_action_backup_subtitle'),
        status: backupDays == null
            ? l10n.tr('more_hub_action_backup_status_none')
            : l10n.tr('more_hub_action_backup_status_days', {
                'days': '$backupDays',
              }),
        icon: Icons.cloud_upload_outlined,
        color: _HubPalette.backup,
        tag: l10n.tr('more_hub_tag_safe'),
        semanticLabel: l10n.tr('more_hub_action_backup_title'),
        onTap: () => _openBackup(context, source: 'data_backup'),
      ),
    ];

    final intentTiles = [
      _IntentTile(
        title: l10n.tr('more_hub_section_now_title'),
        subtitle: l10n.tr('more_hub_section_now_subtitle'),
        icon: Icons.bolt_rounded,
        color: _HubPalette.focus,
        onTap: () => _openFocus(context, source: 'intent_now'),
      ),
      _IntentTile(
        title: l10n.tr('more_hub_section_tracking_title'),
        subtitle: l10n.tr('more_hub_section_tracking_subtitle'),
        icon: Icons.insights_rounded,
        color: _HubPalette.stats,
        onTap: () => _openStats(context, source: 'intent_tracking'),
      ),
      _IntentTile(
        title: l10n.tr('more_hub_section_data_title'),
        subtitle: l10n.tr('more_hub_section_data_subtitle'),
        icon: Icons.shield_outlined,
        color: _HubPalette.backup,
        onTap: () => _openBackup(context, source: 'intent_data'),
      ),
    ];

    final pinned = [
      _ShortcutItem(
        label: l10n.tr('more_item_focus'),
        icon: Icons.timer_outlined,
        color: _HubPalette.focus,
        semanticLabel: l10n.tr('more_item_focus'),
        onTap: () => _openFocus(context, source: 'pinned_focus'),
      ),
      _ShortcutItem(
        label: l10n.tr('more_item_workout'),
        icon: Icons.directions_run_rounded,
        color: _HubPalette.workout,
        semanticLabel: l10n.tr('more_item_workout'),
        onTap: () => _openWorkout(context, source: 'pinned_workout'),
      ),
      _ShortcutItem(
        label: l10n.tr('more_item_sleep'),
        icon: Icons.nights_stay_outlined,
        color: _HubPalette.sleep,
        semanticLabel: l10n.tr('more_item_sleep'),
        onTap: () => _openSleep(context, source: 'pinned_sleep'),
      ),
      _ShortcutItem(
        label: l10n.tr('more_item_journal'),
        icon: Icons.menu_book_rounded,
        color: _HubPalette.journal,
        semanticLabel: l10n.tr('more_item_journal'),
        onTap: () => _openJournal(context, source: 'pinned_journal'),
      ),
      _ShortcutItem(
        label: l10n.tr('more_item_stats'),
        icon: Icons.stacked_bar_chart_rounded,
        color: _HubPalette.stats,
        semanticLabel: l10n.tr('more_item_stats'),
        onTap: () => _openStats(context, source: 'pinned_stats'),
      ),
      _ShortcutItem(
        label: l10n.tr('more_item_backup'),
        icon: Icons.cloud_upload_outlined,
        color: _HubPalette.backup,
        semanticLabel: l10n.tr('more_item_backup'),
        onTap: () => _openBackup(context, source: 'pinned_backup'),
      ),
      _ShortcutItem(
        label: l10n.tr('casual_home_quick_guided'),
        icon: Icons.route_outlined,
        color: _HubPalette.guided,
        semanticLabel: l10n.tr('casual_home_quick_guided'),
        onTap: () => _openGuidedSessions(context, source: 'pinned_guided'),
      ),
    ];

    return Scaffold(
      backgroundColor: _HubPalette.canvas,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFBF6),
              Color(0xFFF8F2E9),
              Color(0xFFF5F4FF),
            ],
          ),
        ),
        child: Stack(
          children: [
            const _MoreBackdrop(),
            SafeArea(
              child: Scrollbar(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          sidePadding,
                          topPadding,
                          sidePadding,
                          12,
                        ),
                        child: _MoreHeader(canPop: canPop),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          sidePadding,
                          0,
                          sidePadding,
                          12,
                        ),
                        child: _IntentBoardCard(items: intentTiles),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          sidePadding,
                          0,
                          sidePadding,
                          12,
                        ),
                        child: _FocusSummaryCard(
                          focusRate: focusRate,
                          workoutRate: workoutRate,
                          sleepRate: sleepRate,
                          focusRemaining: focusRemaining,
                          workoutRemaining: workoutRemaining,
                          sleepRemaining: sleepRemaining,
                          onStartFocus: () =>
                              _openFocus(context, source: 'summary_focus'),
                          onOpenStats: () =>
                              _openStats(context, source: 'summary_stats'),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          sidePadding,
                          0,
                          sidePadding,
                          12,
                        ),
                        child: _PinnedShortcuts(items: pinned),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          sidePadding,
                          0,
                          sidePadding,
                          12,
                        ),
                        child: _HubSectionCard(
                          title: l10n.tr('more_hub_section_now_title'),
                          subtitle: l10n.tr('more_hub_section_now_subtitle'),
                          actions: nowActions,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          sidePadding,
                          0,
                          sidePadding,
                          12,
                        ),
                        child: _HubSectionCard(
                          title: l10n.tr('more_hub_section_tracking_title'),
                          subtitle:
                              l10n.tr('more_hub_section_tracking_subtitle'),
                          actions: trackingActions,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          sidePadding,
                          0,
                          sidePadding,
                          92,
                        ),
                        child: _HubSectionCard(
                          title: l10n.tr('more_hub_section_data_title'),
                          subtitle: l10n.tr('more_hub_section_data_subtitle'),
                          actions: dataActions,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFocus(BuildContext context, {required String source}) {
    _trackTap('focus', source: source);
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const FocusSessionPage(
          autoStart: true,
        ),
      ),
    );
  }

  void _openWorkout(BuildContext context, {required String source}) {
    _trackTap('workout', source: source);
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const WorkoutSessionPage(),
      ),
    );
  }

  void _openSleep(BuildContext context, {required String source}) {
    _trackTap('sleep', source: source);
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const SleepSessionPage(),
      ),
    );
  }

  void _openJournal(BuildContext context, {required String source}) {
    _trackTap('journal', source: source);
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const JournalPage(),
      ),
    );
  }

  void _openStats(BuildContext context, {required String source}) {
    _trackTap('stats', source: source);
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const StatsPage(),
      ),
    );
  }

  void _openBackup(BuildContext context, {required String source}) {
    _trackTap('backup', source: source);
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const BackupPage(),
      ),
    );
  }

  void _openGuidedSessions(BuildContext context, {required String source}) {
    _trackTap('guided_sessions', source: source);
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const GuidedSessionPickerPage(),
      ),
    );
  }

  void _trackTap(String action, {required String source}) {
    unawaited(
      AnalyticsService.logEvent('more_hub_tap', {
        'action': action,
        'source': source,
      }),
    );
  }
}

class _MoreHeader extends StatelessWidget {
  const _MoreHeader({required this.canPop});

  final bool canPop;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _HubPalette.cardBorder),
      ),
      child: Row(
        children: [
          if (canPop) ...[
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: _HubPalette.focus.withValues(alpha: 0.12),
                foregroundColor: _HubPalette.ink,
              ),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tr('more_hub_title'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: _HubPalette.ink,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.tr('more_hub_subtitle'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _HubPalette.inkSoft,
                        fontWeight: FontWeight.w600,
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

class _FocusSummaryCard extends StatelessWidget {
  const _FocusSummaryCard({
    required this.focusRate,
    required this.workoutRate,
    required this.sleepRate,
    required this.focusRemaining,
    required this.workoutRemaining,
    required this.sleepRemaining,
    required this.onStartFocus,
    required this.onOpenStats,
  });

  final double focusRate;
  final double workoutRate;
  final double sleepRate;
  final int focusRemaining;
  final int workoutRemaining;
  final int sleepRemaining;
  final VoidCallback onStartFocus;
  final VoidCallback onOpenStats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final allDone = focusRate >= 1 && workoutRate >= 1 && sleepRate >= 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF20273A),
            Color(0xFF2D3A5A),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tr('more_hub_summary_title'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            allDone
                ? l10n.tr('more_hub_summary_body_done')
                : l10n.tr('more_hub_summary_body_pending'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniStatusChip(
                label: focusRate >= 1
                    ? l10n.tr('more_hub_summary_chip_focus_done')
                    : l10n.tr('more_hub_summary_chip_focus_left', {
                        'minutes': '$focusRemaining',
                      }),
                color: _HubPalette.focus,
              ),
              _MiniStatusChip(
                label: workoutRate >= 1
                    ? l10n.tr('more_hub_summary_chip_workout_done')
                    : l10n.tr('more_hub_summary_chip_workout_left', {
                        'minutes': '$workoutRemaining',
                      }),
                color: _HubPalette.workout,
              ),
              _MiniStatusChip(
                label: sleepRate >= 1
                    ? l10n.tr('more_hub_summary_chip_sleep_done')
                    : l10n.tr('more_hub_summary_chip_sleep_left', {
                        'hours': (sleepRemaining / 60).toStringAsFixed(1),
                      }),
                color: _HubPalette.sleep,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: onStartFocus,
                style: FilledButton.styleFrom(
                  backgroundColor: _HubPalette.focus,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.tr('more_hub_summary_focus_cta')),
              ),
              FilledButton.tonal(
                onPressed: onOpenStats,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.tr('more_hub_summary_stats_cta')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IntentBoardCard extends StatelessWidget {
  const _IntentBoardCard({required this.items});

  final List<_IntentTile> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _HubPalette.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth > 720
              ? 3
              : constraints.maxWidth > 520
                  ? 2
                  : 1;
          const spacing = 10.0;
          final itemWidth =
              (constraints.maxWidth - (spacing * (columns - 1))) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final item in items)
                SizedBox(
                  width: itemWidth,
                  child: _IntentBoardTile(item: item),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _IntentBoardTile extends StatelessWidget {
  const _IntentBoardTile({required this.item});

  final _IntentTile item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.color, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: _HubPalette.ink,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _HubPalette.inkSoft,
                            fontWeight: FontWeight.w600,
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

class _MiniStatusChip extends StatelessWidget {
  const _MiniStatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _PinnedShortcuts extends StatelessWidget {
  const _PinnedShortcuts({required this.items});

  final List<_ShortcutItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _HubPalette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tr('more_hub_pinned_title'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: _HubPalette.ink,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in items) _ShortcutChip(item: item),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  const _ShortcutChip({required this.item});

  final _ShortcutItem item;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: item.semanticLabel,
      child: Material(
        color: item.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: item.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, size: 16, color: item.color),
                const SizedBox(width: 6),
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: _HubPalette.ink,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HubSectionCard extends StatelessWidget {
  const _HubSectionCard({
    required this.title,
    required this.subtitle,
    required this.actions,
  });

  final String title;
  final String subtitle;
  final List<_HubAction> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _HubPalette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _HubPalette.ink,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _HubPalette.inkSoft,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          for (final action in actions) _HubActionTile(action: action),
        ],
      ),
    );
  }
}

class _HubActionTile extends StatelessWidget {
  const _HubActionTile({required this.action});

  final _HubAction action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        label: action.semanticLabel,
        child: Material(
          color: action.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: action.onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: action.color.withValues(alpha: 0.17),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(action.icon, color: action.color, size: 21),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          action.title,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: _HubPalette.ink,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          action.subtitle,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: _HubPalette.inkSoft,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _TagPill(
                              label: action.tag,
                              color: action.color,
                            ),
                            _TagPill(
                              label: action.status,
                              color: _HubPalette.inkSoft,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _HubPalette.inkSoft,
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

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _MoreBackdrop extends StatelessWidget {
  const _MoreBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -90,
            child: _shape(
              size: 250,
              color: const Color(0xFFFFD8AE).withValues(alpha: 0.28),
            ),
          ),
          Positioned(
            top: 96,
            right: -100,
            child: _shape(
              size: 220,
              color: const Color(0xFFBED9FF).withValues(alpha: 0.24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shape({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _HubAction {
  const _HubAction({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.icon,
    required this.color,
    required this.tag,
    required this.semanticLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String status;
  final IconData icon;
  final Color color;
  final String tag;
  final String semanticLabel;
  final VoidCallback onTap;
}

class _ShortcutItem {
  const _ShortcutItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.semanticLabel,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String semanticLabel;
  final VoidCallback onTap;
}

class _IntentTile {
  const _IntentTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _HubPalette {
  static const canvas = Color(0xFFFFFBF6);
  static const ink = Color(0xFF1F2633);
  static const inkSoft = Color(0xFF69748A);
  static const cardBorder = Color(0xFFE6DED2);

  static const focus = Color(0xFF2F80ED);
  static const workout = Color(0xFFF2994A);
  static const sleep = Color(0xFF6C63FF);
  static const journal = Color(0xFF2CA99F);
  static const stats = Color(0xFF4F46E5);
  static const backup = Color(0xFFB9802E);
  static const guided = Color(0xFFE76F93);
}
