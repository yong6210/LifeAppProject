import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/providers/stats_providers.dart';
import 'package:life_app/utils/date_range.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.tr('stats_appbar_title')),
          bottom: TabBar(
            tabs: [
              Tab(text: context.l10n.tr('stats_tab_daily')),
              Tab(text: context.l10n.tr('stats_tab_weekly')),
              Tab(text: context.l10n.tr('stats_tab_monthly')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _StatsTab(
              bucket: StatsTrendBucket.daily,
              count: 7,
              totalsProvider: dailyTotalsProvider,
            ),
            _StatsTab(
              bucket: StatsTrendBucket.weekly,
              count: 5,
              totalsProvider: weeklyTotalsProvider,
            ),
            _StatsTab(
              bucket: StatsTrendBucket.monthly,
              count: 6,
              totalsProvider: monthlyTotalsProvider,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsTab extends ConsumerWidget {
  const _StatsTab({
    required this.bucket,
    required this.count,
    required this.totalsProvider,
  });

  final StatsTrendBucket bucket;
  final int count;
  final FutureProvider<SummaryTotals> totalsProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalsAsync = ref.watch(totalsProvider);
    final trendAsync = ref.watch(
      statsTrendProvider(StatsTrendRequest(bucket: bucket, count: count)),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        totalsAsync.when(
          data: (totals) => _TotalsCard(totals: totals),
          loading: () => _LoadingCard(
            title: context.l10n.tr('stats_loading_totals'),
          ),
          error: (error, _) => _ErrorCard(
            title: context.l10n.tr('stats_error_totals_title'),
            message: error.toString(),
          ),
        ),
        const SizedBox(height: 16),
        trendAsync.when(
          data: (entries) => _TrendList(bucket: bucket, entries: entries),
          loading: () => _LoadingCard(
            title: context.l10n.tr('stats_loading_trend'),
          ),
          error: (error, _) => _ErrorCard(
            title: context.l10n.tr('stats_error_trend_title'),
            message: error.toString(),
          ),
        ),
      ],
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.totals});

  final SummaryTotals totals;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final metrics = [
      _Metric(l10n.tr('session_type_focus'), totals.focusMinutes),
      _Metric(l10n.tr('session_type_rest'), totals.restMinutes),
      _Metric(l10n.tr('session_type_workout'), totals.workoutMinutes),
      _Metric(l10n.tr('session_type_sleep'), totals.sleepMinutes),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tr('stats_totals_title'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: metrics
                  .map((metric) => _MetricChip(metric: metric))
                  .toList(growable: false),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.tr('stats_totals_overall', {
                'duration': _formatMinutes(totals.totalMinutes, l10n),
              }),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendList extends ConsumerStatefulWidget {
  const _TrendList({required this.bucket, required this.entries});

  final StatsTrendBucket bucket;
  final List<StatsTrendEntry> entries;

  @override
  ConsumerState<_TrendList> createState() => _TrendListState();
}

class _TrendListState extends ConsumerState<_TrendList> {
  bool _showTable = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entries = widget.entries;
    if (entries.every((e) => e.totals.totalMinutes == 0)) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.insights_outlined, size: 32),
              const SizedBox(height: 12),
              Text(
                l10n.tr('stats_trend_empty_title'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(l10n.tr('stats_trend_empty_body')),
            ],
          ),
        ),
      );
    }

    final showTable = _showTable;
    final maxTotal = entries
        .fold<int>(0, (prev, e) => max(prev, e.totals.totalMinutes))
        .clamp(1, 999999);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _trendTitle(widget.bucket, l10n),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  _TrendAccessibilityToggle(
                    showTable: showTable,
                    onToggle: () => setState(() => _showTable = !showTable),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (showTable)
              _TrendDataTable(entries: entries, bucket: widget.bucket)
            else
              ...entries.reversed.map((entry) {
                final ratio = entry.totals.totalMinutes / maxTotal;
                return Semantics(
                  label: l10n.tr('stats_trend_row_semantics', {
                    'label': _labelForEntry(widget.bucket, entry.range, l10n),
                    'value': _formatMinutes(entry.totals.totalMinutes, l10n),
                  }),
                  child: ListTile(
                    title: Text(_labelForEntry(widget.bucket, entry.range, l10n)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: ratio.isFinite ? ratio : 0,
                          minHeight: 6,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _MetricChip(
                              metric: _Metric(
                                l10n.tr('session_type_focus'),
                                entry.totals.focusMinutes,
                              ),
                              dense: true,
                            ),
                            _MetricChip(
                              metric: _Metric(
                                l10n.tr('session_type_rest'),
                                entry.totals.restMinutes,
                              ),
                              dense: true,
                            ),
                            _MetricChip(
                              metric: _Metric(
                                l10n.tr('session_type_workout'),
                                entry.totals.workoutMinutes,
                              ),
                              dense: true,
                            ),
                            _MetricChip(
                              metric: _Metric(
                                l10n.tr('session_type_sleep'),
                                entry.totals.sleepMinutes,
                              ),
                              dense: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Text(
                      _formatMinutes(entry.totals.totalMinutes, l10n),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _TrendAccessibilityToggle extends StatelessWidget {
  const _TrendAccessibilityToggle({
    required this.showTable,
    required this.onToggle,
  });

  final bool showTable;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextButton.icon(
      onPressed: onToggle,
      icon: Icon(showTable ? Icons.bar_chart : Icons.table_chart),
      label: Text(
        showTable
            ? l10n.tr('stats_trend_toggle_chart')
            : l10n.tr('stats_trend_toggle_table'),
      ),
    );
  }
}
class _TrendDataTable extends StatelessWidget {
  const _TrendDataTable({required this.entries, required this.bucket});

  final List<StatsTrendEntry> entries;
  final StatsTrendBucket bucket;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text(l10n.tr('stats_table_period'))),
          DataColumn(label: Text(l10n.tr('session_type_focus'))),
          DataColumn(label: Text(l10n.tr('session_type_rest'))),
          DataColumn(label: Text(l10n.tr('session_type_workout'))),
          DataColumn(label: Text(l10n.tr('session_type_sleep'))),
          DataColumn(label: Text(l10n.tr('stats_table_total'))),
        ],
        rows: entries.reversed.map((entry) {
          return DataRow(
            cells: [
              DataCell(Text(_labelForEntry(bucket, entry.range, l10n))),
              DataCell(Text(_formatMinutes(entry.totals.focusMinutes, l10n))),
              DataCell(Text(_formatMinutes(entry.totals.restMinutes, l10n))),
              DataCell(Text(_formatMinutes(entry.totals.workoutMinutes, l10n))),
              DataCell(Text(_formatMinutes(entry.totals.sleepMinutes, l10n))),
              DataCell(Text(_formatMinutes(entry.totals.totalMinutes, l10n))),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _Metric {
  const _Metric(this.label, this.minutes);
  final String label;
  final int minutes;
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.metric, this.dense = false});
  final _Metric metric;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Chip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: dense
          ? const EdgeInsets.symmetric(horizontal: 8)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      label: Text(
        '${metric.label} ${_formatMinutes(metric.minutes, l10n)}',
        style: dense
            ? Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)
            : null,
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
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
      child: ListTile(
        leading: const Icon(Icons.error_outline, color: Colors.redAccent),
        title: Text(title),
        subtitle: Text(message),
      ),
    );
  }
}

String _trendTitle(StatsTrendBucket bucket, AppLocalizations l10n) {
  switch (bucket) {
    case StatsTrendBucket.daily:
      return l10n.tr('stats_trend_title_daily');
    case StatsTrendBucket.weekly:
      return l10n.tr('stats_trend_title_weekly');
    case StatsTrendBucket.monthly:
      return l10n.tr('stats_trend_title_monthly');
  }
}

String _labelForEntry(
  StatsTrendBucket bucket,
  DateRange range,
  AppLocalizations l10n,
) {
  final start = range.start;
  final endExclusive = range.end;
  switch (bucket) {
    case StatsTrendBucket.daily:
      return l10n.tr('stats_label_daily', {
        'month': '${start.month}',
        'day': '${start.day}',
        'weekday': _weekdayLabel(start.weekday, l10n),
      });
    case StatsTrendBucket.weekly:
      final endInclusive = endExclusive.subtract(const Duration(days: 1));
      return l10n.tr('stats_label_weekly', {
        'startMonth': '${start.month}',
        'startDay': '${start.day}',
        'endMonth': '${endInclusive.month}',
        'endDay': '${endInclusive.day}',
      });
    case StatsTrendBucket.monthly:
      final month = start.month.toString().padLeft(2, '0');
      return l10n.tr('stats_label_monthly', {
        'year': '${start.year}',
        'month': month,
      });
  }
}

String _weekdayLabel(int weekday, AppLocalizations l10n) {
  final labels = [
    l10n.tr('weekday_mon'),
    l10n.tr('weekday_tue'),
    l10n.tr('weekday_wed'),
    l10n.tr('weekday_thu'),
    l10n.tr('weekday_fri'),
    l10n.tr('weekday_sat'),
    l10n.tr('weekday_sun'),
  ];
  return labels[(weekday - 1) % 7];
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
