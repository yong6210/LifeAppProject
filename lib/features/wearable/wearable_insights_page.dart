import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/providers/automation_providers.dart';
import 'package:life_app/providers/wearable_providers.dart';
import 'package:life_app/services/wearable/wearable_repository.dart';

class WearableInsightsPage extends ConsumerWidget {
  const WearableInsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(wearableSummaryProvider);
    final repository = ref.watch(wearableRepositoryProvider);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tr('wearable_title'))),
      body: summaryAsync.when(
        data: (summary) =>
            _SummaryView(summary: summary, repository: repository),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.tr('wearable_error', {'error': '$error'}),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryView extends ConsumerWidget {
  const _SummaryView({required this.summary, required this.repository});

  final WearableSummary summary;
  final WearableRepository repository;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final cards = <Widget>[
      _InfoTile(
        icon: Icons.watch,
        title: summary.connected
            ? l10n.tr('wearable_connected', {'source': summary.source})
            : l10n.tr('wearable_disconnected'),
        subtitle: summary.lastSync == null
            ? l10n.tr('wearable_never_synced')
            : l10n.tr('wearable_last_sync', {
                'timestamp': DateFormat.yMMMd(
                  Localizations.localeOf(context).toLanguageTag(),
                ).add_Hm().format(summary.lastSync!.toLocal()),
              }),
      ),
      _MetricTile(
        icon: Icons.bedtime,
        label: l10n.tr('wearable_sleep_duration'),
        value: _formatMinutes(summary.sleepMinutes, l10n),
      ),
      _MetricTile(
        icon: Icons.favorite,
        label: l10n.tr('wearable_resting_hr'),
        value: l10n.tr('wearable_bpm', {
          'value': '${summary.restingHeartRate}',
        }),
      ),
      _MetricTile(
        icon: Icons.show_chart,
        label: l10n.tr('wearable_hrv'),
        value: l10n.tr('wearable_ms', {'value': '${summary.hrvScore}'}),
      ),
      _MetricTile(
        icon: Icons.directions_walk,
        label: l10n.tr('wearable_steps'),
        value: summary.steps.toString(),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...cards,
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () async {
            final previouslyConnected = summary.connected;
            try {
              final updated = await repository.requestConnect(
                forceRefresh: previouslyConnected,
              );
              if (!context.mounted) return;
              final message = previouslyConnected
                  ? l10n.tr('timer_workout_metrics_refreshed')
                  : l10n.tr('wearable_connected_toast', {
                      'source': updated.source,
                    });
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            } on WearableAuthorizationException catch (error) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.tr('wearable_permission_denied', {
                      'error': error.message,
                    }),
                  ),
                ),
              );
            } catch (error) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.tr('wearable_error', {'error': '$error'})),
                ),
              );
            }
          },
          icon: const Icon(Icons.link_rounded),
          label: Text(
            summary.connected
                ? l10n.tr('wearable_refresh')
                : l10n.tr('wearable_connect'),
          ),
        ),
        if (summary.connected) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              try {
                await repository.disconnect();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.tr('wearable_disconnect_toast'))),
                );
              } catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.tr('wearable_error', {'error': '$error'}),
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.link_off_rounded),
            label: Text(l10n.tr('wearable_disconnect')),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          l10n.tr('wearable_disclaimer'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 32),
        const _AutomationSection(),
      ],
    );
  }

  String _formatMinutes(int minutes, AppLocalizations l10n) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (minutes <= 0) return l10n.tr('wearable_not_available');
    if (hours == 0) {
      return l10n.tr('wearable_minutes', {'value': '$mins'});
    }
    return l10n.tr('wearable_hours_minutes', {
      'hours': '$hours',
      'minutes': '$mins',
    });
  }
}

class _AutomationSection extends ConsumerWidget {
  const _AutomationSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final nextEventAsync = ref.watch(nextCalendarEventProvider);

    final Widget calendarStatus = nextEventAsync.when(
      data: (event) {
        if (event == null) {
          return Text(l10n.tr('automation_calendar_no_events'));
        }
        final locale = Localizations.localeOf(context).toLanguageTag();
        final formatter = DateFormat.yMMMd(locale).add_Hm();
        final formatted = formatter.format(event.startsAt.toLocal());
        return Text(
          l10n.tr('automation_calendar_next_event', {
            'title': event.title,
            'time': formatted,
          }),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text(l10n.tr('automation_calendar_failed')),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.tr('automation_section_title'),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tr('automation_calendar_title'),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.tr('automation_calendar_description'),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                calendarStatus,
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.event_available),
                    label: Text(l10n.tr('automation_calendar_connect')),
                    onPressed: () async {
                      try {
                        final service = ref.read(
                          calendarAutomationServiceProvider,
                        );
                        final granted = await service.requestPermissions();
                        if (!granted) {
                          throw Exception('permission_denied');
                        }
                        if (!context.mounted) return;
                        ref.invalidate(upcomingCalendarEventsProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.tr('automation_calendar_connected'),
                            ),
                          ),
                        );
                      } catch (_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.tr('automation_calendar_permission_error'),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tr('automation_shortcuts_title'),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.tr('automation_shortcuts_description'),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.shortcut),
                    label: Text(l10n.tr('automation_shortcuts_register')),
                    onPressed: () async {
                      try {
                        final service = ref.read(
                          shortcutAutomationServiceProvider,
                        );
                        await service.registerShortcuts(defaultTimerShortcuts);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.tr('automation_shortcuts_registered'),
                            ),
                          ),
                        );
                      } catch (_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.tr('automation_shortcuts_failed'),
                            ),
                          ),
                        );
                      }
                    },
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
