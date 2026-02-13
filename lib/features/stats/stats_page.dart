import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:life_app/features/stats/cross_domain_dashboard_page.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/providers/stats_providers.dart';
import 'package:life_app/services/analytics/analytics_service.dart';
import 'package:life_app/design/ui_tokens.dart';
import 'package:life_app/widgets/app_state_widgets.dart';

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  StatsTrendBucket _bucket = StatsTrendBucket.daily;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final sidePadding = math.max(16.0, (screenWidth - 620) / 2);
    final topPadding = screenWidth < 380 ? 10.0 : 14.0;
    final canPop = Navigator.of(context).canPop();

    final totalsAsync = ref.watch(_totalsProviderFor(_bucket));
    final trendAsync = ref.watch(
      statsTrendProvider(
        StatsTrendRequest(bucket: _bucket, count: _countFor(_bucket)),
      ),
    );
    final lifetimeAsync = ref.watch(lifetimeTotalsProvider);
    final levelAsync = ref.watch(userLevelProvider);
    final highlightAsync = _bucket == StatsTrendBucket.daily
        ? ref.watch(weeklyHighlightProvider)
        : null;

    return Scaffold(
      backgroundColor: _StatsPalette.canvas,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFBF7),
              Color(0xFFF7F1E8),
              Color(0xFFF3F4FF),
            ],
          ),
        ),
        child: Stack(
          children: [
            const _StatsBackdrop(),
            SafeArea(
              child: RefreshIndicator(
                color: _StatsPalette.focus,
                onRefresh: () async {
                  _refreshAll();
                  unawaited(
                    AnalyticsService.logEvent('stats_pull_refresh', {
                      'bucket': _bucket.name,
                    }),
                  );
                },
                child: Scrollbar(
                  child: ListView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      sidePadding,
                      topPadding,
                      sidePadding,
                      118,
                    ),
                    children: [
                      _StatsHeader(
                        l10n: l10n,
                        canPop: canPop,
                        onBack: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(height: 14),
                      _BucketSelector(
                        current: _bucket,
                        onChanged: (next) {
                          if (next == _bucket) return;
                          unawaited(
                            AnalyticsService.logEvent('stats_bucket_change', {
                              'from': _bucket.name,
                              'to': next.name,
                            }),
                          );
                          setState(() => _bucket = next);
                        },
                      ),
                      const SizedBox(height: 14),
                      totalsAsync.when(
                        data: (totals) {
                          final lifetimeMinutes = lifetimeAsync.maybeWhen(
                            data: (value) => value.totalMinutes,
                            orElse: () => null,
                          );
                          final level = levelAsync.maybeWhen(
                            data: (value) => value,
                            orElse: () => null,
                          );

                          return _StatsHeroCard(
                            l10n: l10n,
                            bucket: _bucket,
                            totals: totals,
                            lifetimeMinutes: lifetimeMinutes,
                            level: level,
                          );
                        },
                        loading: () => _LoadingCard(
                          title: l10n.tr('stats_loading_totals'),
                        ),
                        error: (error, _) => _ErrorCard(
                          title: l10n.tr('stats_error_totals_title'),
                          message: '$error',
                          onRetry: _refreshTotals,
                        ),
                      ),
                      if (highlightAsync != null) ...[
                        const SizedBox(height: 14),
                        highlightAsync.when(
                          data: (highlight) => _WeeklyFocusHighlightCard(
                            highlight: highlight,
                          ),
                          loading: () => _LoadingCard(
                            title: l10n.tr('stats_highlight_title'),
                          ),
                          error: (error, _) => _ErrorCard(
                            title: l10n.tr('stats_highlight_title'),
                            message: '$error',
                            onRetry: _refreshHighlight,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      trendAsync.when(
                        data: (entries) => _TrendCard(
                          l10n: l10n,
                          bucket: _bucket,
                          entries: entries,
                        ),
                        loading: () => _LoadingCard(
                          title: l10n.tr('stats_loading_trend'),
                        ),
                        error: (error, _) => _ErrorCard(
                          title: l10n.tr('stats_error_trend_title'),
                          message: '$error',
                          onRetry: _refreshTrend,
                        ),
                      ),
                      const SizedBox(height: 14),
                      totalsAsync.when(
                        data: (totals) => _DomainBalanceCard(totals: totals),
                        loading: () => _LoadingCard(
                          title: l10n.tr('stats_loading_totals'),
                        ),
                        error: (error, _) => _ErrorCard(
                          title: l10n.tr('stats_error_totals_title'),
                          message: '$error',
                          onRetry: _refreshTotals,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _AdvancedAnalyticsCard(
                        onTap: () {
                          unawaited(
                            AnalyticsService.logEvent('stats_open_advanced', {
                              'bucket': _bucket.name,
                            }),
                          );
                          Navigator.of(context).push(
                            CrossDomainDashboardPage.route(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  FutureProvider<SummaryTotals> _totalsProviderFor(StatsTrendBucket bucket) {
    switch (bucket) {
      case StatsTrendBucket.daily:
        return dailyTotalsProvider;
      case StatsTrendBucket.weekly:
        return weeklyTotalsProvider;
      case StatsTrendBucket.monthly:
        return monthlyTotalsProvider;
    }
  }

  int _countFor(StatsTrendBucket bucket) {
    switch (bucket) {
      case StatsTrendBucket.daily:
        return 7;
      case StatsTrendBucket.weekly:
        return 5;
      case StatsTrendBucket.monthly:
        return 6;
    }
  }

  void _refreshTotals() {
    ref.invalidate(_totalsProviderFor(_bucket));
    ref.invalidate(lifetimeTotalsProvider);
    ref.invalidate(userLevelProvider);
  }

  void _refreshTrend() {
    ref.invalidate(
      statsTrendProvider(
        StatsTrendRequest(bucket: _bucket, count: _countFor(_bucket)),
      ),
    );
  }

  void _refreshHighlight() {
    if (_bucket == StatsTrendBucket.daily) {
      ref.invalidate(weeklyHighlightProvider);
    }
  }

  void _refreshAll() {
    _refreshTotals();
    _refreshTrend();
    _refreshHighlight();
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({
    required this.l10n,
    required this.canPop,
    required this.onBack,
  });

  final AppLocalizations l10n;
  final bool canPop;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (canPop)
          IconButton(
            onPressed: onBack,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.86),
              side: BorderSide(color: _StatsPalette.cardBorder),
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
        if (canPop) const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.tr('stats_appbar_title'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: _StatsPalette.ink,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.tr('stats_casual_subtitle'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _StatsPalette.inkSoft,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BucketSelector extends StatelessWidget {
  const _BucketSelector({required this.current, required this.onChanged});

  final StatsTrendBucket current;
  final ValueChanged<StatsTrendBucket> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = <(StatsTrendBucket bucket, String label)>[
      (StatsTrendBucket.daily, l10n.tr('stats_tab_daily')),
      (StatsTrendBucket.weekly, l10n.tr('stats_tab_weekly')),
      (StatsTrendBucket.monthly, l10n.tr('stats_tab_monthly')),
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _StatsPalette.cardBorder),
      ),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: _BucketButton(
                label: item.$2,
                isSelected: item.$1 == current,
                onTap: () => onChanged(item.$1),
              ),
            ),
        ],
      ),
    );
  }
}

class _BucketButton extends StatelessWidget {
  const _BucketButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: isSelected
            ? _StatsPalette.focus.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isSelected
                        ? _StatsPalette.focus
                        : _StatsPalette.inkSoft,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsHeroCard extends StatelessWidget {
  const _StatsHeroCard({
    required this.l10n,
    required this.bucket,
    required this.totals,
    required this.lifetimeMinutes,
    required this.level,
  });

  final AppLocalizations l10n;
  final StatsTrendBucket bucket;
  final SummaryTotals totals;
  final int? lifetimeMinutes;
  final int? level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F2536), Color(0xFF2C3957)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.tr('stats_totals_title'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _bucketSummaryLabel(l10n, bucket),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.76),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _formatMinutesCompact(totals.totalMinutes),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroPill(
                color: _StatsPalette.focus,
                label: l10n.tr('session_type_focus'),
                value: _formatMinutesCompact(totals.focusMinutes),
              ),
              _HeroPill(
                color: _StatsPalette.workout,
                label: l10n.tr('session_type_workout'),
                value: _formatMinutesCompact(totals.workoutMinutes),
              ),
              _HeroPill(
                color: _StatsPalette.sleep,
                label: l10n.tr('session_type_sleep'),
                value: _formatMinutesCompact(totals.sleepMinutes),
              ),
              _HeroPill(
                color: _StatsPalette.rest,
                label: l10n.tr('session_type_rest'),
                value: _formatMinutesCompact(totals.restMinutes),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HeroMeta(
                  title: l10n.tr('stats_casual_lifetime'),
                  value: lifetimeMinutes == null
                      ? '...'
                      : _formatMinutesCompact(lifetimeMinutes!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMeta(
                  title: l10n.tr('stats_casual_level'),
                  value: level == null ? '...' : 'Lv.$level',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _bucketSummaryLabel(AppLocalizations l10n, StatsTrendBucket bucket) {
    switch (bucket) {
      case StatsTrendBucket.daily:
        return l10n.tr('stats_tab_daily');
      case StatsTrendBucket.weekly:
        return l10n.tr('stats_tab_weekly');
      case StatsTrendBucket.monthly:
        return l10n.tr('stats_tab_monthly');
    }
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            '$label $value',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _HeroMeta extends StatelessWidget {
  const _HeroMeta({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.74),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyFocusHighlightCard extends StatelessWidget {
  const _WeeklyFocusHighlightCard({required this.highlight});

  final WeeklyHighlight? highlight;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _StatsPalette.cardBorder),
      ),
      child: highlight == null
          ? Text(
              l10n.tr('stats_casual_best_focus_empty'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _StatsPalette.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
            )
          : Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _StatsPalette.focus.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emoji_events_outlined,
                    color: _StatsPalette.focus,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.tr('stats_casual_best_focus_title'),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: _StatsPalette.ink,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat.MMMd(l10n.locale.toLanguageTag()).format(
                          highlight!.date,
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _StatsPalette.inkSoft,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatMinutesCompact(highlight!.focusMinutes),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: _StatsPalette.focus,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.l10n,
    required this.bucket,
    required this.entries,
  });

  final AppLocalizations l10n;
  final StatsTrendBucket bucket;
  final List<StatsTrendEntry> entries;

  @override
  Widget build(BuildContext context) {
    final maxMinutes = entries.fold<int>(
      0,
      (prev, item) => math.max(prev, item.totals.totalMinutes),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _StatsPalette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tr('stats_casual_trend_title'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _StatsPalette.ink,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            Text(
              l10n.tr('stats_casual_no_trend'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _StatsPalette.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          for (var i = entries.length - 1; i >= 0; i--)
            _TrendRow(
              bucket: bucket,
              entry: entries[i],
              maxMinutes: maxMinutes,
              isLast: i == 0,
            ),
        ],
      ),
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({
    required this.bucket,
    required this.entry,
    required this.maxMinutes,
    required this.isLast,
  });

  final StatsTrendBucket bucket;
  final StatsTrendEntry entry;
  final int maxMinutes;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ratio =
        maxMinutes <= 0 ? 0.0 : entry.totals.totalMinutes / maxMinutes;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              _periodLabel(bucket, entry, l10n.locale.toLanguageTag()),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: _StatsPalette.inkSoft,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 9,
                backgroundColor: _StatsPalette.focus.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  _StatsPalette.focus,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 58,
            child: Text(
              _formatMinutesCompact(entry.totals.totalMinutes),
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: _StatsPalette.ink,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _periodLabel(
    StatsTrendBucket bucket,
    StatsTrendEntry entry,
    String locale,
  ) {
    switch (bucket) {
      case StatsTrendBucket.daily:
        return DateFormat.Md(locale).format(entry.start);
      case StatsTrendBucket.weekly:
        final end = entry.end.subtract(const Duration(days: 1));
        return '${DateFormat.Md(locale).format(entry.start)}-${DateFormat.Md(locale).format(end)}';
      case StatsTrendBucket.monthly:
        return DateFormat.yMMM(locale).format(entry.start);
    }
  }
}

class _DomainBalanceCard extends StatelessWidget {
  const _DomainBalanceCard({required this.totals});

  final SummaryTotals totals;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final total = totals.totalMinutes;

    final metrics = [
      _DomainMetric(
        label: l10n.tr('session_type_focus'),
        minutes: totals.focusMinutes,
        color: _StatsPalette.focus,
      ),
      _DomainMetric(
        label: l10n.tr('session_type_workout'),
        minutes: totals.workoutMinutes,
        color: _StatsPalette.workout,
      ),
      _DomainMetric(
        label: l10n.tr('session_type_sleep'),
        minutes: totals.sleepMinutes,
        color: _StatsPalette.sleep,
      ),
      _DomainMetric(
        label: l10n.tr('session_type_rest'),
        minutes: totals.restMinutes,
        color: _StatsPalette.rest,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _StatsPalette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tr('stats_casual_share_label'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _StatsPalette.ink,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < metrics.length; i++)
            _DomainMetricRow(
              metric: metrics[i],
              total: total,
              isLast: i == metrics.length - 1,
            ),
        ],
      ),
    );
  }
}

class _DomainMetricRow extends StatelessWidget {
  const _DomainMetricRow({
    required this.metric,
    required this.total,
    required this.isLast,
  });

  final _DomainMetric metric;
  final int total;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ratio = total <= 0 ? 0.0 : metric.minutes / total;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: Text(
              metric.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: _StatsPalette.inkSoft,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: metric.color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(metric.color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: Text(
              _formatMinutesCompact(metric.minutes),
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: _StatsPalette.ink,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvancedAnalyticsCard extends StatelessWidget {
  const _AdvancedAnalyticsCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _StatsPalette.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _StatsPalette.deep.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.query_stats_rounded,
                  color: _StatsPalette.deep,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.tr('stats_casual_open_advanced'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: _StatsPalette.ink,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _StatsPalette.inkSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppLoadingState(
      title: title,
      compact: true,
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppErrorState(
      title: title,
      message: message,
      retryLabel: context.l10n.tr('common_retry'),
      onRetry: onRetry,
    );
  }
}

class _StatsBackdrop extends StatelessWidget {
  const _StatsBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -90,
            child: _shape(
              size: 240,
              color: const Color(0xFFFFDBBF).withValues(alpha: 0.27),
            ),
          ),
          Positioned(
            top: 90,
            right: -80,
            child: _shape(
              size: 220,
              color: const Color(0xFFC3D7FF).withValues(alpha: 0.23),
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

class _DomainMetric {
  const _DomainMetric({
    required this.label,
    required this.minutes,
    required this.color,
  });

  final String label;
  final int minutes;
  final Color color;
}

class _StatsPalette {
  static const canvas = Color(0xFFFFFBF7);
  static const ink = Color(0xFF1F2633);
  static const inkSoft = Color(0xFF657287);
  static const cardBorder = UiBorders.warmCard;

  static const focus = Color(0xFF2F80ED);
  static const workout = Color(0xFFF2994A);
  static const sleep = Color(0xFF6C63FF);
  static const rest = Color(0xFF22B8B0);
  static const deep = Color(0xFF4656D8);
}

String _formatMinutesCompact(int minutes) {
  if (minutes <= 0) return '0m';
  final hour = minutes ~/ 60;
  final minute = minutes % 60;
  if (hour == 0) return '${minute}m';
  if (minute == 0) return '${hour}h';
  return '${hour}h ${minute}m';
}
