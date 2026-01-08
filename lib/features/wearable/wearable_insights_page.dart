import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:life_app/design/app_theme.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/providers/automation_providers.dart';
import 'package:life_app/providers/wearable_providers.dart';
import 'package:life_app/services/wearable/wearable_repository.dart';
import 'package:life_app/widgets/glass_card.dart';

class WearableInsightsPage extends ConsumerWidget {
  const WearableInsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(wearableSummaryProvider);
    final repository = ref.watch(wearableRepositoryProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF1a2a32),
                    const Color(0xFF0f1519),
                    const Color(0xFF0a0d10),
                  ]
                : [
                    const Color(0xFFE8F4FF),
                    const Color(0xFFDEEEFF),
                    const Color(0xFFFFFFFF),
                  ],
          ),
        ),
        child: SafeArea(
          child: summaryAsync.when(
            data: (summary) => _SummaryView(
              summary: summary,
              repository: repository,
              isDark: isDark,
            ),
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
        ),
      ),
    );
  }
}

class _SummaryView extends ConsumerWidget {
  const _SummaryView({
    required this.summary,
    required this.repository,
    required this.isDark,
  });

  final WearableSummary summary;
  final WearableRepository repository;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Back button and title
        Row(
          children: [
            GlassCard(
              onTap: () => Navigator.of(context).pop(),
              padding: const EdgeInsets.all(12),
              borderRadius: 12,
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: isDark ? Colors.white : AppTheme.electricViolet,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    AppTheme.electricViolet,
                    AppTheme.teal,
                  ],
                ).createShader(bounds),
                child: Text(
                  l10n.tr('wearable_title'),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Connection status
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
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        // Metrics grid
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.bedtime,
                label: l10n.tr('wearable_sleep_duration'),
                value: _formatMinutes(summary.sleepMinutes, l10n),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                icon: Icons.favorite,
                label: l10n.tr('wearable_resting_hr'),
                value: l10n.tr('wearable_bpm', {
                  'value': '${summary.restingHeartRate}',
                }),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.show_chart,
                label: l10n.tr('wearable_hrv'),
                value: l10n.tr('wearable_ms', {'value': '${summary.hrvScore}'}),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                icon: Icons.directions_walk,
                label: l10n.tr('wearable_steps'),
                value: summary.steps.toString(),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Connect/Refresh button
        GlassCard(
          onTap: () async {
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
          padding: const EdgeInsets.all(20),
          borderRadius: 20,
          gradient: LinearGradient(
            colors: [
              AppTheme.electricViolet.withValues(alpha: 0.8),
              AppTheme.teal.withValues(alpha: 0.8),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.link_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                summary.connected
                    ? l10n.tr('wearable_refresh')
                    : l10n.tr('wearable_connect'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        if (summary.connected) ...[
          const SizedBox(height: 12),
          GlassCard(
            onTap: () async {
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
            padding: const EdgeInsets.all(20),
            borderRadius: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.link_off_rounded,
                  color: isDark ? AppTheme.teal : AppTheme.electricViolet,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.tr('wearable_disconnect'),
                  style: TextStyle(
                    color: isDark ? AppTheme.teal : AppTheme.electricViolet,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        GlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: isDark ? Colors.white70 : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.tr('wearable_disclaimer'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white70 : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _AutomationSection(isDark: isDark),
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
  const _AutomationSection({required this.isDark});

  final bool isDark;

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
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.electricViolet.withValues(alpha: 0.3),
                  AppTheme.teal.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isDark ? AppTheme.teal : AppTheme.electricViolet,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white70 : theme.colorScheme.onSurface.withValues(alpha: 0.7),
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

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: isDark ? AppTheme.teal : AppTheme.electricViolet,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white70 : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
