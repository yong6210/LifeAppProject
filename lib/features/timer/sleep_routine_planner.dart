import 'dart:math';

import 'package:life_app/features/timer/sleep_routine_models.dart';
import 'package:life_app/models/settings.dart';

class SleepRoutinePlanner {
  SleepRoutinePlan build({
    required SleepGoal goal,
    required SleepIntent intent,
    required Settings settings,
    DateTime? now,
    DailyUsageContext? usage,
  }) {
    final current = now ?? DateTime.now();
    final resolvedWake = intent.isWakeTime
        ? _resolveWakeTime(intent.wakeTime!, current)
        : current.add(const Duration(minutes: 5));
    final resolvedDuration = _resolveTargetDuration(
      goal,
      intent,
      current,
      resolvedWake,
      usage,
    );
    final bedTime = intent.isWakeTime
        ? resolvedWake.subtract(resolvedDuration)
        : current;
    final wakeTime = intent.isWakeTime
        ? resolvedWake
        : bedTime.add(resolvedDuration);

    final baseTemplate = _segmentTemplateFor(goal);
    final tunedTemplate = usage == null
        ? baseTemplate
        : _applyUsageToTemplate(baseTemplate, usage, goal);
    final segments = _buildSegments(goal, resolvedDuration, settings, tunedTemplate);
    final blend = _audioBlendFor(goal, usage);

    return SleepRoutinePlan(
      goal: goal,
      intent: intent,
      recommendedBedTime: bedTime,
      recommendedWakeTime: wakeTime,
      segments: segments,
      audioBlend: blend,
      totalDuration: resolvedDuration,
    );
  }

  Duration minimumDurationForGoal(SleepGoal goal) =>
      _minimumTotalDuration(goal);

  Duration maximumDurationForGoal(SleepGoal goal) =>
      _maximumTotalDuration(goal);

  DateTime _resolveWakeTime(DateTime rawWakeTime, DateTime now) {
    var wake = rawWakeTime;
    // Interpret target as future time; roll forward if needed.
    while (!wake.isAfter(now)) {
      wake = wake.add(const Duration(days: 1));
    }
    return wake;
  }

  Duration _resolveTargetDuration(
    SleepGoal goal,
    SleepIntent intent,
    DateTime now,
    DateTime resolvedWake,
    DailyUsageContext? usage,
  ) {
    final minTotal = _minimumTotalDuration(goal);
    final maxTotal = _maximumTotalDuration(goal);

    Duration desired;
    if (intent.isDuration && intent.duration != null) {
      desired = intent.duration!;
    } else {
      desired = resolvedWake.difference(now);
    }

    if (desired <= Duration.zero) {
      desired = minTotal;
    }
    if (desired < minTotal) {
      desired = minTotal;
    }
    if (desired > maxTotal) {
      desired = maxTotal;
    }
    if (usage != null) {
      final additional = usage.recommendedAdditionalDuration(goal);
      if (additional > Duration.zero) {
        final candidate = desired + additional;
        if (candidate > maxTotal) {
          desired = maxTotal;
        } else {
          desired = candidate;
        }
      }
    }
    return desired;
  }

  Duration _minimumTotalDuration(SleepGoal goal) {
    switch (goal) {
      case SleepGoal.rest:
        return const Duration(minutes: 20);
      case SleepGoal.standard:
        return const Duration(hours: 4, minutes: 15);
      case SleepGoal.recovery:
        return const Duration(hours: 5, minutes: 21);
    }
  }

  Duration _maximumTotalDuration(SleepGoal goal) {
    switch (goal) {
      case SleepGoal.rest:
        return const Duration(minutes: 90);
      case SleepGoal.standard:
        return const Duration(hours: 9);
      case SleepGoal.recovery:
        return const Duration(hours: 10);
    }
  }

  List<SleepRoutineSegmentPlan> _buildSegments(
    SleepGoal goal,
    Duration totalDuration,
    Settings settings,
    _SegmentTemplate template,
  ) {
    final adjusted = _adjustDurations(totalDuration, template);

    final smartAlarmEnabled = settings.sleepSmartAlarmWindowMinutes > 0;

    return [
      SleepRoutineSegmentPlan(
        id: 'sleep_prepare',
        kind: SleepRoutineSegmentKind.windDown,
        duration: adjusted.windDown,
        localizationKey: 'sleep_routine_segment_wind_down',
        soundProfile: 'sleep_prepare',
      ),
      SleepRoutineSegmentPlan(
        id: 'sleep_relax',
        kind: SleepRoutineSegmentKind.relax,
        duration: adjusted.relax,
        localizationKey: 'sleep_routine_segment_relax',
        soundProfile: 'sleep_relax',
      ),
      SleepRoutineSegmentPlan(
        id: 'sleep_main',
        kind: SleepRoutineSegmentKind.mainSleep,
        duration: adjusted.mainSleep,
        localizationKey: 'sleep_routine_segment_main',
        soundProfile: 'sleep',
        enableSmartAlarm: smartAlarmEnabled,
      ),
      SleepRoutineSegmentPlan(
        id: 'sleep_pre_wake',
        kind: SleepRoutineSegmentKind.preWake,
        duration: adjusted.preWake,
        localizationKey: 'sleep_routine_segment_pre_wake',
        soundProfile: 'sleep_relax',
        autoStartNext: true,
      ),
      SleepRoutineSegmentPlan(
        id: 'sleep_wake_alarm',
        kind: SleepRoutineSegmentKind.wakeAlarm,
        duration: adjusted.wake,
        localizationKey: 'sleep_routine_segment_wake',
        soundProfile: 'wake_alarm',
        autoStartNext: false,
      ),
    ];
  }

