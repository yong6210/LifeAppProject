import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/features/sleep/sleep_analysis_detail_page.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/providers/sleep_analysis_providers.dart';
import 'package:life_app/services/audio/sleep_sound_analyzer.dart';

class SleepAnalysisResultCard extends ConsumerWidget {
  const SleepAnalysisResultCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(latestSleepSoundSummaryProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return summaryAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, stack) => Card(
        color: theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.tr('generic_error_short', {'error': '$err'})),
        ),
      ),
      data: (summary) {
        if (summary == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.nights_stay_outlined, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    l10n.tr('sleep_analysis_no_data_title'),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.tr('sleep_analysis_no_data_body'),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final IconData icon;
        final String title;
        final Color color;

        switch (summary.score) {
          case SleepSoundScore.restful:
            icon = Icons.check_circle_outline;
            title = l10n.tr('sleep_analysis_restful_title');
            color = Colors.green;
            break;
          case SleepSoundScore.moderate:
            icon = Icons.warning_amber_rounded;
            title = l10n.tr('sleep_analysis_moderate_title');
            color = Colors.orange;
            break;
          case SleepSoundScore.disrupted:
            icon = Icons.error_outline;
            title = l10n.tr('sleep_analysis_disrupted_title');
            color = Colors.red;
            break;
        }

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SleepAnalysisDetailPage(summary: summary),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color, size: 28),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(title, style: theme.textTheme.titleMedium),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.tr('sleep_analysis_restful_minutes', {
                      'minutes': '${summary.restfulMinutes.round()}'
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.tr('sleep_analysis_loud_events', {
                      'count': '${summary.loudEventCount}'
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
