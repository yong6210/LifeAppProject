import 'package:life_app/features/workout/workout_light_presets.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/models/settings.dart';

class TimerSegment {
  TimerSegment({
    required this.id,
    required this.type,
    required this.duration,
    this.label,
    this.localizationKey,
    this.localizationArgs,
    this.recordSession = true,
    this.playSoundProfile,
    this.autoStartNext = true,
    this.smartAlarm,
  });

  final String id;
  final String type;
  final Duration duration;
  final String? label;
  final String? localizationKey;
  final Map<String, String>? localizationArgs;
  final bool recordSession;
  final String? playSoundProfile;
  final bool autoStartNext;
  final SmartAlarmConfig? smartAlarm;

  String labelFor(AppLocalizations l10n) {
    if (localizationKey != null) {
      return l10n.tr(localizationKey!, localizationArgs);
    }
    return label ?? '';
  }
}

class SmartAlarmConfig {
  const SmartAlarmConfig({
    required this.windowMinutes,
    required this.intervalMinutes,
    this.fallbackExactAlarm = true,
  }) : assert(windowMinutes >= 0),
       assert(intervalMinutes > 0);

  final int windowMinutes;
  final int intervalMinutes;
  final bool fallbackExactAlarm;

  Duration get windowDuration => Duration(minutes: windowMinutes);
  Duration get intervalDuration => Duration(minutes: intervalMinutes);
}

class TimerPlan {
  TimerPlan({required this.mode, required this.segments});

  final String mode;
  final List<TimerSegment> segments;

  int get totalSeconds =>
      segments.fold(0, (sum, s) => sum + s.duration.inSeconds);

  TimerSegment get firstSegment => segments.first;
}

class TimerPlanFactory {
  static TimerPlan createPlan(String mode, Settings settings) {
    switch (mode) {
      case 'rest':
        return _buildRestPlan(settings);
      case 'workout':
        return _buildWorkoutPlan(settings);
      case 'sleep':
        return _buildSleepPlan(settings);
      case 'focus':
      default:
        return _buildFocusPlan(settings);
    }
  }

  static TimerPlan _buildFocusPlan(Settings settings) {
    final segments = <TimerSegment>[];
    const cycleCount = 4;
    for (var i = 0; i < cycleCount; i++) {
      final sessionNumber = i + 1;
      segments.add(
        TimerSegment(
          id: 'focus_$sessionNumber',
          type: 'focus',
          duration: Duration(minutes: settings.focusMinutes),
          label: 'Focus $sessionNumber',
          localizationKey: 'timer_plan_focus_segment_label',
          localizationArgs: {'number': '$sessionNumber'},
          playSoundProfile: 'focus',
        ),
      );
      if (sessionNumber < cycleCount) {
        final isLongBreak = sessionNumber % 2 == 0;
        final breakMinutes = isLongBreak
            ? settings.restMinutes * 2
            : settings.restMinutes;
        segments.add(
          TimerSegment(
            id: 'break_$sessionNumber',
            type: 'rest',
            duration: Duration(minutes: breakMinutes),
            label: isLongBreak ? 'Long break' : 'Short break',
            localizationKey: isLongBreak
                ? 'timer_plan_focus_long_break_label'
                : 'timer_plan_focus_short_break_label',
            recordSession: false,
            playSoundProfile: 'rest',
          ),
        );
      }
    }
    return TimerPlan(mode: 'focus', segments: segments);
  }

  static TimerPlan _buildRestPlan(Settings settings) {
    final segments = <TimerSegment>[
      TimerSegment(
        id: 'rest_intro',
        type: 'rest',
        duration: const Duration(minutes: 2),
        label: 'Stretch',
        localizationKey: 'timer_plan_rest_stretch_label',
        recordSession: false,
        playSoundProfile: 'rest',
      ),
      TimerSegment(
        id: 'rest_breath',
        type: 'rest',
        duration: Duration(minutes: settings.restMinutes),
        label: 'Breathing',
        localizationKey: 'timer_plan_rest_breath_label',
        recordSession: false,
        playSoundProfile: 'breath',
      ),
      TimerSegment(
        id: 'rest_focus',
        type: 'rest',
        duration: const Duration(minutes: 2),
        label: 'Reset',
        localizationKey: 'timer_plan_rest_reflect_label',
        recordSession: false,
        playSoundProfile: 'calm',
      ),
    ];
    return TimerPlan(mode: 'rest', segments: segments);
  }

