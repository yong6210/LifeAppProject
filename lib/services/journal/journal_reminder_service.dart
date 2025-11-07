import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:life_app/l10n/l10n_loader.dart';
import 'package:life_app/services/notification_service.dart';

class JournalReminderSettings {
  const JournalReminderSettings({
    required this.enabled,
    required this.timeOfDay,
  });

  static const int _defaultHour = 21;

  final bool enabled;
  final TimeOfDay timeOfDay;

  JournalReminderSettings copyWith({bool? enabled, TimeOfDay? timeOfDay}) {
    return JournalReminderSettings(
      enabled: enabled ?? this.enabled,
      timeOfDay: timeOfDay ?? this.timeOfDay,
    );
  }

  factory JournalReminderSettings.defaults() {
    return JournalReminderSettings(
      enabled: false,
      timeOfDay: const TimeOfDay(hour: _defaultHour, minute: 0),
    );
  }
}

class JournalReminderService {
  JournalReminderService._();

  static const String _keyEnabled = 'journal_reminder_enabled_v1';
  static const String _keyTime = 'journal_reminder_time_v1';

  static Future<JournalReminderSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyEnabled) ?? false;
    final timeRaw = prefs.getString(_keyTime);
    final fallback = JournalReminderSettings.defaults();
    if (timeRaw == null) {
      return fallback.copyWith(enabled: enabled);
    }

    final parts = timeRaw.split(':');
    if (parts.length != 2) {
      return fallback.copyWith(enabled: enabled);
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return fallback.copyWith(enabled: enabled);
    }

    return JournalReminderSettings(
      enabled: enabled,
      timeOfDay: TimeOfDay(hour: hour, minute: minute),
    );
  }

  static Future<JournalReminderSettings> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);

    final current = await load();
    if (enabled) {
      await scheduleReminder(current.timeOfDay);
    } else {
      await cancelReminder();
    }
    return current.copyWith(enabled: enabled);
  }

  static Future<JournalReminderSettings> setTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = _formatTime(time);
    await prefs.setString(_keyTime, normalized);

    var settings = await load();
    settings = settings.copyWith(timeOfDay: time);

    if (settings.enabled) {
      await scheduleReminder(time);
    }
    return settings;
  }

  static Future<void> scheduleReminder(TimeOfDay time) async {
    final l10n = await loadAppLocalizations();
    await NotificationService.scheduleJournalReminder(
      time: time,
      title: l10n.tr('journal_reminder_notification_title'),
      body: l10n.tr('journal_reminder_notification_body'),
    );
  }

  static Future<void> cancelReminder() async {
    await NotificationService.cancelJournalReminder();
  }

  static String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
