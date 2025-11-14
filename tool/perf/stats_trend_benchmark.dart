import 'dart:io';
import 'dart:math';

import 'package:life_app/models/daily_summary_local.dart';
import 'package:life_app/providers/stats_providers.dart';
import 'package:life_app/utils/date_range.dart';

/// Simple benchmark helper to measure trend aggregation performance.
///
/// Run with:
/// ```
/// dart run tool/perf/stats_trend_benchmark.dart
/// ```
void main() {
  final now = DateTime.now();
  final random = Random(42);
  final samples = <DailySummaryLocal>[];
  for (var i = 0; i < 365; i++) {
    final summary = DailySummaryLocal()
      ..date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i))
      ..deviceId = 'device'
      ..focusMinutes = random.nextInt(180)
      ..restMinutes = random.nextInt(90)
      ..workoutMinutes = random.nextInt(60)
      ..sleepMinutes = 360 + random.nextInt(120)
      ..updatedAt = DateTime.now().toUtc();
    samples.add(summary);
  }

  final weeklyRanges = weeklyRangesFromToday(52);
  final watch = Stopwatch()..start();
  final entries = buildTrendEntries(weeklyRanges, samples);
  watch.stop();
  stdout.writeln(
    'Computed ${entries.length} weekly trend buckets from '
    '${samples.length} summaries in ${watch.elapsedMilliseconds} ms',
  );
}

List<StatsTrendEntry> buildTrendEntries(
  Iterable<DateRange> ranges,
  Iterable<DailySummaryLocal> summaries,
) {
  final entries = <StatsTrendEntry>[];
  for (final range in ranges) {
    var focus = 0;
    var rest = 0;
    var workout = 0;
    var sleep = 0;
    for (final summary in summaries) {
      final date = DateTime(
        summary.date.year,
        summary.date.month,
        summary.date.day,
      );
      if (date.isBefore(range.start) || !date.isBefore(range.end)) {
        continue;
      }
      focus += summary.focusMinutes;
      rest += summary.restMinutes;
      workout += summary.workoutMinutes;
      sleep += summary.sleepMinutes;
    }
    entries.add(
      StatsTrendEntry(
        range: range,
        totals: SummaryTotals(
          focusMinutes: focus,
          restMinutes: rest,
          workoutMinutes: workout,
          sleepMinutes: sleep,
        ),
      ),
    );
  }
  return entries;
}

List<DateRange> weeklyRangesFromToday(int count) {
  final today = todayRange().start;
  final ranges = <DateRange>[];
  var cursorEnd = today.add(const Duration(days: 1));
  for (var i = 0; i < count; i++) {
    final cursorStart = cursorEnd.subtract(const Duration(days: 7));
    ranges.add(DateRange(cursorStart, cursorEnd));
    cursorEnd = cursorStart;
  }
  return ranges.reversed.toList();
}
