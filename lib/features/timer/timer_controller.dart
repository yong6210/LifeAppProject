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
import 'package:life_app/models/routine.dart';
import 'package:life_app/models/session.dart';
import 'package:life_app/models/settings.dart';
import 'package:life_app/providers/session_providers.dart';
import 'package:life_app/providers/settings_providers.dart';
import 'package:life_app/providers/feature_flags.dart';
import 'package:life_app/services/analytics/analytics_service.dart';
import 'package:life_app/providers/accessibility_providers.dart';
import 'package:life_app/services/audio/sleep_sound_catalog.dart';
import 'package:life_app/services/audio/sleep_sound_analyzer.dart';
import 'package:life_app/services/audio/workout_cue_service.dart';
import 'package:life_app/providers/sleep_analysis_providers.dart';
import 'package:life_app/services/audio/timer_audio_service.dart';
import 'package:life_app/providers/diagnostics_providers.dart';
import 'package:life_app/services/diagnostics/timer_diagnostics_service.dart';
import 'package:life_app/features/workout/models/workout_navigator_models.dart';
import 'package:life_app/features/workout/workout_light_presets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NavigatorCueTrigger {
  _NavigatorCueTrigger({required this.offsetSeconds, required this.message});

  final int offsetSeconds;
  final String message;
  bool triggered = false;
}

class TimerController extends Notifier<TimerState> {
  Timer? _ticker;
  DateTime? _segmentEndAt;
  TimerPlan? _currentPlan;
  late TimerAudioEngine _audioService;
  late TimerNotificationBridge _notifications;
  late TimerForegroundBridge _foreground;
  late TimerBackgroundBridge _background;
  late WorkoutCueService _workoutCues;
  late TimerDependencies _deps;
  bool _allowHaptics = true;
  SharedPreferences? _prefs;
  String? _workoutPresetId;
  SleepSoundAnalyzer? _sleepSoundAnalyzer;
  bool _sleepCaptureActive = false;
  bool _sleepForegroundActive = false;
  WorkoutNavigatorRoute? _navigatorRoute;
  WorkoutNavigatorTarget? _navigatorTarget;
  final List<_NavigatorCueTrigger> _navigatorCueTriggers = [];
  bool _navigatorVoiceEnabled = true;
  int _navigatorChecklistCheckedCount = 0;

  static const _prefsKey = 'timer_state_v2';
  static const _prefsWorkoutPresetKey = 'workout_light_preset_id';
  static const _notificationIdBase = 4200;

  Future<AppLocalizations> _localizations() => loadAppLocalizations();

