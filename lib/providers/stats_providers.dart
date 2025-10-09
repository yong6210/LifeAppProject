import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/models/daily_summary_local.dart';
import 'package:life_app/providers/db_provider.dart';
import 'package:life_app/providers/settings_providers.dart';
import 'package:life_app/repositories/daily_summary_repository.dart';
import 'package:life_app/utils/date_range.dart';

class SummaryTotals {
  SummaryTotals({
    required this.focusMinutes,
    required this.restMinutes,
    required this.workoutMinutes,
    required this.sleepMinutes,
  });

  final int focusMinutes;
  final int restMinutes;
  final int workoutMinutes;
  final int sleepMinutes;

  int get totalMinutes =>
      focusMinutes + restMinutes + workoutMinutes + sleepMinutes;
}

class WeeklyHighlight {
  WeeklyHighlight({required this.date, required this.focusMinutes});

  final DateTime date;
  final int focusMinutes;
}

Future<DailySummaryRepository> _summaryRepo(Ref ref) async {
  final isar = await ref.watch(isarProvider.future);
  return DailySummaryRepository(isar);
}

SummaryTotals _totalsFromSummaries(Iterable<DailySummaryLocal> summaries) {
  int focus = 0, rest = 0, workout = 0, sleep = 0;
  for (final s in summaries) {
    focus += s.focusMinutes;
    rest += s.restMinutes;
    workout += s.workoutMinutes;
    sleep += s.sleepMinutes;
  }
  return SummaryTotals(
    focusMinutes: focus,
    restMinutes: rest,
    workoutMinutes: workout,
    sleepMinutes: sleep,
  );
}

Future<List<DailySummaryLocal>> _fetchSummaries(
  DailySummaryRepository repo,
  DateRange range,
) {
  return repo.fetchBetween(range.start, range.end);
}

final summaryTotalsProvider = FutureProvider.family<SummaryTotals, DateRange>((
  ref,
  range,
) async {
  final repo = await _summaryRepo(ref);
  final summaries = await _fetchSummaries(repo, range);
  return _totalsFromSummaries(summaries);
});

final dailyTotalsProvider = FutureProvider<SummaryTotals>((ref) async {
  final range = todayRange();
  return ref.watch(summaryTotalsProvider(range).future);
});

final weeklyTotalsProvider = FutureProvider<SummaryTotals>((ref) async {
  final repo = await _summaryRepo(ref);
  final range = thisWeekRange();
  final summaries = await _fetchSummaries(repo, range);
  return _totalsFromSummaries(summaries);
});

final monthlyTotalsProvider = FutureProvider<SummaryTotals>((ref) async {
  final repo = await _summaryRepo(ref);
  final range = thisMonthRange();
  final summaries = await _fetchSummaries(repo, range);
  return _totalsFromSummaries(summaries);
});

final streakCountProvider = FutureProvider<int>((ref) async {
  final repo = await _summaryRepo(ref);
  final settings = await ref.watch(settingsFutureProvider.future);
  final today = todayRange().start;

  int streak = 0;
  DateTime cursor = today;
  while (true) {
    final summary = await repo.get(cursor, settings.deviceId);
    if (summary == null || summary.totalMinutes == 0) {
      break;
    }
    streak += 1;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
});

extension on DailySummaryLocal {
  int get totalMinutes =>
      focusMinutes + restMinutes + workoutMinutes + sleepMinutes;
}

enum StatsTrendBucket { daily, weekly, monthly }

class StatsTrendRequest {
  const StatsTrendRequest({required this.bucket, required this.count})
    : assert(count > 0, 'count must be greater than zero');

  final StatsTrendBucket bucket;
  final int count;
}

class StatsTrendEntry {
  StatsTrendEntry({required this.range, required this.totals});

  final DateRange range;
  final SummaryTotals totals;

  DateTime get start => range.start;
  DateTime get end => range.end;
}

final statsTrendProvider =
    FutureProvider.family<List<StatsTrendEntry>, StatsTrendRequest>((
      ref,
      request,
    ) async {
      final repo = await _summaryRepo(ref);
      final ranges = switch (request.bucket) {
        StatsTrendBucket.daily => dailyRanges(request.count),
        StatsTrendBucket.weekly => weeklyRanges(request.count),
        StatsTrendBucket.monthly => monthlyRanges(request.count),
      };
      final earliest = ranges.first.start;
      final latest = ranges.last.end;
      final summaries = await _fetchSummaries(
        repo,
        DateRange(earliest, latest),
      );

      final buckets = <StatsTrendEntry>[];
      for (final range in ranges) {
        final bucketSummaries = summaries.where((s) {
          final date = DateTime(s.date.year, s.date.month, s.date.day);
          return !date.isBefore(range.start) && date.isBefore(range.end);
        });
        buckets.add(
          StatsTrendEntry(
            range: range,
            totals: _totalsFromSummaries(bucketSummaries),
          ),
        );
      }

      return buckets;
    });

final weeklyHighlightProvider = FutureProvider<WeeklyHighlight?>((ref) async {
  final repo = await _summaryRepo(ref);
  final settings = await ref.watch(settingsFutureProvider.future);
  final todayStart = todayRange().start;
  final start = todayStart.subtract(const Duration(days: 6));
  final endExclusive = todayStart.add(const Duration(days: 1));
  final summaries = await repo.fetchBetween(start, endExclusive);
  final deviceSummaries = summaries.where(
    (summary) => summary.deviceId == settings.deviceId,
  );
  if (deviceSummaries.isEmpty) {
    return null;
  }
  DailySummaryLocal? best;
  for (final summary in deviceSummaries) {
    if (summary.focusMinutes <= 0) continue;
    if (best == null || summary.focusMinutes > best!.focusMinutes) {
      best = summary;
    }
  }
  if (best == null) {
    return null;
  }
  return WeeklyHighlight(date: best!.date, focusMinutes: best!.focusMinutes);
});
