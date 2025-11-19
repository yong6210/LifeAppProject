import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/services/automation/calendar_automation_service.dart';
import 'package:life_app/services/automation/shortcut_automation_service.dart';

final calendarAutomationServiceProvider = Provider<CalendarAutomationService>((
  ref,
) {
  return createCalendarAutomationService();
});

final upcomingCalendarEventsProvider = FutureProvider<List<CalendarEvent>>((
  ref,
) async {
  final service = ref.watch(calendarAutomationServiceProvider);
  final now = DateTime.now();
  final events = await service.fetchUpcomingEvents(
    start: now,
    end: now.add(const Duration(hours: 12)),
  );
  events.sort((a, b) => a.startsAt.compareTo(b.startsAt));
  return events;
});

final nextCalendarEventProvider = FutureProvider<CalendarEvent?>((ref) async {
  final events = await ref.watch(upcomingCalendarEventsProvider.future);
  final now = DateTime.now();
  for (final event in events) {
    if (event.endsAt.isAfter(now)) {
      return event;
    }
  }
  return null;
});

final shortcutAutomationServiceProvider = Provider<ShortcutAutomationService>((
  ref,
) {
  return createShortcutAutomationService();
});

final shortcutInvocationStreamProvider = StreamProvider<ShortcutInvocation>((
  ref,
) {
  final service = ref.watch(shortcutAutomationServiceProvider);
  return service.watchInvocations();
});

// TODO(automation-shortcuts): Load shortcut definitions from stored settings
// or remote config and provide localized labels.
// 현재는 영어 문구와 하드 코딩된 두 개의 단축키만 제공되어 다국어 지원과
// 사용자 맞춤 구성이 전혀 이루어지지 않습니다.
const defaultTimerShortcuts = <ShortcutDefinition>[
  ShortcutDefinition(
    id: 'start_focus_timer',
    action: 'start_focus',
    shortLabel: 'Start focus timer',
  ),
  ShortcutDefinition(
    id: 'stop_timer',
    action: 'stop_timer',
    shortLabel: 'Stop current timer',
  ),
];
