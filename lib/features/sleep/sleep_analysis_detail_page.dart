import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/providers/sleep_analysis_providers.dart';
import 'package:life_app/services/audio/sleep_sound_analyzer.dart';

class SleepAnalysisDetailPage extends ConsumerWidget {
  const SleepAnalysisDetailPage({super.key, required this.summary});

  final SleepSoundSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final score = summary.score;

    final IconData icon;
    final String title;
    final Color color;

    switch (score) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('sleep_analysis_detail_title')),
        actions: [
          IconButton(
            tooltip: l10n.tr('sleep_analysis_delete_data_tooltip'),
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text(l10n.tr('sleep_analysis_delete_data_title')),
                  content: Text(l10n.tr('sleep_analysis_delete_data_message')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: Text(l10n.tr('dialog_cancel')),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child:
                          Text(l10n.tr('sleep_analysis_delete_data_confirm')),
                    ),
                  ],
                ),
              );
              if (confirm != true) return;
              await ref.read(clearSleepSoundSummaryProvider(summary).future);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(l10n.tr('sleep_analysis_delete_data_done'))),
              );
              Navigator.of(context).maybePop();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(l10n.tr('sleep_analysis_privacy_title')),
              subtitle: Text(l10n.tr('sleep_analysis_privacy_body')),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(title, style: theme.textTheme.headlineSmall),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildStatTile(
            l10n.tr('sleep_detail_total_duration'),
            _formatDuration(summary.duration),
          ),
          _buildStatTile(
            l10n.tr('sleep_detail_restful_ratio'),
            '${(summary.restfulSampleRatio * 100).toStringAsFixed(1)}%',
          ),
          _buildStatTile(
            l10n.tr('sleep_detail_restful_minutes'),
            l10n.tr('duration_minutes_only',
                {'minutes': summary.restfulMinutes.round().toString()}),
          ),
          _buildStatTile(
            l10n.tr('sleep_detail_loud_events'),
            summary.loudEventCount.toString(),
          ),
          _buildStatTile(
            l10n.tr('sleep_detail_max_amplitude'),
            '${(summary.maxAmplitude * 100).toStringAsFixed(0)}%',
          ),
          const SizedBox(height: 16),
          if (summary.noiseEvents.isNotEmpty)
            ExpansionTile(
              title: Text(l10n.tr('sleep_detail_noise_timeline')),
              children: summary.noiseEvents
                  .map((event) => ListTile(
                        leading: const Icon(Icons.volume_up),
                        title: Text(l10n.tr('sleep_detail_noise_event_at',
                            {'time': _formatDuration(event.offset)})),
                        subtitle: Text(l10n.tr(
                            'sleep_detail_noise_event_duration',
                            {'duration': '${event.duration.inSeconds}s'})),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String title, String value) {
    return ListTile(
      title: Text(title),
      trailing: Text(value, style: const TextStyle(fontSize: 16)),
    );
  }

  String _formatDuration(Duration d) {
    d = d.abs();
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }
}
