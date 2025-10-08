import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'package:life_app/l10n/l10n_loader.dart';
import 'package:life_app/services/notification_service.dart';

const _timerWorkUniqueName = 'life_app_timer_guard';
const _timerWorkTaskName = 'timer_guard_task';
const _prefsTimerStateKey = 'timer_state_v2';

/// Background guard that re-asserts timer notifications when the app has been
/// in the background for an extended period. Only used on Android.
class TimerWorkmanagerGuard {
  TimerWorkmanagerGuard._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized || !Platform.isAndroid) return;
    await Workmanager().initialize(_callbackDispatcher);
    _initialized = true;
  }

  /// Schedules a periodic single-shot work request that re-queues itself until
  /// the timer completes. Min delay follows WorkManager constraints (15 min).
  static Future<void> scheduleGuard() async {
    if (!Platform.isAndroid || !_initialized) return;
    await Workmanager().cancelByUniqueName(_timerWorkUniqueName);
    await Workmanager().registerOneOffTask(
      _timerWorkUniqueName,
      _timerWorkTaskName,
      initialDelay: const Duration(minutes: 15),
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 15),
    );
  }

  static Future<void> cancelGuard() async {
    if (!Platform.isAndroid || !_initialized) return;
    await Workmanager().cancelByUniqueName(_timerWorkUniqueName);
  }
}

@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await NotificationService.init();
    final l10n = await loadAppLocalizations();

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsTimerStateKey);
    if (raw == null) {
      return Future.value(true);
    }
    Map<String, dynamic>? state;
    try {
      state = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      state = null;
    }
    if (state == null) {
      await Workmanager().cancelByUniqueName(_timerWorkUniqueName);
      return Future.value(true);
    }
    final isRunning = state['isRunning'] as bool? ?? false;
    if (!isRunning) {
      await Workmanager().cancelByUniqueName(_timerWorkUniqueName);
      return Future.value(true);
    }

    String segmentLabel = l10n.tr('foreground_notification_default_segment');
    final segmentsRaw = state['segments'];
    if (segmentsRaw is List) {
      final idx = (state['currentIndex'] as num?)?.toInt() ?? 0;
      if (idx >= 0 && idx < segmentsRaw.length) {
        final entry = segmentsRaw[idx];
        if (entry is Map) {
          segmentLabel =
              (entry['label'] ?? segmentLabel).toString();
        }
      }
    }
    final segmentRemaining = (state['segmentRemaining'] as num?)?.toInt();
    final segmentStartedAtRaw = state['segmentStartedAt'] as String?;

    final now = DateTime.now();
    DateTime? segmentEnd;
    if (segmentStartedAtRaw != null && segmentRemaining != null) {
      try {
        final startedAt = DateTime.parse(segmentStartedAtRaw);
        segmentEnd = startedAt.add(Duration(seconds: segmentRemaining));
      } catch (_) {
        segmentEnd = null;
      }
    }

    if (segmentEnd != null && segmentEnd.isAfter(now)) {
      await NotificationService.scheduleTimerEnd(
        id: 4200,
        title: l10n.tr('notification_timer_generic_title'),
        body: l10n.tr('notification_timer_segment_body', {
          'segment': segmentLabel,
        }),
        scheduledAt: segmentEnd,
      );
      // Re-schedule guard to check again after the minimum window.
      await Workmanager().cancelByUniqueName(_timerWorkUniqueName);
      await Workmanager().registerOneOffTask(
        _timerWorkUniqueName,
        _timerWorkTaskName,
        initialDelay: const Duration(minutes: 15),
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(minutes: 15),
      );
    } else {
      await Workmanager().cancelByUniqueName(_timerWorkUniqueName);
    }

    return Future.value(true);
  });
}
