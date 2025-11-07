import 'dart:math';

import 'package:life_app/features/journal/journal_entry.dart';
import 'package:life_app/models/daily_summary_local.dart';

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

double _averageDouble(Iterable<double> values) {
  final list = values.toList(growable: false);
  if (list.isEmpty) return 0;
  final sum = list.reduce((a, b) => a + b);
  return sum / list.length;
}

double? _pearsonCorrelation(List<double> xs, List<double> ys) {
  final length = min(xs.length, ys.length);
  if (length < 2) {
    return null;
  }
  var sumX = 0.0;
  var sumY = 0.0;
  var sumXY = 0.0;
  var sumX2 = 0.0;
  var sumY2 = 0.0;

  for (var i = 0; i < length; i++) {
    final x = xs[i];
    final y = ys[i];
    sumX += x;
    sumY += y;
    sumXY += x * y;
    sumX2 += x * x;
    sumY2 += y * y;
  }

  final numerator = (length * sumXY) - (sumX * sumY);
  final denominator = sqrt(
    ((length * sumX2) - (sumX * sumX)) * ((length * sumY2) - (sumY * sumY)),
  );
  if (denominator == 0) {
    return null;
  }
  final value = numerator / denominator;
  if (value.isNaN || value.isInfinite) {
    return null;
  }
  return value.clamp(-1.0, 1.0);
}

double? _moodScore(String? moodKeyword) {
  if (moodKeyword == null || moodKeyword.trim().isEmpty) {
    return null;
  }
  final normalized = moodKeyword.trim().toLowerCase();
  const lookup = <String, double>{
    'ecstatic': 1.0,
    'great': 0.95,
    'happy': 0.9,
    'grateful': 0.88,
    'energized': 0.85,
    'motivated': 0.85,
    'calm': 0.75,
    'content': 0.7,
    'balanced': 0.65,
    'neutral': 0.5,
    'meh': 0.45,
    'tired': 0.35,
    'stressed': 0.3,
    'anxious': 0.25,
    'down': 0.25,
    'exhausted': 0.2,
    'burnt out': 0.18,
    'burned out': 0.18,
    'upset': 0.18,
    'sad': 0.15,
    'terrible': 0.1,
  };
  if (lookup.containsKey(normalized)) {
    return lookup[normalized]!;
  }
  for (final entry in lookup.entries) {
    if (normalized.contains(entry.key)) {
      return entry.value;
    }
  }
  return null;
}

double? _energyScore(String? energyLevel) {
  if (energyLevel == null || energyLevel.isEmpty) {
    return null;
  }
  switch (energyLevel.toLowerCase()) {
    case 'low':
      return 0.25;
    case 'balanced':
    case 'medium':
      return 0.65;
    case 'energetic':
    case 'high':
      return 0.9;
  }
  return null;
}

class CrossDomainDataPoint {
  const CrossDomainDataPoint({
    required this.date,
    required this.focusMinutes,
    required this.sleepMinutes,
    required this.restMinutes,
    required this.workoutMinutes,
    this.journalSleepHours,
    this.moodScore,
    this.energyScore,
  });

  final DateTime date;
  final int focusMinutes;
  final int sleepMinutes;
  final int restMinutes;
  final int workoutMinutes;
  final double? journalSleepHours;
  final double? moodScore;
  final double? energyScore;

  bool get hasJournalData =>
      journalSleepHours != null || moodScore != null || energyScore != null;
}

class CrossDomainHighlights {
  const CrossDomainHighlights({
    required this.bestFocusDate,
    required this.bestSleepDate,
    required this.lowMoodDate,
  });

  final DateTime? bestFocusDate;
  final DateTime? bestSleepDate;
  final DateTime? lowMoodDate;
}

class CrossDomainAnalytics {
  const CrossDomainAnalytics({
    required this.points,
    required this.focusSleepCorrelation,
    required this.sleepMoodCorrelation,
    required this.focusMoodCorrelation,
    required this.averageFocusMinutes,
    required this.averageSleepMinutes,
    required this.averageMoodScore,
    required this.totalSleepDebtMinutes,
    required this.highlights,
  });

  final List<CrossDomainDataPoint> points;
  final double? focusSleepCorrelation;
  final double? sleepMoodCorrelation;
  final double? focusMoodCorrelation;
  final double averageFocusMinutes;
  final double averageSleepMinutes;
  final double? averageMoodScore;
  final double totalSleepDebtMinutes;
  final CrossDomainHighlights highlights;
}

class CrossDomainAnalyticsBuilder {
  static const _sleepTargetMinutes = 7 * 60;

