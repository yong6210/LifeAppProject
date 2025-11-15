import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class CalendarEvent {
  CalendarEvent({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    this.location,
    this.allDay = false,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    DateTime parseTime(dynamic value) {
      if (value is num) {
        return DateTime.fromMillisecondsSinceEpoch(
          value.toInt(),
          isUtc: true,
        ).toLocal();
      }
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) {
          return parsed.toLocal();
        }
      }
      return DateTime.now();
    }

    final startRaw = json['startsAt'];
    final endRaw = json['endsAt'];
    return CalendarEvent(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      startsAt: parseTime(startRaw),
      endsAt: parseTime(endRaw),
      location: json['location'] as String?,
      allDay: json['allDay'] as bool? ?? false,
    );
  }

  final String id;
  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? location;
  final bool allDay;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'startsAt': startsAt.toIso8601String(),
      'endsAt': endsAt.toIso8601String(),
      'location': location,
      'allDay': allDay,
    };
  }
}

abstract class CalendarAutomationService {
  Future<bool> requestPermissions();
  Future<List<CalendarEvent>> fetchUpcomingEvents({
    required DateTime start,
    required DateTime end,
  });
}

class MethodChannelCalendarAutomationService
    implements CalendarAutomationService {
  MethodChannelCalendarAutomationService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('life_app/calendarAutomation');

  final MethodChannel _channel;

  @override
  Future<bool> requestPermissions() async {
    try {
      final granted = await _channel.invokeMethod<bool>('requestPermissions');
      return granted ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<List<CalendarEvent>> fetchUpcomingEvents({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final results = await _channel
          .invokeMethod<List<dynamic>>('getUpcomingEvents', {
            'start': start.toUtc().millisecondsSinceEpoch,
            'end': end.toUtc().millisecondsSinceEpoch,
          });
      if (results == null) {
        return const [];
      }
      return results
          .map(
            (raw) =>
                CalendarEvent.fromJson(Map<String, dynamic>.from(raw as Map)),
          )
          .toList();
    } on PlatformException {
      return const [];
    }
  }
}

class MockCalendarAutomationService implements CalendarAutomationService {
  @override
  Future<List<CalendarEvent>> fetchUpcomingEvents({
    required DateTime start,
    required DateTime end,
  }) async {
    final now = DateTime.now();
    // TODO(calendar-mock-data): Replace the inline demo event with data loaded
    // from the connected calendar service and localized resources.
    // 현재는 'Team sync'와 같은 영어 문자열을 하드 코딩하여 실제 일정이나
    // 다국어 캘린더 데이터가 표시되지 않습니다.
    return [
      CalendarEvent(
        id: 'demo-focus-sync',
        title: 'Team sync',
        startsAt: now.add(const Duration(minutes: 45)),
        endsAt: now.add(const Duration(hours: 1, minutes: 15)),
        location: 'Zoom',
      ),
    ];
  }

  @override
  Future<bool> requestPermissions() async => true;
}

CalendarAutomationService createCalendarAutomationService() {
  if (kIsWeb) {
    // TODO(calendar-web): Implement a web calendar bridge instead of falling
    // back to the mock service.
    // 웹 빌드에서는 아직 권한/캘린더 연동이 없어 더미 데이터를 반환하는
    // MockCalendarAutomationService만 사용됩니다.
    return MockCalendarAutomationService();
  }
  if (Platform.isIOS || Platform.isAndroid) {
    return MethodChannelCalendarAutomationService();
  }
  // TODO(calendar-desktop): Provide desktop calendar integration or disable
  // the feature gracefully when no provider is configured.
  // 현재 데스크톱 플랫폼에서는 실제 캘린더 앱과의 연결이나 로컬 데이터
  // 로딩이 구현되지 않아 Mock 서비스만 동작합니다.
  return MockCalendarAutomationService();
}