  @override
  TimerState build() {
    _deps = ref.read(timerDependenciesProvider);
    _audioService = _deps.audio;
    _notifications = _deps.notifications;
    _foreground = _deps.foreground;
    _background = _deps.background;
    _workoutCues = _deps.workoutCues;
    _allowHaptics = !ref.read(reducedMotionProvider);
    ref.listen<bool>(reducedMotionProvider, (previous, next) {
      _allowHaptics = !next;
    });
    final defaultPlan = TimerPlanFactory.createPlan('focus', Settings());
    state = TimerState.idle(plan: defaultPlan, workoutPresetId: null);

    unawaited(_foreground.ensureInitialized());
    Future.microtask(() async {
      await _foreground.ensureInitialized();
      try {
        final prefs = await SharedPreferences.getInstance();
        _prefs = prefs;
        _workoutPresetId =
            prefs.getString(_prefsWorkoutPresetKey) ?? _workoutPresetId;
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
      await _workoutCues.dispose();
    });

    return state;
  }

  void _clearNavigatorContext() {
    if (_navigatorRoute == null &&
        _navigatorTarget == null &&
        _navigatorCueTriggers.isEmpty) {
      return;
    }
    _navigatorRoute = null;
    _navigatorTarget = null;
    _navigatorCueTriggers.clear();
    _navigatorVoiceEnabled = true;
    _navigatorChecklistCheckedCount = 0;
    state = state.copyWith(
      navigatorRoute: null,
      navigatorTarget: null,
      navigatorVoiceEnabled: true,
      navigatorLastCueMessage: null,
      navigatorLastCueAt: null,
    );
  }

  Future<void> selectMode(String mode) async {
    await _loadPlanAndRestore(mode: mode, forceReset: true);
  }

  Future<void> setPreset(String mode, int minutes) async {
    // Update settings based on mode
    final settingsRepo = await ref.read(settingsRepoProvider.future);

    switch (mode) {
      case 'focus':
        await settingsRepo.updateFocusMinutes(minutes);
        break;
      case 'rest':
        await settingsRepo.updateRestMinutes(minutes);
        break;
      case 'workout':
        await settingsRepo.updateWorkoutMinutes(minutes);
        break;
      case 'sleep':
        // Sleep doesn't use timer presets in the same way
        break;
    }

    // Invalidate settings and reload plan with new settings
    ref.invalidate(settingsFutureProvider);
    await selectMode(mode);
  }

  Future<void> startWorkoutLightPreset(String presetId) async {
    final preset = _findWorkoutPreset(presetId);
    if (preset == null) {
      await selectMode('workout');
      return;
    }

    final soundEnabled = state.isSoundEnabled;
    final plan = TimerPlanFactory.createWorkoutLightPlan(preset);
    _currentPlan = plan;
    _clearNavigatorContext();
    await _setWorkoutPreset(preset.id);
    unawaited(
      ref
          .read(settingsMutationControllerProvider.notifier)
          .saveLastMode('workout'),
    );

    state = TimerState.idle(
      plan: plan,
      soundEnabled: soundEnabled,
      workoutPresetId: preset.id,
    );
    await _audioService.setEnabled(false);
    await _foreground.stop();
    await _background.cancelGuard();
    await _persistState();
  }

  Future<bool> startCustomRoutine({
    required Routine routine,
    bool autoStart = false,
  }) async {
    final plan = TimerPlanFactory.createRoutinePlan(routine);
    if (plan == null) {
      return false;
    }
    await _cancelScheduledNotifications();
    await _stopTicker();
    await _audioService.setEnabled(false);
    await _background.cancelGuard();
    await _cancelSleepSoundCapture();
    await _foreground.stop();

    _currentPlan = plan;
    _clearNavigatorContext();

    state = TimerState.idle(plan: plan, soundEnabled: state.isSoundEnabled);
    await _persistState();

    if (autoStart && !state.isRunning) {
      await _start();
    }
    return true;
  }

  Future<void> startNavigatorWorkout({
    required WorkoutNavigatorRoute route,
    required WorkoutNavigatorTarget target,
    required bool voiceGuidanceEnabled,
    required int checklistCheckedCount,
  }) async {
    final soundEnabled = state.isSoundEnabled;
    await _cancelScheduledNotifications();
    await _stopTicker();
    await _audioService.setEnabled(false);
    await _background.cancelGuard();
    await _cancelSleepSoundCapture();
    await _foreground.stop();

    _navigatorRoute = route;
    _navigatorTarget = target;
    _navigatorCueTriggers
      ..clear()
      ..addAll(
        route.voiceCues
            .map(
              (cue) => _NavigatorCueTrigger(
                offsetSeconds: cue.offset.inSeconds.clamp(0, 24 * 3600).toInt(),
                message: cue.message,
              ),
            )
            .toList()
          ..sort((a, b) => a.offsetSeconds.compareTo(b.offsetSeconds)),
      );
    _navigatorVoiceEnabled = voiceGuidanceEnabled;
    _navigatorChecklistCheckedCount = checklistCheckedCount;

    final plan = _buildNavigatorPlan(route);
    _currentPlan = plan;
    state = TimerState.idle(
      plan: plan,
      soundEnabled: soundEnabled,
      navigatorRoute: route,
      navigatorTarget: target,
      navigatorVoiceEnabled: voiceGuidanceEnabled,
      navigatorLastSummary: null,
      workoutPresetId: null,
    );

    await AnalyticsService.logEvent('workout_navigator_start_session', {
      'route_id': route.id,
      'target_type': target.type.name,
      'target_value': target.value,
      'voice_guidance_enabled': voiceGuidanceEnabled,
      'checklist_checked_count': checklistCheckedCount,
    });

    await _persistState();
    await _start();
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
    _clearNavigatorContext();
    final previousPresetId = state.workoutPresetId;
    final plan =
        _currentPlan ?? TimerPlanFactory.createPlan(state.mode, Settings());
    state = TimerState.idle(
      plan: plan,
      soundEnabled: state.isSoundEnabled,
      workoutPresetId: previousPresetId,
    );
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
    await AnalyticsService.logEvent('segment_skip', {
      'mode': state.mode,
      'navigator_route_id': _navigatorRoute?.id,
    });
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
      'navigator_route_id': _navigatorRoute?.id,
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
    final persistedState = forceReset ? null : await _readPersistedStateMap();
    final resolution = _resolvePlan(
      mode: mode,
      settings: settings,
      persistedState: persistedState,
    );
    final plan = resolution.plan;
    final presetId = resolution.presetId;
    _currentPlan = plan;
    _clearNavigatorContext();

    final restored = forceReset
        ? false
        : await _restoreState(plan, persistedState);
    if (!restored) {
      state = TimerState.idle(
        plan: plan,
        soundEnabled: state.isSoundEnabled,
        workoutPresetId: presetId,
      );
      await _foreground.stop();
      await _background.cancelGuard();
      await _persistState();
    }
  }

  Future<Map<String, dynamic>?> _readPersistedStateMap() async {
    final prefs = _prefs;
    if (prefs == null) return null;
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  ({TimerPlan plan, String? presetId}) _resolvePlan({
    required String mode,
    required Settings settings,
    Map<String, dynamic>? persistedState,
  }) {
    if (mode == 'custom_routine') {
      final customPlan = persistedState?['customPlan'];
      if (customPlan is Map<String, dynamic>) {
        final rawSegments = customPlan['segments'];
        if (rawSegments is List) {
          final segments = rawSegments
              .map<Map<String, dynamic>>(
                (item) => Map<String, dynamic>.from(item as Map),
              )
              .toList();
          final plan = TimerPlanFactory.planFromSerializedSegments(
            segments,
            mode: 'custom_routine',
          );
          if (plan != null) {
            return (plan: plan, presetId: null);
          }
        }
      }
    }
    if (mode == 'workout') {
      final hasPersistedKey =
          persistedState?.containsKey('workoutPresetId') ?? false;
      final storedPreset = persistedState?['workoutPresetId'];
      final candidateId = hasPersistedKey
          ? storedPreset as String?
          : _workoutPresetId;
      final preset = _findWorkoutPreset(candidateId);
      if (preset != null) {
        _workoutPresetId = preset.id;
        return (
          plan: TimerPlanFactory.createWorkoutLightPlan(preset),
          presetId: preset.id,
        );
      }
    }
    return (plan: TimerPlanFactory.createPlan(mode, settings), presetId: null);
  }

  Future<bool> _restoreState(
    TimerPlan plan,
    Map<String, dynamic>? persistedState,
  ) async {
    var map = persistedState;
    map ??= await _readPersistedStateMap();
    if (map == null) {
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

    final storedPresetId = map['workoutPresetId'];
    final workoutPresetId =
        storedPresetId is String && storedPresetId.isNotEmpty
        ? storedPresetId
        : null;
    if (workoutPresetId != null) {
      _workoutPresetId = workoutPresetId;
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

    final navigatorVoiceEnabled = map['navigatorVoiceEnabled'] as bool? ?? true;

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
      navigatorRoute: null,
      navigatorTarget: null,
      navigatorVoiceEnabled: navigatorVoiceEnabled,
      workoutPresetId: workoutPresetId,
    );

    final lastCueMessage = map['navigatorLastCueMessage'] as String?;
    final lastCueAtRaw = map['navigatorLastCueAt'] as String?;
    final lastCueAt = lastCueAtRaw != null
        ? DateTime.tryParse(lastCueAtRaw)
        : null;
    if (lastCueMessage != null) {
      state = state.copyWith(
        navigatorLastCueMessage: lastCueMessage,
        navigatorLastCueAt: lastCueAt,
      );
    }

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
    if (state.mode == 'workout') {
      await _maybeSpeakWorkoutCue(state.currentSegment, l10n);
    }

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
      'navigator_route_id': _navigatorRoute?.id,
      'navigator_target_type': _navigatorTarget?.type.name,
      'navigator_target_value': _navigatorTarget?.value,
      'navigator_voice_enabled': _navigatorVoiceEnabled,
      'navigator_checklist_checked_count': _navigatorChecklistCheckedCount,
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
      'navigator_route_id': _navigatorRoute?.id,
      'navigator_voice_enabled': _navigatorVoiceEnabled,
      'navigator_checklist_checked_count': _navigatorChecklistCheckedCount,
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

    if (_navigatorRoute != null) {
      _processNavigatorCues(now);
    }

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
      'navigator_route_id': _navigatorRoute?.id,
      'navigator_voice_enabled': _navigatorVoiceEnabled,
    });

    if (state.isLastSegment) {
      if (state.mode == 'workout') {
        await _workoutCues.speakComplete(l10n: l10n);
      }
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
        'navigator_route_id': _navigatorRoute?.id,
        'navigator_target_type': _navigatorTarget?.type.name,
        'navigator_target_value': _navigatorTarget?.value,
        'navigator_voice_enabled': _navigatorVoiceEnabled,
        'navigator_checklist_checked_count': _navigatorChecklistCheckedCount,
      });
      await AnalyticsService.logEvent('routine_complete', {
        'mode': state.mode,
        'duration_sec': elapsed,
        'segments': state.segments.length,
        'navigator_route_id': _navigatorRoute?.id,
        'navigator_voice_enabled': _navigatorVoiceEnabled,
        'navigator_checklist_checked_count': _navigatorChecklistCheckedCount,
      });
      NavigatorCompletionSummary? summary;
      if (_navigatorRoute != null) {
        summary = NavigatorCompletionSummary(
          routeId: _navigatorRoute!.id,
          completedAt: now,
          elapsedSeconds: elapsed,
          targetType: _navigatorTarget?.type,
          targetValue: _navigatorTarget?.value,
          voiceGuidanceEnabled: _navigatorVoiceEnabled,
          checklistCheckedCount: _navigatorChecklistCheckedCount,
        );
      }
      await reset();
      if (summary != null) {
        state = state.copyWith(
          navigatorLastSummary: summary,
          navigatorLastCueMessage: null,
          navigatorLastCueAt: null,
        );
      }
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

    if (state.mode == 'workout') {
      await _maybeSpeakWorkoutCue(nextSegment, l10n);
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

  Future<void> _maybeSpeakWorkoutCue(
    TimerSegment segment,
    AppLocalizations l10n,
  ) async {
    if (state.mode != 'workout' || _navigatorRoute != null) {
      return;
    }
    final round = _workoutRoundFromSegment(segment);
    if (round == null) {
      return;
    }
    final totalRounds = _workoutRoundTotal();
    if (totalRounds == 0) {
      return;
    }
    if (segment.type == 'workout') {
      await _workoutCues.speakRoundStart(
        l10n: l10n,
        round: round,
        totalRounds: totalRounds,
      );
    } else if (segment.type == 'rest') {
      await _workoutCues.speakRest(
        l10n: l10n,
        seconds: segment.duration.inSeconds,
      );
    }
  }

  int? _workoutRoundFromSegment(TimerSegment segment) {
    if (!segment.id.startsWith('workout_')) {
      return null;
    }
    final parts = segment.id.split('_');
    if (parts.length < 3) {
      return null;
    }
    return int.tryParse(parts.last);
  }

  int _workoutRoundTotal() {
    return state.segments
        .where((segment) => segment.id.startsWith('workout_active_'))
        .length;
  }

  Future<void> _startSleepSoundCaptureIfNeeded(TimerSegment segment) async {
    if (segment.type != 'sleep' || !segment.recordSession) {
      return;
    }
    _sleepSoundAnalyzer ??= SleepSoundAnalyzer();
    final started = await _sleepSoundAnalyzer!.start();
    if (started) {
      _sleepCaptureActive = true;
      if (Platform.isAndroid && ref.read(sleepSoundFeatureEnabledProvider)) {
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
    if (segment.type == 'workout' && state.navigatorRoute != null) {
      session.navigatorRouteId = state.navigatorRoute!.id;
      session.navigatorTargetType = state.navigatorTarget?.type.name;
      session.navigatorTargetValue = state.navigatorTarget?.value;
      session.navigatorVoiceEnabled = state.navigatorVoiceEnabled;
    }
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

  Future<void> _setWorkoutPreset(String? presetId) async {
    _workoutPresetId = presetId;
    SharedPreferences? prefs = _prefs;
    if (prefs == null) {
      try {
        prefs = await SharedPreferences.getInstance();
        _prefs = prefs;
      } catch (_) {
        return;
      }
    }
    if (presetId == null || presetId.isEmpty) {
      await prefs.remove(_prefsWorkoutPresetKey);
    } else {
      await prefs.setString(_prefsWorkoutPresetKey, presetId);
    }
  }

  WorkoutLightPreset? _findWorkoutPreset(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final preset in workoutLightPresets) {
      if (preset.id == id) {
        return preset;
      }
    }
    return null;
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
      'navigatorRouteId': state.navigatorRoute?.id,
      'navigatorVoiceEnabled': state.navigatorVoiceEnabled,
      'navigatorLastCueMessage': state.navigatorLastCueMessage,
      'navigatorLastCueAt': state.navigatorLastCueAt?.toIso8601String(),
      'workoutPresetId': state.workoutPresetId,
    };
    if (state.mode == 'custom_routine') {
      data['customPlan'] = {
        'segments': state.segments
            .map(TimerPlanFactory.serializeSegment)
            .toList(),
      };
    }
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
      count = state.segments.length;
    }
    await _notifications.cancelNotificationRange(
      _notificationIdBase,
      count * 10 + 10,
    );
    await _notifications.cancelTimerNotifications();
  }

  TimerPlan _buildNavigatorPlan(WorkoutNavigatorRoute route) {
    final navigatorSegments = <TimerSegment>[];
    if (route.segments.isNotEmpty) {
      for (var i = 0; i < route.segments.length; i++) {
        final segment = route.segments[i];
        final duration = segment.endOffset - segment.startOffset;
        if (duration <= Duration.zero) continue;
        navigatorSegments.add(
          TimerSegment(
            id: '${route.id}_segment_${i + 1}',
            type: 'workout',
            duration: duration,
            label: segment.focus,
            playSoundProfile: 'workout',
          ),
        );
      }
    }

    if (navigatorSegments.isEmpty) {
      final minutes = route.estimatedMinutes > 1
          ? route.estimatedMinutes.round()
          : 20;
      navigatorSegments.add(
        TimerSegment(
          id: '${route.id}_main',
          type: 'workout',
          duration: Duration(minutes: minutes),
          label: route.title,
          playSoundProfile: 'workout',
        ),
      );
    }

    return TimerPlan(mode: 'workout', segments: navigatorSegments);
  }

  void _processNavigatorCues(DateTime now) {
    if (_navigatorRoute == null) return;
    if (!_navigatorVoiceEnabled) return;
    final startedAt = state.sessionStartedAt;
    if (startedAt == null) return;
    final elapsed = now.difference(startedAt).inSeconds;
    for (final cue in _navigatorCueTriggers) {
      if (cue.triggered) continue;
      if (elapsed >= cue.offsetSeconds) {
        cue.triggered = true;
        unawaited(_workoutCues.speakNavigatorCue(cue.message));
        unawaited(
          AnalyticsService.logEvent('workout_navigator_voice_cue', {
            'route_id': _navigatorRoute?.id,
            'offset_sec': cue.offsetSeconds,
          }),
        );
        state = state.copyWith(
          navigatorLastCueMessage: cue.message,
          navigatorLastCueAt: DateTime.now(),
        );
      }
    }
  }
}

final timerControllerProvider = NotifierProvider<TimerController, TimerState>(
  TimerController.new,
);
