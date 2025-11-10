import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:life_app/design/app_theme.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/providers/stats_providers.dart';
import 'package:life_app/utils/date_range.dart';
import 'package:life_app/widgets/modern_animations.dart';
import 'package:life_app/widgets/glass_card.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0F1419)
            : theme.colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          title: Text(
            context.l10n.tr('stats_appbar_title'),
            style: TextStyle(
              color: isDark ? Colors.white : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: AppTheme.eucalyptus,
            indicatorWeight: 3,
            labelColor: isDark ? Colors.white : theme.colorScheme.primary,
            unselectedLabelColor: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : theme.colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
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
    final highlightAsync = bucket == StatsTrendBucket.daily
        ? ref.watch(weeklyHighlightProvider)
        : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (highlightAsync != null) ...[
          highlightAsync.when(
            data: (highlight) => highlight == null
                ? const _EmptyHighlightCard()
                : _WeeklyHighlightCard(highlight: highlight),
            loading: () =>
                _LoadingCard(title: context.l10n.tr('stats_highlight_title')),
            error: (error, _) => _ErrorCard(
              title: context.l10n.tr('stats_highlight_title'),
              message: error.toString(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        totalsAsync.when(
          data: (totals) => _TotalsCard(totals: totals),
          loading: () =>
              _LoadingCard(title: context.l10n.tr('stats_loading_totals')),
          error: (error, _) => _ErrorCard(
            title: context.l10n.tr('stats_error_totals_title'),
            message: error.toString(),
          ),
        ),
        const SizedBox(height: 16),
        trendAsync.when(
          data: (entries) => _TrendList(bucket: bucket, entries: entries),
          loading: () =>
              _LoadingCard(title: context.l10n.tr('stats_loading_trend')),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final metrics = [
      _Metric(
        l10n.tr('session_type_focus'),
        totals.focusMinutes,
        AppTheme.teal,
      ),
      _Metric(
        l10n.tr('session_type_rest'),
        totals.restMinutes,
        AppTheme.lime,
      ),
      _Metric(
        l10n.tr('session_type_workout'),
        totals.workoutMinutes,
        AppTheme.coral,
      ),
      _Metric(
        l10n.tr('session_type_sleep'),
        totals.sleepMinutes,
        AppTheme.electricViolet,
      ),
    ];

    // Calculate percentages for visual representation
    final total = totals.totalMinutes;
    final focusPercent = total > 0 ? (totals.focusMinutes / total) : 0.0;
    final restPercent = total > 0 ? (totals.restMinutes / total) : 0.0;
    final workoutPercent = total > 0 ? (totals.workoutMinutes / total) : 0.0;
    final sleepPercent = total > 0 ? (totals.sleepMinutes / total) : 0.0;

    return FadeInAnimation(
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        borderRadius: 20,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppTheme.eucalyptus.withValues(alpha: 0.1),
                  AppTheme.teal.withValues(alpha: 0.05),
                ]
              : [
                  Colors.white.withValues(alpha: 0.95),
                  Colors.white.withValues(alpha: 0.85),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.eucalyptus, AppTheme.teal],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_graph,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.tr('stats_totals_title'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Circular activity breakdown
            Row(
              children: [
                // Segmented ring showing activity distribution
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CustomPaint(
                          painter: _ActivityRingPainter(
                            focusPercent: focusPercent,
                            restPercent: restPercent,
                            workoutPercent: workoutPercent,
                            sleepPercent: sleepPercent,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatMinutes(totals.totalMinutes, l10n),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color:
                                  isDark ? Colors.white : theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: metrics
                        .map((metric) => _MetricChip(metric: metric))
                        .toList(growable: false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for activity ring showing distribution
class _ActivityRingPainter extends CustomPainter {
  _ActivityRingPainter({
    required this.focusPercent,
    required this.restPercent,
    required this.workoutPercent,
    required this.sleepPercent,
  });

  final double focusPercent;
  final double restPercent;
  final double workoutPercent;
  final double sleepPercent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final strokeWidth = 12.0;

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Draw segments
    const startAngle = -pi / 2; // Start from top
    var currentAngle = startAngle;

    final segments = [
      (focusPercent, AppTheme.teal),
      (restPercent, AppTheme.lime),
      (workoutPercent, AppTheme.coral),
      (sleepPercent, AppTheme.electricViolet),
    ];

    for (final (percent, color) in segments) {
      if (percent > 0) {
        final sweepAngle = 2 * pi * percent;
        final paint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
          currentAngle,
          sweepAngle,
          false,
          paint,
        );

        currentAngle += sweepAngle;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityRingPainter oldDelegate) {
    return oldDelegate.focusPercent != focusPercent ||
        oldDelegate.restPercent != restPercent ||
        oldDelegate.workoutPercent != workoutPercent ||
        oldDelegate.sleepPercent != sleepPercent;
  }
}

class _WeeklyHighlightCard extends StatelessWidget {
  const _WeeklyHighlightCard({required this.highlight});

  final WeeklyHighlight highlight;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final formatter = DateFormat.yMMMd(localeTag);
    final dateLabel = formatter.format(highlight.date.toLocal());
    final body = l10n.tr('stats_highlight_body', {
      'date': dateLabel,
      'minutes': '${highlight.focusMinutes}',
    });

    return ScaleInAnimation(
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        borderRadius: 20,
        gradient: LinearGradient(
          colors: [
            AppTheme.lime.withValues(alpha: isDark ? 0.18 : 0.12),
            AppTheme.lime.withValues(alpha: isDark ? 0.08 : 0.05),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.lime, AppTheme.limeLight],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.lime.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tr('stats_highlight_title'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHighlightCard extends StatelessWidget {
  const _EmptyHighlightCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tr('stats_highlight_title'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(l10n.tr('stats_highlight_empty')),
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
      return FadeInAnimation(
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          borderRadius: 20,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.eucalyptus.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.insights_outlined,
                  size: 32,
                  color: AppTheme.eucalyptus,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.tr('stats_trend_empty_title'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.tr('stats_trend_empty_body'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    final showTable = _showTable;

    return FadeInAnimation(
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _trendTitle(widget.bucket, l10n),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  _TrendAccessibilityToggle(
                    showTable: showTable,
                    onToggle: () => setState(() => _showTable = !showTable),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            if (showTable)
              _TrendDataTable(entries: entries, bucket: widget.bucket)
            else
              ...entries.reversed.map((entry) {
                return Semantics(
                  label: l10n.tr('stats_trend_row_semantics', {
                    'label': _labelForEntry(widget.bucket, entry.range, l10n),
                    'value': _formatMinutes(entry.totals.totalMinutes, l10n),
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _labelForEntry(widget.bucket, entry.range, l10n),
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _formatMinutes(entry.totals.totalMinutes, l10n),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.eucalyptus,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Stacked bar showing activity breakdown
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            height: 12,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final totalWidth = constraints.maxWidth;
                                final total = entry.totals.totalMinutes;
                                if (total == 0) {
                                  return Container(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  );
                                }

                                return Row(
                                  children: [
                                    if (entry.totals.focusMinutes > 0)
                                      Container(
                                        width: totalWidth *
                                            (entry.totals.focusMinutes / total),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppTheme.teal,
                                              AppTheme.teal.withValues(alpha: 0.8),
                                            ],
                                          ),
                                        ),
                                      ),
                                    if (entry.totals.restMinutes > 0)
                                      Container(
                                        width: totalWidth *
                                            (entry.totals.restMinutes / total),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppTheme.lime,
                                              AppTheme.lime.withValues(alpha: 0.8),
                                            ],
                                          ),
                                        ),
                                      ),
                                    if (entry.totals.workoutMinutes > 0)
                                      Container(
                                        width: totalWidth *
                                            (entry.totals.workoutMinutes / total),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppTheme.coral,
                                              AppTheme.coral.withValues(alpha: 0.8),
                                            ],
                                          ),
                                        ),
                                      ),
                                    if (entry.totals.sleepMinutes > 0)
                                      Container(
                                        width: totalWidth *
                                            (entry.totals.sleepMinutes / total),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppTheme.electricViolet,
                                              AppTheme.electricViolet
                                                  .withValues(alpha: 0.8),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
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
  const _Metric(this.label, this.minutes, [this.color]);
  final String label;
  final int minutes;
  final Color? color;
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.metric, this.dense = false});
  final _Metric metric;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final color = metric.color ?? theme.colorScheme.primary;

    return Container(
      padding: dense
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '${metric.label} ${_formatMinutes(metric.minutes, l10n)}',
            style:
                (dense ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)
                    ?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
          ),
        ],
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
