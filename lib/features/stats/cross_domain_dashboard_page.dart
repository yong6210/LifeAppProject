import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/providers/cross_domain_analytics_provider.dart';
import 'package:life_app/services/analytics/cross_domain_analytics_service.dart';
import 'package:life_app/services/analytics/cross_domain_exporter.dart';

class CrossDomainDashboardPage extends ConsumerStatefulWidget {
  const CrossDomainDashboardPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const CrossDomainDashboardPage(),
    );
  }

  @override
  ConsumerState<CrossDomainDashboardPage> createState() =>
      _CrossDomainDashboardPageState();
}

class _CrossDomainDashboardPageState
    extends ConsumerState<CrossDomainDashboardPage> {
  final _exporter = CrossDomainAnalyticsExporter();
  CrossDomainRange _range = CrossDomainRange.last7Days;

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(crossDomainAnalyticsProvider(_range));
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('analytics_dashboard_title')),
        actions: [
          analyticsAsync.when(
            data: (analytics) => IconButton(
              tooltip: l10n.tr('analytics_dashboard_export'),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () => _exportAnalytics(analytics),
            ),
            loading: () => IconButton(
              onPressed: null,
              tooltip: l10n.tr('analytics_dashboard_export'),
              icon: const Icon(Icons.picture_as_pdf_outlined),
            ),
            error: (error, stackTrace) => IconButton(
              onPressed: null,
              tooltip: l10n.tr('analytics_dashboard_export'),
              icon: const Icon(Icons.picture_as_pdf_outlined),
            ),
          ),
        ],
      ),
      body: analyticsAsync.when(
        data: (analytics) => _DashboardBody(
          range: _range,
          onRangeChanged: _onRangeChanged,
          analytics: analytics,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(message: '$error'),
      ),
    );
  }

  void _onRangeChanged(CrossDomainRange value) {
    setState(() => _range = value);
  }

  Future<void> _exportAnalytics(CrossDomainAnalytics analytics) async {
    final l10n = context.l10n;
    try {
      final path = await _exporter.exportToPdf(
        analytics: analytics,
        range: _range,
        l10n: l10n,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.tr('analytics_dashboard_export_success', {'path': path}),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.tr('analytics_dashboard_export_error', {'error': '$error'}),
          ),
        ),
      );
    }
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.range,
    required this.onRangeChanged,
    required this.analytics,
  });

  final CrossDomainRange range;
  final ValueChanged<CrossDomainRange> onRangeChanged;
  final CrossDomainAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    if (analytics.points.isEmpty) {
      return _EmptyState(
        range: range,
        onRangeChanged: onRangeChanged,
      );
    }

    final dateFormat = DateFormat.yMMMd(l10n.locale.toLanguageTag());
    final lastUpdated = analytics.points.last.date;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _RangeSelector(range: range, onChanged: onRangeChanged),
        const SizedBox(height: 16),
        Text(
          l10n.tr('analytics_dashboard_last_updated', {
            'date': dateFormat.format(lastUpdated),
          }),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        _SummaryGrid(analytics: analytics),
        const SizedBox(height: 16),
        _CorrelationRow(analytics: analytics),
        const SizedBox(height: 16),
        _HighlightsRow(analytics: analytics),
        const SizedBox(height: 16),
        _MetricsChart(points: analytics.points),
        const SizedBox(height: 16),
        _LegendBar(),
        const SizedBox(height: 12),
        _DataTable(points: analytics.points),
      ],
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.range, required this.onChanged});

  final CrossDomainRange range;
  final ValueChanged<CrossDomainRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.tr('analytics_dashboard_range_label'),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SegmentedButton<CrossDomainRange>(
          segments: [
            ButtonSegment(
              value: CrossDomainRange.last7Days,
              label: Text(l10n.tr('analytics_dashboard_range_7')),
            ),
            ButtonSegment(
              value: CrossDomainRange.last14Days,
              label: Text(l10n.tr('analytics_dashboard_range_14')),
            ),
            ButtonSegment(
              value: CrossDomainRange.last30Days,
              label: Text(l10n.tr('analytics_dashboard_range_30')),
            ),
          ],
          selected: <CrossDomainRange>{range},
          onSelectionChanged: (selection) {
            if (selection.isEmpty) return;
            onChanged(selection.first);
          },
        ),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.analytics});

  final CrossDomainAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final averageMood = analytics.averageMoodScore != null
        ? NumberFormat.percentPattern(l10n.locale.toLanguageTag())
            .format(analytics.averageMoodScore)
        : '—';
    final sleepDebtHours =
        (analytics.totalSleepDebtMinutes / 60).clamp(0, double.infinity);

    final cards = [
      _SummaryCard(
        label: l10n.tr('analytics_dashboard_avg_focus'),
        value: l10n.tr('analytics_dashboard_summary_minutes', {
          'minutes': analytics.averageFocusMinutes.toStringAsFixed(0),
        }),
      ),
      _SummaryCard(
        label: l10n.tr('analytics_dashboard_avg_sleep'),
        value: l10n.tr('analytics_dashboard_summary_minutes', {
          'minutes': analytics.averageSleepMinutes.toStringAsFixed(0),
        }),
      ),
      _SummaryCard(
        label: l10n.tr('analytics_dashboard_avg_mood'),
        value: averageMood,
      ),
      _SummaryCard(
        label: l10n.tr('analytics_dashboard_sleep_debt'),
        value: l10n.tr(
          'analytics_dashboard_sleep_debt_hours',
          {'hours': sleepDebtHours.toStringAsFixed(1)},
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                Expanded(child: cards[i]),
                if (i != cards.length - 1) const SizedBox(width: 12),
              ],
            ],
          );
        }

        return Column(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              cards[i],
              if (i != cards.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CorrelationRow extends StatelessWidget {
  const _CorrelationRow({required this.analytics});

  final CrossDomainAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cards = [
      _CorrelationCard(
        label: l10n.tr('analytics_dashboard_correlation_focus_sleep'),
        value: analytics.focusSleepCorrelation,
      ),
      _CorrelationCard(
        label: l10n.tr('analytics_dashboard_correlation_sleep_mood'),
        value: analytics.sleepMoodCorrelation,
      ),
      _CorrelationCard(
        label: l10n.tr('analytics_dashboard_correlation_focus_mood'),
        value: analytics.focusMoodCorrelation,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        if (isWide) {
          return Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                Expanded(child: cards[i]),
                if (i != cards.length - 1) const SizedBox(width: 12),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              cards[i],
              if (i != cards.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _CorrelationCard extends StatelessWidget {
  const _CorrelationCard({required this.label, required this.value});

  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final descriptor = _describeCorrelation(value, l10n);
    final formatted = value == null ? '—' : value!.toStringAsFixed(2);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(
              formatted,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              descriptor,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _describeCorrelation(double? value, AppLocalizations l10n) {
    if (value == null) {
      return l10n.tr('analytics_dashboard_correlation_neutral');
    }
    if (value >= 0.35) {
      return l10n.tr('analytics_dashboard_correlation_positive');
    }
    if (value <= -0.35) {
      return l10n.tr('analytics_dashboard_correlation_negative');
    }
    return l10n.tr('analytics_dashboard_correlation_neutral');
  }
}

class _HighlightsRow extends StatelessWidget {
  const _HighlightsRow({required this.analytics});

  final CrossDomainAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final dateFormat = DateFormat.MMMd(l10n.locale.toLanguageTag());

    String formatOrDash(DateTime? date) {
      if (date == null) {
        return l10n.tr('analytics_dashboard_highlight_missing');
      }
      return dateFormat.format(date);
    }

    final cards = [
      _HighlightCard(
        icon: Icons.bolt,
        title: l10n.tr('analytics_dashboard_highlight_focus'),
        value: formatOrDash(analytics.highlights.bestFocusDate),
        color: theme.colorScheme.primary,
      ),
      _HighlightCard(
        icon: Icons.nightlight_round,
        title: l10n.tr('analytics_dashboard_highlight_sleep'),
        value: formatOrDash(analytics.highlights.bestSleepDate),
        color: theme.colorScheme.secondary,
      ),
      _HighlightCard(
        icon: Icons.sentiment_dissatisfied_outlined,
        title: l10n.tr('analytics_dashboard_highlight_mood'),
        value: formatOrDash(analytics.highlights.lowMoodDate),
        color: theme.colorScheme.tertiary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        if (isWide) {
          return Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                Expanded(child: cards[i]),
                if (i != cards.length - 1) const SizedBox(width: 12),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              cards[i],
              if (i != cards.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
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

class _MetricsChart extends StatelessWidget {
  const _MetricsChart({required this.points});

  final List<CrossDomainDataPoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 220,
          child: CustomPaint(
            painter: _MultiMetricChartPainter(
              points: points,
              focusColor: theme.colorScheme.primary,
              sleepColor: theme.colorScheme.secondary,
              moodColor: theme.colorScheme.tertiary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MultiMetricChartPainter extends CustomPainter {
  _MultiMetricChartPainter({
    required this.points,
    required this.focusColor,
    required this.sleepColor,
    required this.moodColor,
  });

  final List<CrossDomainDataPoint> points;
  final Color focusColor;
  final Color sleepColor;
  final Color moodColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }
    final focusMax = points.fold<int>(
      0,
      (maxValue, point) => point.focusMinutes > maxValue
          ? point.focusMinutes
          : maxValue,
    );
    final sleepMax = points.fold<int>(
      0,
      (maxValue, point) => point.sleepMinutes > maxValue
          ? point.sleepMinutes
          : maxValue,
    );
    final moodMax = points.fold<double>(
      0,
      (maxValue, point) => point.moodScore != null && point.moodScore! > maxValue
          ? point.moodScore!
          : maxValue,
    );

    final focusScale = focusMax == 0 ? 1 : focusMax.toDouble();
    final sleepScale = sleepMax == 0 ? 1 : sleepMax.toDouble();
    final moodScale = moodMax == 0 ? 1 : moodMax;

    final dxStep = points.length == 1
        ? 0.0
        : size.width / (points.length - 1);

    final focusPath = Path();
    final sleepPath = Path();
    final moodPath = Path();

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final x = dxStep * i;
      final focusRatio = (point.focusMinutes / focusScale).clamp(0.0, 1.0);
      final sleepRatio = (point.sleepMinutes / sleepScale).clamp(0.0, 1.0);
      final moodScore = point.moodScore ?? 0.5;
      final moodRatio = (moodScore / moodScale).clamp(0.0, 1.0);

      final focusY = size.height - (focusRatio * size.height);
      final sleepY = size.height - (sleepRatio * size.height);
      final moodY = size.height - (moodRatio * size.height);

      if (i == 0) {
        focusPath.moveTo(x, focusY);
        sleepPath.moveTo(x, sleepY);
        moodPath.moveTo(x, moodY);
      } else {
        focusPath.lineTo(x, focusY);
        sleepPath.lineTo(x, sleepY);
        moodPath.lineTo(x, moodY);
      }
    }

    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1;
    for (var i = 1; i <= 4; i++) {
      final y = size.height * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final focusPaint = Paint()
      ..color = focusColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final sleepPaint = Paint()
      ..color = sleepColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final moodPaint = Paint()
      ..color = moodColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    if (points.length == 1) {
      final point = points.first;
      final focusRatio = (point.focusMinutes / focusScale).clamp(0.0, 1.0);
      final sleepRatio = (point.sleepMinutes / sleepScale).clamp(0.0, 1.0);
      final moodRatio = ((point.moodScore ?? 0.5) / moodScale).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(0, size.height - (focusRatio * size.height)),
        4,
        focusPaint..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(0, size.height - (sleepRatio * size.height)),
        4,
        sleepPaint..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(0, size.height - (moodRatio * size.height)),
        4,
        moodPaint..style = PaintingStyle.fill,
      );
    } else {
      canvas.drawPath(focusPath, focusPaint);
      canvas.drawPath(sleepPath, sleepPaint);
      canvas.drawPath(moodPath, moodPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MultiMetricChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.focusColor != focusColor ||
        oldDelegate.sleepColor != sleepColor ||
        oldDelegate.moodColor != moodColor;
  }
}

class _LegendBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _LegendChip(
          color: theme.colorScheme.primary,
          label: l10n.tr('analytics_dashboard_chart_label_focus'),
        ),
        _LegendChip(
          color: theme.colorScheme.secondary,
          label: l10n.tr('analytics_dashboard_chart_label_sleep'),
        ),
        _LegendChip(
          color: theme.colorScheme.tertiary,
          label: l10n.tr('analytics_dashboard_chart_label_mood'),
        ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(backgroundColor: color, radius: 6),
      label: Text(label),
    );
  }
}

class _DataTable extends StatelessWidget {
  const _DataTable({required this.points});

  final List<CrossDomainDataPoint> points;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dateFormat = DateFormat.MMMd(l10n.locale.toLanguageTag());
    final moodFormat = NumberFormat.percentPattern(l10n.locale.toLanguageTag());

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(
            label: Text(l10n.tr('analytics_dashboard_table_header_date')),
          ),
          DataColumn(
            label: Text(l10n.tr('analytics_dashboard_table_header_focus')),
          ),
          DataColumn(
            label: Text(l10n.tr('analytics_dashboard_table_header_sleep')),
          ),
          DataColumn(
            label: Text(l10n.tr('analytics_dashboard_table_header_mood')),
          ),
          DataColumn(
            label: Text(l10n.tr('analytics_dashboard_table_header_journal_sleep')),
          ),
        ],
        rows: points
            .map(
              (point) => DataRow(
                cells: [
                  DataCell(Text(dateFormat.format(point.date))),
                  DataCell(Text('${point.focusMinutes}')),
                  DataCell(Text('${point.sleepMinutes}')),
                  DataCell(
                    Text(
                      point.moodScore == null
                          ? '—'
                          : moodFormat.format(point.moodScore),
                    ),
                  ),
                  DataCell(
                    Text(
                      point.journalSleepHours == null
                          ? '—'
                          : point.journalSleepHours!.toStringAsFixed(1),
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.range, required this.onRangeChanged});

  final CrossDomainRange range;
  final ValueChanged<CrossDomainRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RangeSelector(range: range, onChanged: onRangeChanged),
          const SizedBox(height: 32),
          Expanded(
            child: Center(
              child: Text(
                l10n.tr('analytics_dashboard_empty'),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