  static TimerPlan _buildWorkoutPlan(Settings settings) {
    final totalSecondsTarget = (settings.workoutMinutes * 60).clamp(60, 3600);
    const activeSeconds = 45;
    const restSeconds = 15;
    final cycleSeconds = activeSeconds + restSeconds;
    var rounds = (totalSecondsTarget / cycleSeconds).round();
    if (rounds < 1) rounds = 1;
    if (rounds > 20) rounds = 20;
    final segments = <TimerSegment>[];
    for (var round = 0; round < rounds; round++) {
      final idx = round + 1;
      segments.add(
        TimerSegment(
          id: 'workout_active_$idx',
          type: 'workout',
          duration: const Duration(seconds: activeSeconds),
          label: 'Round $idx',
          localizationKey: 'timer_plan_workout_active_label',
          localizationArgs: {'number': '$idx'},
          playSoundProfile: 'workout',
        ),
      );
      if (idx < rounds) {
        segments.add(
          TimerSegment(
            id: 'workout_rest_$idx',
            type: 'rest',
            duration: const Duration(seconds: restSeconds),
            label: 'Rest',
            localizationKey: 'timer_plan_workout_rest_label',
            recordSession: false,
            playSoundProfile: 'rest',
          ),
        );
      }
    }
    return TimerPlan(mode: 'workout', segments: segments);
  }

  static TimerPlan _buildSleepPlan(Settings settings) {
    final windowMinutes = settings.sleepSmartAlarmWindowMinutes
        .clamp(0, 120)
        .toInt();
    final intervalMinutes = settings.sleepSmartAlarmIntervalMinutes
        .clamp(1, 15)
        .toInt();
    final smartAlarm = windowMinutes > 0
        ? SmartAlarmConfig(
            windowMinutes: windowMinutes,
            intervalMinutes: intervalMinutes,
            fallbackExactAlarm: settings.sleepSmartAlarmExactFallback,
          )
        : null;
    final segments = <TimerSegment>[
      TimerSegment(
        id: 'sleep_prepare',
        type: 'sleep',
        duration: const Duration(minutes: 5),
        label: 'Wind down',
        localizationKey: 'timer_plan_sleep_prepare_label',
        recordSession: false,
        playSoundProfile: 'sleep_prepare',
      ),
      TimerSegment(
        id: 'sleep_relax',
        type: 'sleep',
        duration: const Duration(minutes: 10),
        label: 'Relax',
        localizationKey: 'timer_plan_sleep_relax_label',
        recordSession: false,
        playSoundProfile: 'sleep_relax',
      ),
      TimerSegment(
        id: 'sleep_main',
        type: 'sleep',
        duration: Duration(minutes: settings.sleepMinutes),
        label: 'Sleep',
        localizationKey: 'timer_plan_sleep_main_label',
        playSoundProfile: 'sleep',
        smartAlarm: smartAlarm,
      ),
    ];
    return TimerPlan(mode: 'sleep', segments: segments);
  }

  static TimerPlan createWorkoutLightPlan(WorkoutLightPreset preset) {
    return TimerPlan(
      mode: 'workout',
      segments: _segmentsForWorkoutPreset(preset),
    );
  }

  static List<TimerSegment> _segmentsForWorkoutPreset(
    WorkoutLightPreset preset,
  ) {
    switch (preset.id) {
      case 'run_light':
        return _runLightSegments();
      case 'run_moderate':
        return _runModerateSegments();
      case 'run_vigorous':
        return _runVigorousSegments();
      case 'ride_light':
        return _rideLightSegments();
      case 'ride_moderate':
        return _rideModerateSegments();
      case 'ride_vigorous':
        return _rideVigorousSegments();
      default:
        throw ArgumentError.value(
          preset.id,
          'preset',
          'Unknown workout preset',
        );
    }
  }

