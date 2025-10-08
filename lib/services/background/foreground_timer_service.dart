import 'dart:isolate';
import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/l10n/l10n_loader.dart';

const _keyMode = 'foreground_timer_mode';
const _keySegment = 'foreground_timer_segment';
const _keyEndAt = 'foreground_timer_end_at';
const _keySmartInterval = 'foreground_timer_smart_interval';
const _keySmartWindow = 'foreground_timer_smart_window_start';
const _keySleepSoundActive = 'foreground_sleep_sound_active';
const _keySleepSoundStartedAt = 'foreground_sleep_sound_started_at';

@pragma('vm:entry-point')
void timerForegroundStartCallback() {
  FlutterForegroundTask.setTaskHandler(_TimerTaskHandler());
}

class _TimerTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    await _refreshNotification();
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    await _refreshNotification();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    await FlutterForegroundTask.clearAllData();
  }

  @override
  Future<void> onNotificationPressed() async {
    FlutterForegroundTask.launchApp();
  }

  Future<void> _refreshNotification() async {
    final l10n = await loadAppLocalizations();
    final endAtMillis = await FlutterForegroundTask.getData<int>(
      key: _keyEndAt,
    );
    if (endAtMillis == null) {
      return;
    }

    final endAt = DateTime.fromMillisecondsSinceEpoch(endAtMillis);
    final now = DateTime.now();
    final remainingSeconds = endAt.difference(now).inSeconds;
    if (remainingSeconds <= 0) {
      await FlutterForegroundTask.updateService(
        notificationTitle: l10n.tr('foreground_notification_running_title'),
        notificationText: l10n.tr('foreground_notification_almost_done'),
      );
      return;
    }

    final modeRaw =
        await FlutterForegroundTask.getData<String>(key: _keyMode) ?? 'TIMER';
    final segmentLabel = await FlutterForegroundTask.getData<String>(
          key: _keySegment,
        ) ??
        l10n.tr('foreground_notification_default_segment');

    final formatted = _formatCompact(l10n, remainingSeconds);
    final modeLabel = _modeLabel(l10n, modeRaw.toLowerCase());

    var notificationText = l10n.tr(
      'foreground_notification_segment_remaining',
      {
        'segment': segmentLabel,
        'time': formatted,
      },
    );

    final sleepSoundActive =
        await FlutterForegroundTask.getData<bool>(key: _keySleepSoundActive) ??
            false;
    if (sleepSoundActive) {
      final startedAtMillis = await FlutterForegroundTask.getData<int>(
        key: _keySleepSoundStartedAt,
      );
      final startedAt = startedAtMillis != null && startedAtMillis > 0
          ? DateTime.fromMillisecondsSinceEpoch(startedAtMillis)
          : null;
      final elapsedSeconds =
          startedAt != null ? now.difference(startedAt).inSeconds : 0;
      final overlay = elapsedSeconds > 0
          ? l10n.tr(
              'foreground_sleep_sound_notification',
              {
                'elapsed': _formatCompact(l10n, elapsedSeconds),
              },
            )
          : l10n.tr('foreground_sleep_sound_notification_idle');
      notificationText = '$notificationText • $overlay';
    }

    await FlutterForegroundTask.updateService(
      notificationTitle: l10n.tr(
        'foreground_notification_mode_progress',
        {'mode': modeLabel},
      ),
      notificationText: notificationText,
    );
  }
}

class ForegroundTimerService {
  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    final l10n = await loadAppLocalizations();

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'life_app_timer_channel',
        channelName: l10n.tr('foreground_channel_name'),
        channelDescription: l10n.tr('foreground_channel_description'),
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        isSticky: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 60000,
        isOnceEvent: false,
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
    _initialized = true;
  }

  static Future<void> start({
    required String title,
    required String text,
    required String mode,
    required String segmentLabel,
    required DateTime segmentEndAt,
    DateTime? smartWindowStart,
    Duration? smartInterval,
  }) async {
    await ensureInitialized();
    await _persistMetadata(
      mode: mode,
      segmentLabel: segmentLabel,
      segmentEndAt: segmentEndAt,
      smartWindowStart: smartWindowStart,
      smartInterval: smartInterval,
    );
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: text,
      );
    } else {
      await FlutterForegroundTask.startService(
        notificationTitle: title,
        notificationText: text,
        callback: timerForegroundStartCallback,
      );
    }
  }

  static Future<void> update({
    required String title,
    required String text,
    required String mode,
    required String segmentLabel,
    required DateTime segmentEndAt,
    DateTime? smartWindowStart,
    Duration? smartInterval,
  }) async {
    await _persistMetadata(
      mode: mode,
      segmentLabel: segmentLabel,
      segmentEndAt: segmentEndAt,
      smartWindowStart: smartWindowStart,
      smartInterval: smartInterval,
    );
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: text,
      );
    }
  }

  static Future<void> stop() async {
    await FlutterForegroundTask.clearAllData();
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  static Future<void> setSleepSoundActive({
    required bool active,
    DateTime? startedAt,
  }) async {
    if (!Platform.isAndroid) {
      return;
    }
    await ensureInitialized();
    if (active) {
      await FlutterForegroundTask.saveData(
        key: _keySleepSoundActive,
        value: true,
      );
      await FlutterForegroundTask.saveData(
        key: _keySleepSoundStartedAt,
        value: (startedAt ?? DateTime.now()).millisecondsSinceEpoch,
      );
    } else {
      await FlutterForegroundTask.saveData(
        key: _keySleepSoundActive,
        value: false,
      );
      await FlutterForegroundTask.saveData(
        key: _keySleepSoundStartedAt,
        value: 0,
      );
    }
  }

  static Future<void> _persistMetadata({
    required String mode,
    required String segmentLabel,
    required DateTime segmentEndAt,
    DateTime? smartWindowStart,
    Duration? smartInterval,
  }) async {
    await FlutterForegroundTask.saveData(
      key: _keyMode,
      value: mode.toUpperCase(),
    );
    await FlutterForegroundTask.saveData(key: _keySegment, value: segmentLabel);
    await FlutterForegroundTask.saveData(
      key: _keyEndAt,
      value: segmentEndAt.millisecondsSinceEpoch,
    );
    if (smartInterval != null) {
      await FlutterForegroundTask.saveData(
        key: _keySmartInterval,
        value: smartInterval.inSeconds,
      );
    }
    if (smartWindowStart != null) {
      await FlutterForegroundTask.saveData(
        key: _keySmartWindow,
        value: smartWindowStart.millisecondsSinceEpoch,
      );
    }
  }
}

String _formatCompact(AppLocalizations l10n, int seconds) {
  final duration = Duration(seconds: seconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final secs = duration.inSeconds.remainder(60);
  if (hours > 0) {
    return l10n.tr('duration_hours_minutes', {
      'hours': '$hours',
      'minutes': minutes.toString().padLeft(2, '0'),
    });
  }
  if (minutes > 0) {
    return l10n.tr('duration_minutes_seconds', {
      'minutes': '$minutes',
      'seconds': secs.toString().padLeft(2, '0'),
    });
  }
  return l10n.tr('duration_seconds_only', {'seconds': '$secs'});
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
      return mode.toUpperCase();
  }
}
