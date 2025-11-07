import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/services/audio/timer_audio_service.dart';
import 'package:life_app/services/audio/workout_cue_service.dart';
import 'package:life_app/services/background/foreground_timer_service.dart';
import 'package:life_app/services/background/workmanager_scheduler.dart';
import 'package:life_app/services/notification_service.dart';

abstract class TimerNotificationBridge {
  Future<void> showDone({required String mode});
  Future<void> scheduleTimerEnd({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  });
  Future<void> scheduleSmartSleepAlarmWindow({
    required int baseId,
    required String label,
    required DateTime windowStart,
    required DateTime targetTime,
    required Duration interval,
    bool includeFallbackExact,
  });
  Future<void> cancelNotificationRange(int baseId, int count);
  Future<void> cancelTimerNotifications();
}

abstract class TimerForegroundBridge {
  Future<void> ensureInitialized();
  Future<void> start({
    required String title,
    required String text,
    required String mode,
    required String segmentLabel,
    required DateTime segmentEndAt,
    DateTime? smartWindowStart,
    Duration? smartInterval,
  });
  Future<void> update({
    required String title,
    required String text,
    required String mode,
    required String segmentLabel,
    required DateTime segmentEndAt,
    DateTime? smartWindowStart,
    Duration? smartInterval,
  });
  Future<void> setSleepSoundActive({required bool active, DateTime? startedAt});
  Future<void> stop();
}

abstract class TimerBackgroundBridge {
  Future<void> scheduleGuard();
  Future<void> cancelGuard();
}

class DefaultTimerNotificationBridge implements TimerNotificationBridge {
  @override
  Future<void> cancelNotificationRange(int baseId, int count) {
    return NotificationService.cancelNotificationRange(baseId, count);
  }

  @override
  Future<void> cancelTimerNotifications() {
    return NotificationService.cancelTimerNotifications();
  }

  @override
  Future<void> scheduleSmartSleepAlarmWindow({
    required int baseId,
    required String label,
    required DateTime windowStart,
    required DateTime targetTime,
    required Duration interval,
    bool includeFallbackExact = true,
  }) {
    return NotificationService.scheduleSmartSleepAlarmWindow(
      baseId: baseId,
      label: label,
      windowStart: windowStart,
      targetTime: targetTime,
      interval: interval,
      includeFallbackExact: includeFallbackExact,
    );
  }

  @override
  Future<void> scheduleTimerEnd({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) {
    return NotificationService.scheduleTimerEnd(
      id: id,
      title: title,
      body: body,
      scheduledAt: scheduledAt,
    );
  }

  @override
  Future<void> showDone({required String mode}) {
    return NotificationService.showDone(mode: mode);
  }
}

class DefaultTimerForegroundBridge implements TimerForegroundBridge {
  @override
  Future<void> ensureInitialized() {
    return ForegroundTimerService.ensureInitialized();
  }

  @override
  Future<void> start({
    required String title,
    required String text,
    required String mode,
    required String segmentLabel,
    required DateTime segmentEndAt,
    DateTime? smartWindowStart,
    Duration? smartInterval,
  }) {
    return ForegroundTimerService.start(
      title: title,
      text: text,
      mode: mode,
      segmentLabel: segmentLabel,
      segmentEndAt: segmentEndAt,
      smartWindowStart: smartWindowStart,
      smartInterval: smartInterval,
    );
  }

  @override
  Future<void> stop() {
    return ForegroundTimerService.stop();
  }

  @override
  Future<void> update({
    required String title,
    required String text,
    required String mode,
    required String segmentLabel,
    required DateTime segmentEndAt,
    DateTime? smartWindowStart,
    Duration? smartInterval,
  }) {
    return ForegroundTimerService.update(
      title: title,
      text: text,
      mode: mode,
      segmentLabel: segmentLabel,
      segmentEndAt: segmentEndAt,
      smartWindowStart: smartWindowStart,
      smartInterval: smartInterval,
    );
  }

  @override
  Future<void> setSleepSoundActive({
    required bool active,
    DateTime? startedAt,
  }) {
    return ForegroundTimerService.setSleepSoundActive(
      active: active,
      startedAt: startedAt,
    );
  }
}

class NoopTimerForegroundBridge implements TimerForegroundBridge {
  const NoopTimerForegroundBridge();

  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<void> start({
    required String title,
    required String text,
    required String mode,
    required String segmentLabel,
    required DateTime segmentEndAt,
    DateTime? smartWindowStart,
    Duration? smartInterval,
  }) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> update({
    required String title,
    required String text,
    required String mode,
    required String segmentLabel,
    required DateTime segmentEndAt,
    DateTime? smartWindowStart,
    Duration? smartInterval,
  }) async {}

  @override
  Future<void> setSleepSoundActive({
    required bool active,
    DateTime? startedAt,
  }) async {}
}

class DefaultTimerBackgroundBridge implements TimerBackgroundBridge {
  @override
  Future<void> cancelGuard() {
    return TimerWorkmanagerGuard.cancelGuard();
  }

  @override
  Future<void> scheduleGuard() {
    return TimerWorkmanagerGuard.scheduleGuard();
  }
}

class NoopTimerBackgroundBridge implements TimerBackgroundBridge {
  const NoopTimerBackgroundBridge();

  @override
  Future<void> cancelGuard() async {}

  @override
  Future<void> scheduleGuard() async {}
}

class TimerDependencies {
  TimerDependencies({
    TimerAudioEngine? audio,
    TimerNotificationBridge? notifications,
    TimerForegroundBridge? foreground,
    TimerBackgroundBridge? background,
    WorkoutCueService? workoutCues,
  }) : audio = audio ?? TimerAudioService(),
       notifications = notifications ?? DefaultTimerNotificationBridge(),
       foreground =
           foreground ??
           (_isAndroid
               ? DefaultTimerForegroundBridge()
               : const NoopTimerForegroundBridge()),
       background =
           background ??
           (_isAndroid
               ? DefaultTimerBackgroundBridge()
               : const NoopTimerBackgroundBridge()),
       workoutCues = workoutCues ?? WorkoutCueService();

  final TimerAudioEngine audio;
  final TimerNotificationBridge notifications;
  final TimerForegroundBridge foreground;
  final TimerBackgroundBridge background;
  final WorkoutCueService workoutCues;
}

bool get _isAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

final timerDependenciesProvider = Provider<TimerDependencies>((ref) {
  return TimerDependencies();
});