  static List<TimerSegment> _runLightSegments() {
    const rounds = 4;
    final segments = <TimerSegment>[];
    for (var round = 1; round <= rounds; round++) {
      segments.add(
        TimerSegment(
          id: 'run_light_active_$round',
          type: 'workout',
          duration: const Duration(minutes: 3),
          localizationKey: 'timer_workout_light_segment_run_interval',
          localizationArgs: {'number': '$round'},
          playSoundProfile: 'workout',
        ),
      );
      if (round < rounds) {
        segments.add(
          TimerSegment(
            id: 'run_light_recover_$round',
            type: 'rest',
            duration: const Duration(minutes: 1),
            localizationKey: 'timer_workout_light_segment_run_recovery',
            localizationArgs: {'number': '$round'},
            recordSession: false,
            playSoundProfile: 'rest',
          ),
        );
      }
    }
    return segments;
  }

  static List<TimerSegment> _runModerateSegments() {
    const rounds = 4;
    final segments = <TimerSegment>[
      TimerSegment(
        id: 'run_moderate_warmup',
        type: 'workout',
        duration: const Duration(minutes: 3),
        localizationKey: 'timer_workout_light_segment_warmup',
        recordSession: false,
        playSoundProfile: 'workout',
      ),
    ];
    for (var round = 1; round <= rounds; round++) {
      segments.add(
        TimerSegment(
          id: 'run_moderate_active_$round',
          type: 'workout',
          duration: const Duration(minutes: 4),
          localizationKey: 'timer_workout_light_segment_run_interval',
          localizationArgs: {'number': '$round'},
          playSoundProfile: 'workout',
        ),
      );
      if (round < rounds) {
        segments.add(
          TimerSegment(
            id: 'run_moderate_recover_$round',
            type: 'rest',
            duration: const Duration(minutes: 1),
            localizationKey: 'timer_workout_light_segment_run_recovery',
            localizationArgs: {'number': '$round'},
            recordSession: false,
            playSoundProfile: 'rest',
          ),
        );
      }
    }
    segments.add(
      TimerSegment(
        id: 'run_moderate_cooldown',
        type: 'rest',
        duration: const Duration(minutes: 2),
        localizationKey: 'timer_workout_light_segment_cooldown',
        recordSession: false,
        playSoundProfile: 'calm',
      ),
    );
    return segments;
  }

  static List<TimerSegment> _runVigorousSegments() {
    const rounds = 6;
    final segments = <TimerSegment>[
      TimerSegment(
        id: 'run_vigorous_warmup',
        type: 'workout',
        duration: const Duration(minutes: 2),
        localizationKey: 'timer_workout_light_segment_warmup',
        recordSession: false,
        playSoundProfile: 'workout',
      ),
    ];
    for (var round = 1; round <= rounds; round++) {
      segments.add(
        TimerSegment(
          id: 'run_vigorous_active_$round',
          type: 'workout',
          duration: const Duration(minutes: 2),
          localizationKey: 'timer_workout_light_segment_run_interval',
          localizationArgs: {'number': '$round'},
          playSoundProfile: 'workout',
        ),
      );
      if (round < rounds) {
        segments.add(
          TimerSegment(
            id: 'run_vigorous_recover_$round',
            type: 'rest',
            duration: const Duration(minutes: 1),
            localizationKey: 'timer_workout_light_segment_run_recovery',
            localizationArgs: {'number': '$round'},
            recordSession: false,
            playSoundProfile: 'rest',
          ),
        );
      }
    }
    segments.add(
      TimerSegment(
        id: 'run_vigorous_cooldown',
        type: 'rest',
        duration: const Duration(minutes: 3),
        localizationKey: 'timer_workout_light_segment_cooldown',
        recordSession: false,
        playSoundProfile: 'calm',
      ),
    );
    return segments;
  }

