import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/l10n/l10n_loader.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _tzInitialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    // iOS/macOS 설정
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Android 설정 (기본 아이콘은 앱 아이콘 사용)
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );

    await _plugin.initialize(settings);
    _initialized = true;

    // Android 13+ 알림 권한 요청
    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin
          ?.requestPermission(); // granted == true/false/null (무시해도 무방)
    }
  }

  static Future<void> _ensureTimeZoneInitialized() async {
    if (_tzInitialized) return;
    tz.initializeTimeZones();
    String timeZoneName;
    try {
      timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    } catch (_) {
      timeZoneName = 'UTC';
    }
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    _tzInitialized = true;
  }

  static Future<void> showDone({required String mode}) async {
    await init();
    final l10n = await loadAppLocalizations();
    final modeLabel = _modeLabel(l10n, mode);
    final androidDetails = AndroidNotificationDetails(
      'timer_done_channel',
      l10n.tr('notification_timer_channel_name'),
      channelDescription: l10n.tr('notification_timer_channel_description'),
      importance: Importance.max,
      priority: Priority.high,
    );
    const darwinDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
    await _plugin.show(
      1001, // notification id
      l10n.tr('notification_timer_done_title'),
      l10n.tr('notification_timer_done_body', {'mode': modeLabel}),
      details,
    );
  }

  static Future<void> showBackupReminder({
    required String title,
    required String body,
  }) async {
    await init();
    final l10n = await loadAppLocalizations();
    final androidDetails = AndroidNotificationDetails(
      'backup_reminder_channel',
      l10n.tr('notification_backup_channel_name'),
      channelDescription: l10n.tr('notification_backup_channel_description'),
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const darwinDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.show(1201, title, body, details);
  }

  static Future<void> scheduleTimerEnd({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    await init();
    await _ensureTimeZoneInitialized();
    final l10n = await loadAppLocalizations();

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'timer_schedule_channel',
        l10n.tr('notification_timer_schedule_channel_name'),
        channelDescription: l10n.tr(
          'notification_timer_schedule_channel_description',
        ),
        importance: Importance.max,
        priority: Priority.high,
        scheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
    );

    final tzDateTime = tz.TZDateTime.from(scheduledAt, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDateTime,
      details,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> scheduleSmartSleepAlarmWindow({
    required int baseId,
    required String label,
    required DateTime windowStart,
    required DateTime targetTime,
    required Duration interval,
    bool includeFallbackExact = true,
  }) async {
    await init();
    await _ensureTimeZoneInitialized();
    final l10n = await loadAppLocalizations();

    final now = DateTime.now();
    if (targetTime.isBefore(now)) {
      return;
    }

    final normalizedStart = windowStart.isBefore(now)
        ? now.add(const Duration(seconds: 5))
        : windowStart;

    final prompts = <DateTime>[];
    const maxGentlePrompts = 3;
    var pointer = normalizedStart;
    while (pointer.isBefore(targetTime) && prompts.length < maxGentlePrompts) {
      if (pointer.isAfter(now)) {
        prompts.add(pointer);
      }
      pointer = pointer.add(interval);
    }

    if (includeFallbackExact || prompts.isEmpty) {
      prompts.add(targetTime);
    } else {
      final last = prompts.last;
      if (!last.isAtSameMomentAs(targetTime)) {
        prompts.add(targetTime);
      }
    }

    final seen = <int>{};
    for (var i = 0; i < prompts.length; i++) {
      final scheduledAt = prompts[i];
      final tzDateTime = tz.TZDateTime.from(scheduledAt, tz.local);
      final isFinal = scheduledAt.isAtSameMomentAs(targetTime);
      final id = baseId + i;
      if (!seen.add(id)) continue;

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          'sleep_smart_alarm_channel',
          l10n.tr('notification_sleep_channel_name'),
          channelDescription: l10n.tr('notification_sleep_channel_description'),
          importance: isFinal ? Importance.max : Importance.defaultImportance,
          priority: isFinal ? Priority.high : Priority.defaultPriority,
          fullScreenIntent: isFinal,
          scheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        ),
        iOS: DarwinNotificationDetails(presentSound: isFinal),
        macOS: const DarwinNotificationDetails(),
      );

      final title = isFinal
          ? l10n.tr('notification_sleep_final_title')
          : l10n.tr('notification_sleep_gentle_title');
      final body = isFinal
          ? l10n.tr('notification_sleep_final_body', {'routine': label})
          : l10n.tr('notification_sleep_gentle_body', {'routine': label});

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        details,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static Future<void> cancelTimerNotifications() async {
    await init();
    await _plugin.cancel(1001);
  }

  static Future<void> cancelNotification(int id) async {
    await init();
    await _plugin.cancel(id);
  }

  static Future<void> cancelNotificationRange(int baseId, int count) async {
    await init();
    for (var i = 0; i < count; i++) {
      await _plugin.cancel(baseId + i);
    }
  }

  static const int _journalReminderId = 4301;

  static Future<void> scheduleJournalReminder({
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    await init();
    await _ensureTimeZoneInitialized();

    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final tzDateTime = tz.TZDateTime.from(scheduled, tz.local);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'journal_reminder_channel',
        'Journal Reminder',
        channelDescription: 'Daily reminder to write your journal.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        category: AndroidNotificationCategory.reminder,
        scheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      _journalReminderId,
      title,
      body,
      tzDateTime,
      details,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelJournalReminder() async {
    await init();
    await _plugin.cancel(_journalReminderId);
  }
}

String _modeLabel(AppLocalizations l10n, String mode) {
  switch (mode) {
    case 'focus':
      return l10n.tr('timer_mode_focus');
    case 'rest':
      return l10n.tr('timer_mode_rest');
    case 'workout':
      return l10n.tr('timer_mode_workout');
    case 'sleep':
      return l10n.tr('timer_mode_sleep');
    default:
      return mode;
  }
}
