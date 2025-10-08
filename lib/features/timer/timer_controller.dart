import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/features/timer/timer_dependencies.dart';
import 'package:life_app/features/timer/timer_plan.dart';
import 'package:life_app/features/timer/timer_state.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/l10n/l10n_loader.dart';
import 'package:life_app/models/session.dart';
import 'package:life_app/models/settings.dart';
import 'package:life_app/providers/session_providers.dart';
import 'package:life_app/providers/settings_providers.dart';
import 'package:life_app/providers/feature_flags.dart';
import 'package:life_app/services/analytics/analytics_service.dart';
import 'package:life_app/providers/accessibility_providers.dart';
import 'package:life_app/services/audio/sleep_sound_catalog.dart';
import 'package:life_app/services/audio/sleep_sound_analyzer.dart';
import 'package:life_app/providers/sleep_analysis_providers.dart';
import 'package:life_app/services/audio/timer_audio_service.dart';
import 'package:life_app/providers/diagnostics_providers.dart';
import 'package:life_app/services/diagnostics/timer_diagnostics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimerController extends Notifier<TimerState> {
  Timer? _ticker;
  DateTime? _segmentEndAt;
  TimerPlan? _currentPlan;
  late TimerAudioEngine _audioService;
  late TimerNotificationBridge _notifications;
  late TimerForegroundBridge _foreground;
  late TimerBackgroundBridge _background;
  late TimerDependencies _deps;
  bool _allowHaptics = true;
  SharedPreferences? _prefs;
  SleepSoundAnalyzer? _sleepSoundAnalyzer;
  bool _sleepCaptureActive = false;
  bool _sleepForegroundActive = false;

  static const _prefsKey = 'timer_state_v2';
  static const _notificationIdBase = 4200;

  Future<AppLocalizations> _localizations() => loadAppLocalizations();

  @override
  TimerState build() {
    _deps = ref.read(timerDependenciesProvider);
    _audioService = _deps.audio;
    _notifications = _deps.notifications;
    _foreground = _deps.foreground;
    _background = _deps.background;
    _allowHaptics = !ref.read(reducedMotionProvider);
    ref.listen<bool>(reducedMotionProvider, (previous, next) {
      _allowHaptics = !next;
    });
    final defaultPlan = TimerPlanFactory.createPlan('focus', Settings());
    state = TimerState.idle(plan: defaultPlan);

    unawaited(_foreground.ensureInitialized());
    Future.microtask(() async {
      await _foreground.ensureInitialized();
      try {
        _prefs = await SharedPreferences.getInstance();
      } catch (_) {
        _prefs = null;
      }
      await _audioService.init();
      await _loadPlanAndRestore(mode: state.mode);
    });

    ref.onDispose(() async {
      await _stopTicker();
      await _audioService.dispose();
      await _cancelScheduledNotifications();
      await _foreground.stop();
      await _disposeSleepSoundAnalyzer();
    });

    return state;
  }

  Future<void> selectMode(String mode) async {
    await _loadPlanAndRestore(mode: mode, forceReset: true);
  }

  Future<void> setPreset(String mode, int minutes) async {
    await selectMode(mode);
  }

  Future<void> refreshCurrentPlan() async {
    await _loadPlanAndRestore(mode: state.mode, forceReset: true);
  }

  Future<void> toggleSound() async {
    final enabled = !state.isSoundEnabled;
    state = state.copyWith(isSoundEnabled: enabled);
    if (enabled) {
      await _audioService.setEnabled(
        true,
        profile: state.currentSegment.playSoundProfile,
      );
    } else {
      await _audioService.setEnabled(false);
    }
    await _persistState();
  }

  Future<void> toggleStartStop() async {
    if (state.isRunning) {
      await _pause();
    } else {
      await _start();
    }
  }

  Future<void> reset() async {
    final plan =
        _currentPlan ?? TimerPlanFactory.createPlan(state.mode, Settings());
    state = TimerState.idle(plan: plan, soundEnabled: state.isSoundEnabled);
    await _stopTicker();
    await _audioService.setEnabled(false);
    await _cancelScheduledNotifications();
    await _foreground.stop();
    await _background.cancelGuard();
    await _cancelSleepSoundCapture();
    await _persistState();
    await AnalyticsService.logEvent('session_reset', {'mode': state.mode});
  }

  Future<void> skipSegment() async {
    if (_currentPlan == null) return;
    if (state.isLastSegment) {
      await reset();
      return;
    }
    await _completeCurrentSegment(record: false, autoAdvance: true);
    await AnalyticsService.logEvent('segment_skip', {'mode': state.mode});
  }

  Future<void> previousSegment() async {
    if (_currentPlan == null) return;
    final idx = state.currentSegmentIndex;
    if (idx == 0) {
      await reset();
      return;
    }
    await _stopTicker();
    final remainingAfter =
        _remainingSecondsAfter(idx - 1) +
        state.segments[idx - 1].duration.inSeconds;
    state = state.copyWith(
      currentSegmentIndex: idx - 1,
      segmentRemainingSeconds: state.segments[idx - 1].duration.inSeconds,
      remainingSeconds: remainingAfter,
      isRunning: false,
      segmentStartedAt: null,
      sessionStartedAt: state.sessionStartedAt,
    );
    await _audioService.updateProfile(
      state.isSoundEnabled ? state.currentSegment.playSoundProfile : null,
    );
    await _cancelScheduledNotifications();
    await _persistState();
    await AnalyticsService.logEvent('segment_rewind', {
      'mode': state.mode,
      'target_segment': state.currentSegment.id,
    });
  }

  Future<void> _loadPlanAndRestore({
    required String mode,
    bool forceReset = false,
  }) async {
    final settings = await ref.read(settingsFutureProvider.future);
    await _audioService.configureSleepAmbience(
      white: settings.sleepMixerWhiteLevel,
      pink: settings.sleepMixerPinkLevel,
      brown: settings.sleepMixerBrownLevel,
      presetId: settings.sleepMixerPresetId.isEmpty
          ? SleepSoundCatalog.defaultPresetId
          : settings.sleepMixerPresetId,
    );
    final plan = TimerPlanFactory.createPlan(mode, settings);
    _currentPlan = plan;

    final restored = forceReset ? false : await _restoreState(plan);
    if (!restored) {
      state = TimerState.idle(plan: plan, soundEnabled: state.isSoundEnabled);
      await _foreground.stop();
      await _background.cancelGuard();
      await _persistState();
    }
  }

  Future<bool> _restoreState(TimerPlan plan) async {
    final prefs = _prefs;
    if (prefs == null) return false;
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return false;
    final Map<String, dynamic> map;
    try {
      map = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return false;
    }

    if (map['mode'] != plan.mode) {
      return false;
    }
    final segmentsData = (map['segments'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    if (!_segmentsMatch(plan.segments, segmentsData)) {
      return false;
    }

    final currentIndex = (map['currentIndex'] as num?)?.toInt() ?? 0;
    final savedRemainingSeconds =
        (map['remainingSeconds'] as num?)?.toInt() ?? plan.totalSeconds;
    final segmentRemaining =
        (map['segmentRemaining'] as num?)?.toInt() ??
        plan.segments[currentIndex].duration.inSeconds;
    final isRunning = map['isRunning'] as bool? ?? false;
    final soundEnabled = map['isSoundEnabled'] as bool? ?? false;
    final sessionStartedAt = map['sessionStartedAt'] != null
        ? DateTime.parse(map['sessionStartedAt'] as String)
        : null;
    final segmentStartedAt = map['segmentStartedAt'] != null
        ? DateTime.parse(map['segmentStartedAt'] as String)
        : null;

    var computedSegmentRemaining = segmentRemaining;
    if (isRunning && segmentStartedAt != null) {
      final elapsed = DateTime.now().difference(segmentStartedAt).inSeconds;
      computedSegmentRemaining = (segmentRemaining - elapsed).clamp(
        0,
        plan.segments[currentIndex].duration.inSeconds,
      );
    }
    final newRemaining = isRunning
        ? computedSegmentRemaining +
              _remainingSecondsAfter(currentIndex + 1, plan: plan)
        : savedRemainingSeconds;

    state = TimerState(
      mode: plan.mode,
      segments: plan.segments,
      currentSegmentIndex: currentIndex.clamp(0, plan.segments.length - 1),
      totalSeconds: plan.totalSeconds,
      remainingSeconds: newRemaining,
      segmentRemainingSeconds: computedSegmentRemaining,
      isRunning: isRunning && computedSegmentRemaining > 0,
      sessionStartedAt: sessionStartedAt,
      segmentStartedAt: isRunning && computedSegmentRemaining > 0
          ? segmentStartedAt
          : null,
      isSoundEnabled: soundEnabled,
    );

    final l10n = await _localizations();
    if (state.isRunning) {
      await _startTicker(resume: true);
      await _audioService.setEnabled(
        state.isSoundEnabled,
        profile: state.currentSegment.playSoundProfile,
      );
      final segmentEnd = segmentStartedAt!.add(
        Duration(seconds: segmentRemaining),
      );
      _segmentEndAt = segmentEnd;
      await _scheduleNotification(segmentEnd, state.currentSegment);
      final smartConfig = state.currentSegment.smartAlarm;
      final segmentLabel = state.currentSegment.labelFor(l10n);
      final runningText = l10n.tr('foreground_notification_segment_remaining', {
        'segment': segmentLabel,
        'time': _formatForegroundDuration(l10n, state.segmentRemainingSeconds),
      });
      await _foreground.start(
        title: l10n.tr('foreground_notification_running_title'),
        text: runningText,
        mode: state.mode,
        segmentLabel: segmentLabel,
        segmentEndAt: _segmentEndAt!,
        smartWindowStart: smartConfig != null
            ? _segmentEndAt!.subtract(smartConfig.windowDuration)
            : null,
        smartInterval: smartConfig?.intervalDuration,
      );
      await _background.scheduleGuard();
    } else {
      await _audioService.setEnabled(false);
      await _foreground.stop();
      await _background.cancelGuard();
    }

    return true;
  }

  bool _segmentsMatch(
    List<TimerSegment> planSegments,
    List<Map<String, dynamic>> savedSegments,
  ) {
    if (planSegments.length != savedSegments.length) return false;
    for (var i = 0; i < planSegments.length; i++) {
      if (planSegments[i].id != savedSegments[i]['id']) return false;
      if (planSegments[i].duration.inSeconds !=
          (savedSegments[i]['duration'] as num?)?.toInt()) {
        return false;
      }
    }
    return true;
  }

  Future<void> _start() async {
    if (_currentPlan == null) {
      await _loadPlanAndRestore(mode: state.mode, forceReset: true);
    }
    if (state.remainingSeconds <= 0) {
      await reset();
      return;
    }
    final existingSessionStart = state.sessionStartedAt;
    final now = DateTime.now();
    final l10n = await _localizations();
    if (_allowHaptics) {
      HapticFeedback.mediumImpact();
    }
    state = state.copyWith(
      isRunning: true,
      sessionStartedAt: state.sessionStartedAt ?? now,
      segmentStartedAt: now,
    );
    await _startTicker();
    _segmentEndAt = now.add(Duration(seconds: state.segmentRemainingSeconds));
    await _audioService.setEnabled(
      state.isSoundEnabled,
      profile: state.currentSegment.playSoundProfile,
    );
    await _scheduleNotification(_segmentEndAt!, state.currentSegment);
    final smartConfig = state.currentSegment.smartAlarm;
    final segmentLabel = state.currentSegment.labelFor(l10n);
    final runningTitle = l10n.tr('foreground_notification_running_title');
    final runningText = l10n.tr('foreground_notification_segment_remaining', {
      'segment': segmentLabel,
      'time': _formatForegroundDuration(l10n, state.segmentRemainingSeconds),
    });
    await _foreground.start(
      title: runningTitle,
      text: runningText,
      mode: state.mode,
      segmentLabel: segmentLabel,
      segmentEndAt: _segmentEndAt!,
      smartWindowStart: smartConfig != null
          ? _segmentEndAt!.subtract(smartConfig.windowDuration)
          : null,
      smartInterval: smartConfig?.intervalDuration,
    );
    await _persistState();
    await _background.scheduleGuard();
    await _startSleepSoundCaptureIfNeeded(state.currentSegment);

    final sessionStartedAt = state.sessionStartedAt ?? now;
    final elapsed = now.difference(sessionStartedAt).inSeconds;
    final eventName = existingSessionStart == null
        ? 'session_start'
        : 'session_resume';
    await AnalyticsService.logEvent(eventName, {
      'mode': state.mode,
      'segment_id': state.currentSegment.id,
      'segment_label': segmentLabel,
      'plan_segments': state.segments.length,
      'sound_enabled': state.isSoundEnabled,
      'elapsed_sec': elapsed,
    });
  }

  Future<void> _pause() async {
    _recalculateRemaining();
    state = state.copyWith(isRunning: false, segmentStartedAt: null);
    await _stopTicker();
    await _cancelScheduledNotifications();
    await _audioService.setEnabled(false);
    await _foreground.stop();
    await _background.cancelGuard();
    await _cancelSleepSoundCapture();
    await _persistState();
    final startedAt = state.sessionStartedAt;
    final elapsed = startedAt != null
        ? DateTime.now().difference(startedAt).inSeconds
        : 0;
    await AnalyticsService.logEvent('session_pause', {
      'mode': state.mode,
      'segment_id': state.currentSegment.id,
      'remaining_sec': state.remainingSeconds,
      'elapsed_sec': elapsed,
    });
  }

  Future<void> _startTicker({bool resume = false}) async {
    await _stopTicker();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    if (!resume) {
      _tick();
    }
  }

  Future<void> _stopTicker() async {
    _ticker?.cancel();
    _ticker = null;
    _segmentEndAt = null;
  }

  Future<void> _tick() async {
    if (!state.isRunning) return;
    if (_segmentEndAt == null) return;
    final now = DateTime.now();
    var segmentRemaining = _segmentEndAt!.difference(now).inSeconds;
    if (segmentRemaining < 0) segmentRemaining = 0;

    final remaining =
        segmentRemaining +
        _remainingSecondsAfter(state.currentSegmentIndex + 1);

    state = state.copyWith(
      segmentRemainingSeconds: segmentRemaining,
      remainingSeconds: remaining,
    );

    if (segmentRemaining <= 0) {
      await _completeCurrentSegment();
    } else {
      await _persistState();
    }
  }

  Future<void> _completeCurrentSegment({
    bool record = true,
    bool autoAdvance = true,
  }) async {
    await _cancelScheduledNotifications();

    final segment = state.currentSegment;
    if (_allowHaptics) {
      HapticFeedback.lightImpact();
    }
    final now = DateTime.now();
    final l10n = await _localizations();
    final segmentLabel = segment.labelFor(l10n);
    if (_segmentEndAt != null) {
      final skewMs = now.difference(_segmentEndAt!).inMilliseconds;
      await AnalyticsService.logEvent('timer_accuracy_sample', {
        'mode': state.mode,
        'segment_id': segment.id,
        'segment_label': segmentLabel,
        'skew_ms': skewMs,
      });
      final diagnostics = await ref.read(
        timerDiagnosticsServiceProvider.future,
      );
      unawaited(
        diagnostics.appendAccuracySample(
          TimerAccuracySample(
            recordedAt: now.toUtc(),
            mode: state.mode,
            segmentId: segment.id,
            segmentLabel: segmentLabel,
            skewMs: skewMs,
          ),
        ),
      );
    }
    if (record && segment.recordSession) {
      await _recordSession(segment, l10n: l10n);
    }

    final isSleepRecordingSegment =
        segment.type == 'sleep' && segment.recordSession;
    if (isSleepRecordingSegment) {
      await _finalizeSleepSoundCapture(saveSummary: record);
    }

    await AnalyticsService.logEvent('segment_complete', {
      'mode': state.mode,
      'segment_id': segment.id,
      'segment_label': segmentLabel,
      'segment_type': segment.type,
      'duration_sec': segment.duration.inSeconds,
    });

    if (state.isLastSegment) {
      await _notifications.showDone(mode: state.mode);
      await _audioService.setEnabled(false);
      final startedAt = state.sessionStartedAt;
      final elapsed = startedAt != null
          ? now.difference(startedAt).inSeconds
          : _currentPlan?.totalSeconds ?? 0;
      await AnalyticsService.logEvent('session_end', {
        'mode': state.mode,
        'duration_sec': elapsed,
        'segments': state.segments.length,
      });
      await AnalyticsService.logEvent('routine_complete', {
        'mode': state.mode,
        'duration_sec': elapsed,
        'segments': state.segments.length,
      });
      await reset();
      await _clearPersistedState();
      return;
    }

    final nextIndex = state.currentSegmentIndex + 1;
    final nextSegment = state.segments[nextIndex];
    final remaining =
        nextSegment.duration.inSeconds + _remainingSecondsAfter(nextIndex + 1);

    state = state.copyWith(
      currentSegmentIndex: nextIndex,
      segmentRemainingSeconds: nextSegment.duration.inSeconds,
      remainingSeconds: remaining,
      isRunning: autoAdvance && state.isRunning,
      segmentStartedAt: autoAdvance ? DateTime.now() : null,
    );

    if (autoAdvance && state.isSoundEnabled) {
      await _audioService.updateProfile(nextSegment.playSoundProfile);
    } else if (!state.isRunning) {
      await _audioService.setEnabled(false);
    }

    if (state.isRunning) {
      _segmentEndAt = DateTime.now().add(
        Duration(seconds: state.segmentRemainingSeconds),
      );
      await _scheduleNotification(_segmentEndAt!, nextSegment);
      await _startTicker();
      await _startSleepSoundCaptureIfNeeded(nextSegment);
      final smartConfig = nextSegment.smartAlarm;
      final nextLabel = nextSegment.labelFor(l10n);
      final nextText = l10n.tr('foreground_notification_segment_remaining', {
        'segment': nextLabel,
        'time': _formatForegroundDuration(l10n, state.segmentRemainingSeconds),
      });
      await _foreground.update(
        title: l10n.tr('foreground_notification_running_title'),
        text: nextText,
        mode: state.mode,
        segmentLabel: nextLabel,
        segmentEndAt: _segmentEndAt!,
        smartWindowStart: smartConfig != null
            ? _segmentEndAt!.subtract(smartConfig.windowDuration)
            : null,
        smartInterval: smartConfig?.intervalDuration,
      );
      await _background.scheduleGuard();
    } else {
      await _foreground.stop();
      await _background.cancelGuard();
    }

    await _persistState();
  }

  Future<void> _startSleepSoundCaptureIfNeeded(TimerSegment segment) async {
    if (segment.type != 'sleep' || !segment.recordSession) {
      return;
    }
    _sleepSoundAnalyzer ??= SleepSoundAnalyzer();
    final started = await _sleepSoundAnalyzer!.start();
    if (started) {
      _sleepCaptureActive = true;
      if (Platform.isAndroid &&
          ref.read(sleepSoundFeatureEnabledProvider)) {
        await _foreground.setSleepSoundActive(
          active: true,
          startedAt: DateTime.now(),
        );
        _sleepForegroundActive = true;
      }
      await AnalyticsService.logEvent('sleep_sound_capture_started', {
        'segment_id': segment.id,
        'duration_target_sec': segment.duration.inSeconds,
      });
    }
  }

  Future<void> _finalizeSleepSoundCapture({required bool saveSummary}) async {
    if (_sleepSoundAnalyzer == null || !_sleepCaptureActive) {
      return;
    }
    try {
      final summary = await _sleepSoundAnalyzer!.stop();
      _sleepCaptureActive = false;
      await _stopSleepSoundForegroundIfNeeded();
      if (!saveSummary) {
        return;
      }
      await ref.read(saveSleepSoundSummaryProvider(summary).future);
      ref.invalidate(latestSleepSoundSummaryProvider);
      await AnalyticsService.logEvent('sleep_sound_capture_saved', {
        'duration_sec': summary.duration.inSeconds,
        'loud_events': summary.loudEventCount,
        'restful_ratio': summary.restfulSampleRatio,
      });
    } catch (error, stack) {
      debugPrint('SleepSoundAnalyzer finalize error: $error');
      await AnalyticsService.recordError(
        error,
        stack,
        reason: 'sleep_sound_finalize',
      );
      _sleepCaptureActive = false;
      await _stopSleepSoundForegroundIfNeeded();
    }
  }

  Future<void> _cancelSleepSoundCapture() async {
    if (_sleepSoundAnalyzer == null) {
      return;
    }
    if (_sleepCaptureActive) {
      try {
        await _sleepSoundAnalyzer!.stop();
      } catch (error) {
        debugPrint('SleepSoundAnalyzer cancel error: $error');
      }
      _sleepCaptureActive = false;
    }
    await _stopSleepSoundForegroundIfNeeded();
  }

  Future<void> _disposeSleepSoundAnalyzer() async {
    if (_sleepSoundAnalyzer == null) {
      return;
    }
    await _cancelSleepSoundCapture();
    await _sleepSoundAnalyzer!.dispose();
    _sleepSoundAnalyzer = null;
  }

  Future<void> _stopSleepSoundForegroundIfNeeded() async {
    if (!_sleepForegroundActive) {
      return;
    }
    if (Platform.isAndroid) {
      await _foreground.setSleepSoundActive(active: false);
    }
    _sleepForegroundActive = false;
  }

  Future<void> _recordSession(
    TimerSegment segment, {
    AppLocalizations? l10n,
  }) async {
    final settings = await ref.read(settingsFutureProvider.future);
    final now = DateTime.now();
    final localizations = l10n ?? await _localizations();
    final session = Session()
      ..type = segment.type
      ..startedAt = (state.segmentStartedAt ?? now)
      ..endedAt = now
      ..deviceId = settings.deviceId
      ..tags = []
      ..note = segment.labelFor(localizations);
    await ref.read(addSessionProvider(session).future);
  }

  void _recalculateRemaining() {
    if (_segmentEndAt == null) return;
    final now = DateTime.now();
    final segmentRemaining = (_segmentEndAt!.difference(now).inSeconds).clamp(
      0,
      state.segmentTotalSeconds,
    );
    final totalRemaining =
        segmentRemaining +
        _remainingSecondsAfter(state.currentSegmentIndex + 1);
    state = state.copyWith(
      segmentRemainingSeconds: segmentRemaining,
      remainingSeconds: totalRemaining,
    );
  }

  int _remainingSecondsAfter(int startIndex, {TimerPlan? plan}) {
    final segments = plan?.segments ?? state.segments;
    if (startIndex >= segments.length) return 0;
    var sum = 0;
    for (var i = startIndex; i < segments.length; i++) {
      sum += segments[i].duration.inSeconds;
    }
    return sum;
  }

  String _formatForegroundDuration(AppLocalizations l10n, int seconds) {
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

  Future<void> _scheduleNotification(
    DateTime endAt,
    TimerSegment segment,
  ) async {
    final l10n = await _localizations();
    final segmentLabel = segment.labelFor(l10n);
    final index = state.currentSegmentIndex;
    final baseId = _notificationIdBase + index * 10;

    final smartAlarm = segment.smartAlarm;
    if (smartAlarm != null) {
      final windowStart = endAt.subtract(smartAlarm.windowDuration);
      await _notifications.scheduleSmartSleepAlarmWindow(
        baseId: baseId,
        label: segmentLabel,
        windowStart: windowStart,
        targetTime: endAt,
        interval: smartAlarm.intervalDuration,
        includeFallbackExact: smartAlarm.fallbackExactAlarm,
      );
    } else {
      await _notifications.scheduleTimerEnd(
        id: baseId,
        title: l10n.tr('notification_timer_generic_title'),
        body: l10n.tr('notification_timer_segment_body', {
          'segment': segmentLabel,
        }),
        scheduledAt: endAt,
      );
    }
  }

  Future<void> _persistState() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final l10n = await _localizations();
    final data = {
      'mode': state.mode,
      'currentIndex': state.currentSegmentIndex,
      'remainingSeconds': state.remainingSeconds,
      'segmentRemaining': state.segmentRemainingSeconds,
      'isRunning': state.isRunning,
      'segments': state.segments
          .map(
            (s) => {
              'id': s.id,
              'duration': s.duration.inSeconds,
              'label': s.labelFor(l10n),
            },
          )
          .toList(),
      'sessionStartedAt': state.sessionStartedAt?.toIso8601String(),
      'segmentStartedAt': state.segmentStartedAt?.toIso8601String(),
      'isSoundEnabled': state.isSoundEnabled,
    };
    await prefs.setString(_prefsKey, jsonEncode(data));
  }

  Future<void> _clearPersistedState() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.remove(_prefsKey);
  }

  Future<void> _cancelScheduledNotifications({int? segmentCount}) async {
    var count = segmentCount ?? _currentPlan?.segments.length;
    if (count == null) {
      if (ref.mounted) {
        count = state.segments.length;
      } else {
        count = 0;
      }
    }
    await _notifications.cancelNotificationRange(
      _notificationIdBase,
      count * 10 + 10,
    );
    await _notifications.cancelTimerNotifications();
  }
}

final timerControllerProvider = NotifierProvider<TimerController, TimerState>(
  TimerController.new,
);
