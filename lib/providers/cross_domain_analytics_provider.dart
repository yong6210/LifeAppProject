import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/providers/db_provider.dart';
import 'package:life_app/providers/settings_providers.dart';
import 'package:life_app/repositories/daily_summary_repository.dart';
import 'package:life_app/services/analytics/cross_domain_analytics_service.dart';
import 'package:life_app/services/journal/journal_store.dart';

enum CrossDomainRange {
  last7Days(7),
  last14Days(14),
  last30Days(30);

  const CrossDomainRange(this.days);
  final int days;
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

Future<DailySummaryRepository> _summaryRepo(Ref ref) async {
  final isar = await ref.watch(isarProvider.future);
  return DailySummaryRepository(isar);
}

final crossDomainAnalyticsProvider =
    FutureProvider.family<CrossDomainAnalytics, CrossDomainRange>((
      ref,
      range,
    ) async {
      final repo = await _summaryRepo(ref);
      final settings = await ref.watch(settingsFutureProvider.future);
      final today = _dateOnly(DateTime.now());
      final endExclusive = today.add(const Duration(days: 1));
      final start = endExclusive.subtract(Duration(days: range.days));

      final summaries = await repo.fetchBetween(start, endExclusive);
      final deviceSummaries = summaries.where(
        (summary) => summary.deviceId == settings.deviceId,
      );

      final journalEntries = await JournalStore.loadEntries();
      final filteredJournal = journalEntries.where((entry) {
        final date = _dateOnly(entry.date);
        return !date.isBefore(_dateOnly(start)) && date.isBefore(endExclusive);
      });

      return CrossDomainAnalyticsBuilder.build(
        start: start,
        endExclusive: endExclusive,
        summaries: deviceSummaries,
        journalEntries: filteredJournal,
      );
    });
