import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/providers/stats_providers.dart';
import 'package:life_app/l10n/app_localizations.dart';

class WeeklySummaryCard extends ConsumerWidget {
  const WeeklySummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalsAsync = ref.watch(weeklyTotalsProvider);

    return totalsAsync.when(
      data: (totals) {
        final l10n = context.l10n;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tr('stats_weekly_title'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: l10n.tr('session_type_focus'),
                  minutes: totals.focusMinutes,
                ),
                _SummaryRow(
                  label: l10n.tr('session_type_rest'),
                  minutes: totals.restMinutes,
                ),
                _SummaryRow(
                  label: l10n.tr('session_type_workout'),
                  minutes: totals.workoutMinutes,
                ),
                _SummaryRow(
                  label: l10n.tr('session_type_sleep'),
                  minutes: totals.sleepMinutes,
                ),
                const Divider(height: 20),
                Text(
                  l10n.tr('stats_total_label', {
                    'duration': _formatMinutes(totals.totalMinutes, l10n),
                  }),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => _LoadingCard(title: context.l10n.tr('stats_weekly_title')),
      error: (err, _) => _ErrorCard(
        title: context.l10n.tr('stats_weekly_title'),
        message: err.toString(),
      ),
    );
  }
}

class FocusStreakCard extends ConsumerWidget {
  const FocusStreakCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakCountProvider);
    return streakAsync.when(
      data: (streak) {
        final l10n = context.l10n;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ListTile(
            leading: const Icon(
              Icons.local_fire_department_outlined,
              color: Colors.orange,
            ),
            title: Text(l10n.tr('stats_streak_title')),
            subtitle: Text(
              l10n.tr('stats_streak_subtitle', {'days': '$streak'}),
            ),
          ),
        );
      },
      loading: () => _LoadingCard(title: context.l10n.tr('stats_streak_title')),
      error: (err, _) => _ErrorCard(
        title: context.l10n.tr('stats_streak_title'),
        message: err.toString(),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.minutes});

  final String label;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(_formatMinutes(minutes, l10n))],
      ),
    );
  }
}

String _formatMinutes(int minutes, AppLocalizations l10n) {
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (hours == 0) {
    return l10n.tr('duration_minutes_only', {'minutes': '$mins'});
  }
  if (mins == 0) {
    return l10n.tr('duration_hours_only', {'hours': '$hours'});
  }
  return l10n.tr('duration_hours_minutes', {
    'hours': '$hours',
    'minutes': '$mins',
  });
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        title: Text(title),
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.error_outline, color: Colors.redAccent),
        title: Text(title),
        subtitle: Text(
          context.l10n.tr('stats_error_message', {'error': message}),
        ),
      ),
    );
  }
}