  static List<TimerSegment> _rideLightSegments() {
    const rounds = 3;
    final segments = <TimerSegment>[
      TimerSegment(
        id: 'ride_light_warmup',
        type: 'workout',
        duration: const Duration(minutes: 3),
        localizationKey: 'timer_workout_light_segment_warmup',
        recordSession: false,
        playSoundProfile: 'workout',
      ),
    ];
    for (var round = 1; round <= rounds; round++) {
      segments.add(
        TimerSegment(
          id: 'ride_light_block_$round',
          type: 'workout',
          duration: const Duration(minutes: 5),
          localizationKey: 'timer_workout_light_segment_ride_block',
          localizationArgs: {'number': '$round'},
          playSoundProfile: 'workout',
        ),
      );
      if (round < rounds) {
        segments.add(
          TimerSegment(
            id: 'ride_light_recover_$round',
            type: 'rest',
            duration: const Duration(minutes: 2),
            localizationKey: 'timer_workout_light_segment_ride_recovery',
            localizationArgs: {'number': '$round'},
            recordSession: false,
            playSoundProfile: 'rest',
          ),
        );
      }
    }
    segments.add(
      TimerSegment(
        id: 'ride_light_cooldown',
        type: 'rest',
        duration: const Duration(minutes: 5),
        localizationKey: 'timer_workout_light_segment_cooldown',
        recordSession: false,
        playSoundProfile: 'calm',
      ),
    );
    return segments;
  }

  static List<TimerSegment> _rideModerateSegments() {
    const rounds = 3;
    final segments = <TimerSegment>[
      TimerSegment(
        id: 'ride_moderate_warmup',
        type: 'workout',
        duration: const Duration(minutes: 4),
        localizationKey: 'timer_workout_light_segment_warmup',
        recordSession: false,
        playSoundProfile: 'workout',
      ),
    ];
    for (var round = 1; round <= rounds; round++) {
      segments.add(
        TimerSegment(
          id: 'ride_moderate_block_$round',
          type: 'workout',
          duration: const Duration(minutes: 6),
          localizationKey: 'timer_workout_light_segment_ride_block',
          localizationArgs: {'number': '$round'},
          playSoundProfile: 'workout',
        ),
      );
      if (round < rounds) {
        segments.add(
          TimerSegment(
            id: 'ride_moderate_recover_$round',
            type: 'rest',
            duration: const Duration(minutes: 2),
            localizationKey: 'timer_workout_light_segment_ride_recovery',
            localizationArgs: {'number': '$round'},
            recordSession: false,
            playSoundProfile: 'rest',
          ),
        );
      }
    }
    segments.add(
      TimerSegment(
        id: 'ride_moderate_cooldown',
        type: 'rest',
        duration: const Duration(minutes: 6),
        localizationKey: 'timer_workout_light_segment_cooldown',
        recordSession: false,
        playSoundProfile: 'calm',
      ),
    );
    return segments;
  }

  static List<TimerSegment> _rideVigorousSegments() {
    const rounds = 6;
    final segments = <TimerSegment>[
      TimerSegment(
        id: 'ride_vigorous_warmup',
        type: 'workout',
        duration: const Duration(minutes: 5),
        localizationKey: 'timer_workout_light_segment_warmup',
        recordSession: false,
        playSoundProfile: 'workout',
      ),
    ];
    for (var round = 1; round <= rounds; round++) {
      segments.add(
        TimerSegment(
          id: 'ride_vigorous_block_$round',
          type: 'workout',
          duration: const Duration(minutes: 3),
          localizationKey: 'timer_workout_light_segment_ride_block',
          localizationArgs: {'number': '$round'},
          playSoundProfile: 'workout',
        ),
      );
      if (round < rounds) {
        segments.add(
          TimerSegment(
            id: 'ride_vigorous_recover_$round',
            type: 'rest',
            duration: const Duration(minutes: 1),
            localizationKey: 'timer_workout_light_segment_ride_recovery',
            localizationArgs: {'number': '$round'},
            recordSession: false,
            playSoundProfile: 'rest',
          ),
        );
      }
    }
    segments.add(
      TimerSegment(
        id: 'ride_vigorous_cooldown',
        type: 'rest',
        duration: const Duration(minutes: 3),
        localizationKey: 'timer_workout_light_segment_cooldown',
        recordSession: false,
        playSoundProfile: 'calm',
      ),
    );
    return segments;
  }
}