  static CrossDomainAnalytics build({
    required DateTime start,
    required DateTime endExclusive,
    required Iterable<DailySummaryLocal> summaries,
    required Iterable<JournalEntry> journalEntries,
  }) {
    final summaryByDate = <DateTime, DailySummaryLocal>{};
    for (final summary in summaries) {
      summaryByDate[_dateOnly(summary.date)] = summary;
    }

    final journalByDate = <DateTime, JournalEntry>{};
    for (final entry in journalEntries) {
      journalByDate[_dateOnly(entry.date)] = entry;
    }

    final points = <CrossDomainDataPoint>[];
    final focusSeries = <double>[];
    final sleepSeries = <double>[];
    final moodSeries = <double>[];
    final sleepMoodPairsX = <double>[];
    final sleepMoodPairsY = <double>[];
    final focusMoodPairsX = <double>[];
    final focusMoodPairsY = <double>[];
    final focusSleepPairsX = <double>[];
    final focusSleepPairsY = <double>[];

    var cursor = _dateOnly(start);
    final end = _dateOnly(endExclusive);
    var totalSleepDebt = 0.0;
    DateTime? bestFocusDate;
    DateTime? bestSleepDate;
    DateTime? lowMoodDate;
    var bestFocusMinutes = -1;
    var bestSleepMinutes = -1;
    var lowestMood = 2.0;

    while (!cursor.isAfter(end.subtract(const Duration(days: 1)))) {
      final summary = summaryByDate[cursor];
      final journal = journalByDate[cursor];

      final focusMinutes = summary?.focusMinutes ?? 0;
      final sleepMinutes = summary?.sleepMinutes ?? 0;
      final restMinutes = summary?.restMinutes ?? 0;
      final workoutMinutes = summary?.workoutMinutes ?? 0;
      final journalSleep = journal?.sleepHours;
      final moodScore =
          _moodScore(journal?.mood) ?? _energyScore(journal?.energyLevel);
      final energyScore = _energyScore(journal?.energyLevel);

      if (focusMinutes > bestFocusMinutes) {
        bestFocusMinutes = focusMinutes;
        bestFocusDate = focusMinutes > 0 ? cursor : bestFocusDate;
      }
      if (sleepMinutes > bestSleepMinutes) {
        bestSleepMinutes = sleepMinutes;
        bestSleepDate = sleepMinutes > 0 ? cursor : bestSleepDate;
      }
      if (moodScore != null && moodScore < lowestMood) {
        lowestMood = moodScore;
        lowMoodDate = cursor;
      }

      if (sleepMinutes > 0) {
        totalSleepDebt += max(0, _sleepTargetMinutes - sleepMinutes);
      }

      if (focusMinutes > 0 && sleepMinutes > 0) {
        focusSleepPairsX.add(focusMinutes.toDouble());
        focusSleepPairsY.add(sleepMinutes.toDouble());
      }
      if (sleepMinutes > 0 && moodScore != null) {
        sleepMoodPairsX.add(sleepMinutes.toDouble());
        sleepMoodPairsY.add(moodScore);
      }
      if (focusMinutes > 0 && moodScore != null) {
        focusMoodPairsX.add(focusMinutes.toDouble());
        focusMoodPairsY.add(moodScore);
      }

      focusSeries.add(focusMinutes.toDouble());
      sleepSeries.add(sleepMinutes.toDouble());
      if (moodScore != null) {
        moodSeries.add(moodScore);
      }

      points.add(
        CrossDomainDataPoint(
          date: cursor,
          focusMinutes: focusMinutes,
          sleepMinutes: sleepMinutes,
          restMinutes: restMinutes,
          workoutMinutes: workoutMinutes,
          journalSleepHours: journalSleep,
          moodScore: moodScore,
          energyScore: energyScore,
        ),
      );

      cursor = cursor.add(const Duration(days: 1));
    }

    return CrossDomainAnalytics(
      points: points,
      focusSleepCorrelation: _pearsonCorrelation(
        focusSleepPairsX,
        focusSleepPairsY,
      ),
      sleepMoodCorrelation: _pearsonCorrelation(
        sleepMoodPairsX,
        sleepMoodPairsY,
      ),
      focusMoodCorrelation: _pearsonCorrelation(
        focusMoodPairsX,
        focusMoodPairsY,
      ),
      averageFocusMinutes: focusSeries.isEmpty
          ? 0
          : _averageDouble(focusSeries),
      averageSleepMinutes: sleepSeries.isEmpty
          ? 0
          : _averageDouble(sleepSeries),
      averageMoodScore: moodSeries.isEmpty ? null : _averageDouble(moodSeries),
      totalSleepDebtMinutes: totalSleepDebt,
      highlights: CrossDomainHighlights(
        bestFocusDate: bestFocusDate,
        bestSleepDate: bestSleepDate,
        lowMoodDate: lowMoodDate,
      ),
    );
  }
}
