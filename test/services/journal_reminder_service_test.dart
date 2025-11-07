import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:life_app/services/journal/journal_reminder_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final defaultMessenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final recordedCalls = <MethodCall>[];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    recordedCalls.clear();
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
    defaultMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall call) async {
        recordedCalls.add(call);
        switch (call.method) {
          case 'initialize':
            return true;
          case 'zonedSchedule':
          case 'cancel':
          case 'requestNotificationsPermission':
          case 'resolvePlatformSpecificImplementation':
            return null;
          default:
            return true;
        }
      },
    );
  });

  tearDown(() {
    defaultMessenger.setMockMethodCallHandler(channel, null);
  });

  test('load returns defaults', () async {
    final settings = await JournalReminderService.load();
    expect(settings.enabled, isFalse);
    expect(settings.timeOfDay.hour, 21);
    expect(settings.timeOfDay.minute, 0);
  });

  test('setTime persists selection', () async {
    final updated = await JournalReminderService.setTime(
      const TimeOfDay(hour: 7, minute: 30),
    );
    expect(updated.timeOfDay.hour, 7);
    expect(updated.timeOfDay.minute, 30);

    final reloaded = await JournalReminderService.load();
    expect(reloaded.timeOfDay.hour, 7);
    expect(reloaded.timeOfDay.minute, 30);
  });

  test('setEnabled schedules and cancels reminders', () async {
    await JournalReminderService.setTime(const TimeOfDay(hour: 8, minute: 0));

    final enabledSettings = await JournalReminderService.setEnabled(true);
    expect(enabledSettings.enabled, isTrue);
    expect(recordedCalls.any((call) => call.method == 'zonedSchedule'), isTrue);

    final disabledSettings = await JournalReminderService.setEnabled(false);
    expect(disabledSettings.enabled, isFalse);
    expect(recordedCalls.any((call) => call.method == 'cancel'), isTrue);
  });
}