  _SegmentTemplate _segmentTemplateFor(SleepGoal goal) {
    switch (goal) {
      case SleepGoal.rest:
        return _SegmentTemplate(
          windDown: const Duration(minutes: 3),
          minWindDown: const Duration(minutes: 2),
          relax: const Duration(minutes: 4),
          minRelax: const Duration(minutes: 2),
          preWake: const Duration(minutes: 2),
          minPreWake: const Duration(minutes: 1),
          wake: const Duration(minutes: 1),
          minMain: const Duration(minutes: 12),
        );
      case SleepGoal.standard:
        return _SegmentTemplate(
          windDown: const Duration(minutes: 10),
          minWindDown: const Duration(minutes: 5),
          relax: const Duration(minutes: 6),
          minRelax: const Duration(minutes: 3),
          preWake: const Duration(minutes: 5),
          minPreWake: const Duration(minutes: 3),
          wake: const Duration(minutes: 2),
          minMain: const Duration(hours: 4),
        );
      case SleepGoal.recovery:
        return _SegmentTemplate(
          windDown: const Duration(minutes: 15),
          minWindDown: const Duration(minutes: 8),
          relax: const Duration(minutes: 10),
          minRelax: const Duration(minutes: 5),
          preWake: const Duration(minutes: 10),
          minPreWake: const Duration(minutes: 5),
          wake: const Duration(minutes: 3),
          minMain: const Duration(hours: 5),
        );
    }
  }

  _AdjustedDurations _adjustDurations(
    Duration total,
    _SegmentTemplate template,
  ) {
    final totalSeconds = total.inSeconds;
    var windDownSeconds = template.windDown.inSeconds;
    var relaxSeconds = template.relax.inSeconds;
    var preWakeSeconds = template.preWake.inSeconds;
    final wakeSeconds = template.wake.inSeconds;
    var mainSeconds = totalSeconds -
        (windDownSeconds + relaxSeconds + preWakeSeconds + wakeSeconds);

    final minMainSeconds = template.minMain.inSeconds;
    final minWindDown = template.minWindDown.inSeconds;
    final minRelax = template.minRelax.inSeconds;
    final minPreWake = template.minPreWake.inSeconds;

    if (mainSeconds < minMainSeconds) {
      var deficit = minMainSeconds - mainSeconds;
      mainSeconds = minMainSeconds;
      final adjustments = [
        _MutableSegment(
          () => windDownSeconds,
          (value) => windDownSeconds = value,
          minWindDown,
        ),
        _MutableSegment(
          () => relaxSeconds,
          (value) => relaxSeconds = value,
          minRelax,
        ),
        _MutableSegment(
          () => preWakeSeconds,
          (value) => preWakeSeconds = value,
          minPreWake,
        ),
      ];
      for (final segment in adjustments) {
        if (deficit <= 0) break;
        final available = segment.current() - segment.minimum;
        if (available <= 0) continue;
        final reduction = min(available, deficit);
        segment.set(segment.current() - reduction);
        deficit -= reduction;
      }
    }

    windDownSeconds = max(windDownSeconds, minWindDown);
    relaxSeconds = max(relaxSeconds, minRelax);
    preWakeSeconds = max(preWakeSeconds, minPreWake);

    var used = windDownSeconds +
        relaxSeconds +
        preWakeSeconds +
        wakeSeconds +
        mainSeconds;
    if (used > totalSeconds) {
      final overflow = used - totalSeconds;
      mainSeconds = max(minMainSeconds, mainSeconds - overflow);
      used = windDownSeconds +
          relaxSeconds +
          preWakeSeconds +
          wakeSeconds +
          mainSeconds;
    }

    // Ensure no negative durations.
    windDownSeconds = max(windDownSeconds, minWindDown);
    relaxSeconds = max(relaxSeconds, minRelax);
    preWakeSeconds = max(preWakeSeconds, minPreWake);
    mainSeconds = max(mainSeconds, minMainSeconds);

    return _AdjustedDurations(
      windDown: Duration(seconds: windDownSeconds),
      relax: Duration(seconds: relaxSeconds),
      mainSleep: Duration(seconds: mainSeconds),
      preWake: Duration(seconds: preWakeSeconds),
      wake: Duration(seconds: wakeSeconds),
    );
  }

