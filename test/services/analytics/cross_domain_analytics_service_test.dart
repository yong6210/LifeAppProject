import 'package:flutter_test/flutter_test.dart';
import 'package:life_app/features/journal/journal_entry.dart';
import 'package:life_app/models/daily_summary_local.dart';
import 'package:life_app/services/analytics/cross_domain_analytics_service.dart';

DailySummaryLocal _summary(
  DateTime date, {
  required String deviceId,
  int focus = 0,
  int sleep = 0,
  int rest = 0,
  int workout = 0,
}) {
  return DailySummaryLocal()
    ..date = date
    ..deviceId = deviceId
    ..focusMinutes = focus
    ..sleepMinutes = sleep
    ..restMinutes = rest
    ..workoutMinutes = workout;
}

JournalEntry _journal(
  DateTime date, {
  required String mood,
  String? energy,
  double sleepHours = 7,
}) {
  return JournalEntry(
    id: '${date.millisecondsSinceEpoch}',
    date: date,
    mood: mood,
    sleepHours: sleepHours,
    energyLevel: energy,
  );
}

void main() {
  group('CrossDomainAnalyticsBuilder', () {
    test('computes correlations and averages', () {
      final start = DateTime(2025, 1, 1);
      final endExclusive = DateTime(2025, 1, 4);
      final deviceId = 'device';
      final summaries = [
        _summary(DateTime(2025, 1, 1), deviceId: deviceId, focus: 60, sleep: 420),
        _summary(DateTime(2025, 1, 2), deviceId: deviceId, focus: 90, sleep: 450),
        _summary(DateTime(2025, 1, 3), deviceId: deviceId, focus: 120, sleep: 480),
      ];

      final journals = [
        _journal(DateTime(2025, 1, 1), mood: 'tired', energy: 'Low', sleepHours: 6),
        _journal(DateTime(2025, 1, 2), mood: 'calm', energy: 'Balanced', sleepHours: 7),
        _journal(DateTime(2025, 1, 3), mood: 'energized', energy: 'Energetic', sleepHours: 7.5),
      ];

      final analytics = CrossDomainAnalyticsBuilder.build(
        start: start,
        endExclusive: endExclusive,
        summaries: summaries,
        journalEntries: journals,
      );

      expect(analytics.points, hasLength(3));
      expect(analytics.averageFocusMinutes, closeTo(90, 0.001));
      expect(analytics.averageSleepMinutes, closeTo(450, 0.001));
      expect(analytics.averageMoodScore, isNotNull);
      expect(
        analytics.focusSleepCorrelation,
        greaterThan(0.8),
      );
      expect(
        analytics.sleepMoodCorrelation,
        greaterThan(0.8),
      );
      expect(
        analytics.focusMoodCorrelation,
        greaterThan(0.8),
      );
      expect(analytics.highlights.bestFocusDate, DateTime(2025, 1, 3));
      expect(analytics.highlights.bestSleepDate, DateTime(2025, 1, 3));
      expect(analytics.highlights.lowMoodDate, DateTime(2025, 1, 1));
    });

    test('handles missing data gracefully', () {
      final start = DateTime(2025, 2, 1);
      final endExclusive = DateTime(2025, 2, 4);
      final summaries = [
        _summary(DateTime(2025, 2, 1), deviceId: 'device', focus: 0, sleep: 360),
        _summary(DateTime(2025, 2, 3), deviceId: 'device', focus: 30, sleep: 0),
      ];

      final journals = [
        _journal(DateTime(2025, 2, 1), mood: '', energy: 'Low', sleepHours: 5.5),
      ];

      final analytics = CrossDomainAnalyticsBuilder.build(
        start: start,
        endExclusive: endExclusive,
        summaries: summaries,
        journalEntries: journals,
      );

      expect(analytics.points, hasLength(3));
      expect(analytics.focusSleepCorrelation, isNull);
      expect(analytics.sleepMoodCorrelation, isNull);
      expect(analytics.focusMoodCorrelation, isNull);
      expect(analytics.averageMoodScore, isNotNull);
      expect(analytics.highlights.bestFocusDate, DateTime(2025, 2, 3));
      expect(analytics.totalSleepDebtMinutes, greaterThan(0));
    });
  });
}

