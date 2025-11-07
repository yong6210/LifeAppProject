// lib/providers/session_providers.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/models/session.dart';
import 'package:life_app/providers/db_provider.dart';
import 'package:life_app/providers/settings_providers.dart';
import 'package:life_app/repositories/session_repository.dart';
import 'package:life_app/utils/date_range.dart';

/// ───── 오늘 요약 모델 ─────
class TodaySummary {
  final int focus, rest, workout, sleep;
  const TodaySummary({
    this.focus = 0,
    this.rest = 0,
    this.workout = 0,
    this.sleep = 0,
  });
  int get total => focus + rest + workout + sleep;
}

/// 합계 계산
TodaySummary _sum(List<Session> list) {
  int focus = 0, rest = 0, workout = 0, sleep = 0;
  for (final x in list) {
    final minutes = (x.endedAt ?? x.startedAt)
        .difference(x.startedAt)
        .inMinutes;
    switch (x.type) {
      case 'focus':
        focus += minutes;
        break;
      case 'rest':
        rest += minutes;
        break;
      case 'workout':
        workout += minutes;
        break;
      case 'sleep':
        sleep += minutes;
        break;
    }
  }
  return TodaySummary(focus: focus, rest: rest, workout: workout, sleep: sleep);
}

/// ───── 오늘 요약 Provider ─────
final todaySummaryProvider = StreamProvider.autoDispose<TodaySummary>((ref) {
  final isarAsync = ref.watch(isarProvider);

  Stream<TodaySummary> streamFor(Isar isar) {
    final now = DateTime.now();
    final d0 = DateTime(now.year, now.month, now.day);
    final q = isar.sessions.where().localDateEqualTo(d0);

    return q
        .watch(fireImmediately: true)
        .asyncMap((_) => q.findAll())
        .map(_sum)
        .distinct(
          (a, b) =>
              a.focus == b.focus &&
              a.rest == b.rest &&
              a.workout == b.workout &&
              a.sleep == b.sleep,
        );
  }

  return isarAsync.when(
    data: (isar) => streamFor(isar),
    loading: () => Stream.value(const TodaySummary()), // ✅ 바로 Data 상태
    error: (e, st) => Stream.error(e, st),
  );
});

/// ───── 리포지토리 Provider ─────
final sessionRepoProvider = Provider<SessionRepository?>((ref) {
  final isarAsync = ref.watch(isarProvider);
  return isarAsync.maybeWhen(
    data: (isar) => SessionRepository(isar),
    orElse: () => null,
  );
});

/// ───── 세션 필터 Provider ─────
enum SessionFilter { all, today, week, month }

class SessionFilterNotifier extends Notifier<SessionFilter> {
  @override
  SessionFilter build() => SessionFilter.all;

  void set(SessionFilter value) => state = value;
}

final sessionFilterProvider =
    NotifierProvider<SessionFilterNotifier, SessionFilter>(
      SessionFilterNotifier.new,
    );

/// ───── 세션 스트림 Provider ─────
final sessionsStreamProvider = StreamProvider<List<Session>>((ref) {
  final repo = ref.watch(sessionRepoProvider);
  final filter = ref.watch(sessionFilterProvider);

  if (repo == null) return Stream.value(const <Session>[]);

  switch (filter) {
    case SessionFilter.all:
      return repo.watchAll();
    case SessionFilter.today:
      final range = todayRange();
      return repo.watchInRange(range.start, range.end);
    case SessionFilter.week:
      final range = thisWeekRange();
      return repo.watchInRange(range.start, range.end);
    case SessionFilter.month:
      final range = thisMonthRange();
      return repo.watchInRange(range.start, range.end);
  }
});

/// ───── 세션 조작 Provider ─────
final addDemoSessionProvider = FutureProvider<void>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  final repo = SessionRepository(isar);

  final now = DateTime.now();
  final end = now.add(const Duration(minutes: 25));

  final s = Session()
    ..type = 'focus'
    ..startedAt = now
    ..endedAt = end
    ..deviceId = 'demo-device'
    ..note = 'demo';

  await repo.add(s);
});

final addSessionProvider = FutureProvider.family<void, Session>((
  ref,
  session,
) async {
  final isar = await ref.watch(isarProvider.future);
  final repo = SessionRepository(isar);
  final settings = await ref.watch(settingsFutureProvider.future);
  if (session.deviceId.isEmpty) {
    session.deviceId = settings.deviceId;
  }
  await repo.add(session);
});

final deleteSessionProvider = FutureProvider.family<void, int>((ref, id) async {
  final isar = await ref.watch(isarProvider.future);
  final repo = SessionRepository(isar);
  await repo.deleteById(id);
});

/// ───── UI Helper ─────
/// ───── 오늘 합계 카드 UI ─────
class TodaySummaryCard extends ConsumerWidget {
  const TodaySummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // v3: valueOrNull 대신 maybeWhen 사용
    final t = ref
        .watch(todaySummaryProvider)
        .maybeWhen(data: (v) => v, orElse: () => const TodaySummary());
    final l10n = context.l10n;

    String formatMinutes(int minutes) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (hours > 0 && mins > 0) {
        return l10n.tr('duration_hours_minutes', {
          'hours': '$hours',
          'minutes': '$mins',
        });
      }
      if (hours > 0) {
        return l10n.tr('duration_hours_only', {'hours': '$hours'});
      }
      return l10n.tr('duration_minutes_only', {'minutes': '$mins'});
    }

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tr('home_daily_totals_title'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('${l10n.tr('session_type_focus')}  ${formatMinutes(t.focus)}'),
            Text('${l10n.tr('session_type_rest')}  ${formatMinutes(t.rest)}'),
            Text(
              '${l10n.tr('session_type_workout')}  ${formatMinutes(t.workout)}',
            ),
            Text('${l10n.tr('session_type_sleep')}  ${formatMinutes(t.sleep)}'),
            const Divider(height: 16),
            Text(
              '${l10n.tr('today_summary_total_label')}  ${formatMinutes(t.total)}',
            ),
          ],
        ),
      ),
    );
  }
}