  SleepAudioBlend _audioBlendFor(
    SleepGoal goal,
    DailyUsageContext? usage,
  ) {
    final base = _baseAudioBlend(goal);
    if (usage == null) {
      return base;
    }
    final layers = Map<String, double>.from(base.layers);
    final calm = usage.calmNeedScore();
    if (calm > 0.05) {
      layers['ocean_waves'] = (layers['ocean_waves'] ?? 0.0) + 0.25 * calm;
      layers['rain_light'] = (layers['rain_light'] ?? 0.2) * (1 - 0.15 * calm);
      layers['pink_noise'] = (layers['pink_noise'] ?? 0.15) + 0.1 * calm;
    }
    final physical = usage.physicalRecoveryNeedScore(goal);
    if (physical > 0.05) {
      layers['brown_noise'] = (layers['brown_noise'] ?? 0.2) + 0.2 * physical;
      layers['forest_birds'] = (layers['forest_birds'] ?? 0.1) * (1 - 0.1 * physical);
    }
    final normalized = _normalizeLayers(layers);
    return SleepAudioBlend(
      layers: normalized,
      fadeIn: base.fadeIn,
      fadeOut: base.fadeOut,
    );
  }

  SleepAudioBlend _baseAudioBlend(SleepGoal goal) {
    switch (goal) {
      case SleepGoal.rest:
        return const SleepAudioBlend(
          layers: {
            'white_noise': 0.25,
            'ocean_waves': 0.35,
            'pink_noise': 0.15,
          },
        );
      case SleepGoal.standard:
        return const SleepAudioBlend(
          layers: {
            'rain_light': 0.3,
            'pink_noise': 0.2,
            'fireplace_cozy': 0.15,
          },
        );
      case SleepGoal.recovery:
        return const SleepAudioBlend(
          layers: {
            'brown_noise': 0.35,
            'ocean_waves': 0.25,
            'forest_birds': 0.15,
          },
        );
    }
  }

  Map<String, double> _normalizeLayers(Map<String, double> layers) {
    final positiveEntries = <String, double>{};
    for (final entry in layers.entries) {
      if (entry.value > 0) {
        positiveEntries[entry.key] = entry.value;
      }
    }
    final total = positiveEntries.values.fold<double>(0, (prev, value) => prev + value);
    if (total <= 0) {
      return layers;
    }
    return positiveEntries.map(
      (key, value) => MapEntry(key, (value / total).clamp(0.0, 1.0)),
    );
  }

  _SegmentTemplate _applyUsageToTemplate(
    _SegmentTemplate template,
    DailyUsageContext usage,
    SleepGoal goal,
  ) {
    final calm = usage.calmNeedScore();
    final sleepExtension = usage.sleepExtensionScore(goal);
    final physical = usage.physicalRecoveryNeedScore(goal);

    final windFactor = _lerp(1.0, 1.45, calm);
    final relaxFactor = _lerp(1.0, 1.55, calm);
    final mainFactor = _lerp(1.0, 1.3, sleepExtension);
    final preWakeFactor = _lerp(1.0, 1.25, physical);
    final wakeFactor = _lerp(1.0, 1.2, physical);

    return _scaleTemplate(
      template,
      windDownFactor: windFactor,
      relaxFactor: relaxFactor,
      mainFactor: mainFactor,
      preWakeFactor: preWakeFactor,
      wakeFactor: wakeFactor,
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t.clamp(0, 1);
}

class _SegmentTemplate {
  _SegmentTemplate({
    required this.windDown,
    required this.minWindDown,
    required this.relax,
    required this.minRelax,
    required this.preWake,
    required this.minPreWake,
    required this.wake,
    required this.minMain,
  });

  final Duration windDown;
  final Duration minWindDown;
  final Duration relax;
  final Duration minRelax;
  final Duration preWake;
  final Duration minPreWake;
  final Duration wake;
  final Duration minMain;
}

class _MutableSegment {
  _MutableSegment(
    this.current,
    this.set,
    this.minimum,
  );

  final int Function() current;
  final void Function(int) set;
  final int minimum;
}

_SegmentTemplate _scaleTemplate(
  _SegmentTemplate template, {
  double windDownFactor = 1.0,
  double relaxFactor = 1.0,
  double mainFactor = 1.0,
  double preWakeFactor = 1.0,
  double wakeFactor = 1.0,
}) {
  Duration scale(Duration duration, double factor) {
    final seconds = (duration.inSeconds * factor).round();
    return Duration(seconds: max(1, seconds));
  }

  return _SegmentTemplate(
    windDown: scale(template.windDown, windDownFactor),
    minWindDown: template.minWindDown,
    relax: scale(template.relax, relaxFactor),
    minRelax: template.minRelax,
    preWake: scale(template.preWake, preWakeFactor),
    minPreWake: template.minPreWake,
    wake: scale(template.wake, wakeFactor),
    minMain: scale(template.minMain, mainFactor),
  );
}

class _AdjustedDurations {
  _AdjustedDurations({
    required this.windDown,
    required this.relax,
    required this.mainSleep,
    required this.preWake,
    required this.wake,
  });

  final Duration windDown;
  final Duration relax;
  final Duration mainSleep;
  final Duration preWake;
  final Duration wake;
}
