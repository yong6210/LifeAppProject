import 'package:life_app/features/timer/timer_plan.dart';
import 'package:life_app/models/settings.dart';
import 'package:life_app/services/premium/premium_routine.dart';

class PremiumRoutineSegmentDefinition {
  const PremiumRoutineSegmentDefinition({
    required this.id,
    required this.type,
    required this.duration,
    required this.localizationKey,
    this.localizationArgs,
    this.soundProfile,
    this.recordSession = true,
    this.enableSmartAlarm = false,
  });

  final String id;
  final String type;
  final Duration duration;
  final String localizationKey;
  final Map<String, String>? localizationArgs;
  final String? soundProfile;
  final bool recordSession;
  final bool enableSmartAlarm;
}

class PremiumRoutineDefinition {
  const PremiumRoutineDefinition({
    required this.id,
    required this.mode,
    required this.segments,
  });

  final String id;
  final PremiumRoutineMode mode;
  final List<PremiumRoutineSegmentDefinition> segments;
}

class PremiumRoutinePlanBuilder {
  static const _premiumProfile = 'premium_routine';

  static final Map<String, PremiumRoutineDefinition> _definitions = {
    'focus_deep_work': const PremiumRoutineDefinition(
      id: 'focus_deep_work',
      mode: PremiumRoutineMode.focus,
      segments: [
        PremiumRoutineSegmentDefinition(
          id: 'warmup',
          type: 'rest',
          duration: Duration(minutes: 5),
          localizationKey: 'premium_focus_deep_warmup_label',
          soundProfile: 'breath',
          recordSession: false,
        ),
        PremiumRoutineSegmentDefinition(
          id: 'main',
          type: 'focus',
          duration: Duration(minutes: 40),
          localizationKey: 'premium_focus_deep_main_label',
          soundProfile: _premiumProfile,
          recordSession: true,
        ),
        PremiumRoutineSegmentDefinition(
          id: 'cooldown',
          type: 'rest',
          duration: Duration(minutes: 5),
          localizationKey: 'premium_focus_deep_cooldown_label',
          soundProfile: 'calm',
          recordSession: false,
        ),
      ],
    ),
    'focus_flow_cycle': const PremiumRoutineDefinition(
      id: 'focus_flow_cycle',
      mode: PremiumRoutineMode.focus,
      segments: [
        PremiumRoutineSegmentDefinition(
          id: 'activate',
          type: 'rest',
          duration: Duration(minutes: 5),
          localizationKey: 'premium_focus_flow_activate_label',
          soundProfile: 'breath',
          recordSession: false,
        ),
        PremiumRoutineSegmentDefinition(
          id: 'cycle1_focus',
          type: 'focus',
          duration: Duration(minutes: 10),
          localizationKey: 'premium_focus_flow_focus_label',
          localizationArgs: {'cycle': '1'},
          soundProfile: _premiumProfile,
        ),
        PremiumRoutineSegmentDefinition(
          id: 'cycle1_reset',
          type: 'rest',
          duration: Duration(minutes: 2),
          localizationKey: 'premium_focus_flow_reset_label',
          localizationArgs: {'cycle': '1'},
          soundProfile: 'rest',
          recordSession: false,
        ),
        PremiumRoutineSegmentDefinition(
          id: 'cycle2_focus',
          type: 'focus',
          duration: Duration(minutes: 10),
          localizationKey: 'premium_focus_flow_focus_label',
          localizationArgs: {'cycle': '2'},
          soundProfile: _premiumProfile,
        ),
        PremiumRoutineSegmentDefinition(
          id: 'cycle2_reset',
          type: 'rest',
          duration: Duration(minutes: 2),
          localizationKey: 'premium_focus_flow_reset_label',
          localizationArgs: {'cycle': '2'},
          soundProfile: 'rest',
          recordSession: false,
        ),
        PremiumRoutineSegmentDefinition(
          id: 'cycle3_focus',
          type: 'focus',
          duration: Duration(minutes: 10),
          localizationKey: 'premium_focus_flow_focus_label',
          localizationArgs: {'cycle': '3'},
          soundProfile: _premiumProfile,
        ),
        PremiumRoutineSegmentDefinition(
          id: 'cycle3_calm',
          type: 'rest',
          duration: Duration(minutes: 6),
          localizationKey: 'premium_focus_flow_calm_label',
          soundProfile: 'calm',
          recordSession: false,
        ),
      ],
    ),
    'rest_mindful_break': const PremiumRoutineDefinition(
      id: 'rest_mindful_break',
      mode: PremiumRoutineMode.rest,
      segments: [
        PremiumRoutineSegmentDefinition(
          id: 'arrive',
          type: 'rest',
          duration: Duration(minutes: 5),
          localizationKey: 'premium_rest_mindful_arrive_label',
          soundProfile: 'breath',
          recordSession: false,
        ),
        PremiumRoutineSegmentDefinition(
          id: 'guided',
          type: 'rest',
          duration: Duration(minutes: 15),
          localizationKey: 'premium_rest_mindful_guided_label',
          soundProfile: _premiumProfile,
        ),
        PremiumRoutineSegmentDefinition(
          id: 'integrate',
          type: 'rest',
          duration: Duration(minutes: 10),
          localizationKey: 'premium_rest_mindful_integrate_label',
          soundProfile: 'calm',
          recordSession: false,
        ),
      ],
    ),
    'rest_guided_unwind': const PremiumRoutineDefinition(
      id: 'rest_guided_unwind',
      mode: PremiumRoutineMode.rest,
      segments: [
        PremiumRoutineSegmentDefinition(
          id: 'release',
          type: 'rest',
          duration: Duration(minutes: 5),
          localizationKey: 'premium_rest_guided_release_label',
          soundProfile: 'breath',
          recordSession: false,
        ),
        PremiumRoutineSegmentDefinition(
          id: 'journey',
          type: 'rest',
          duration: Duration(minutes: 15),
          localizationKey: 'premium_rest_guided_journey_label',
          soundProfile: _premiumProfile,
        ),
        PremiumRoutineSegmentDefinition(
          id: 'reflection',
          type: 'rest',
          duration: Duration(minutes: 5),
          localizationKey: 'premium_rest_guided_reflection_label',
          soundProfile: 'calm',
          recordSession: false,
        ),
      ],
    ),
    'sleep_lunar_waves': const PremiumRoutineDefinition(
      id: 'sleep_lunar_waves',
      mode: PremiumRoutineMode.sleep,
      segments: [
        PremiumRoutineSegmentDefinition(
          id: 'prepare',
          type: 'sleep',
          duration: Duration(minutes: 8),
          localizationKey: 'premium_sleep_lunar_prepare_label',
          soundProfile: 'sleep_prepare',
          recordSession: false,
        ),
        PremiumRoutineSegmentDefinition(
          id: 'drift',
          type: 'sleep',
          duration: Duration(minutes: 22),
          localizationKey: 'premium_sleep_lunar_drift_label',
          soundProfile: _premiumProfile,
          recordSession: true,
          enableSmartAlarm: true,
        ),
        PremiumRoutineSegmentDefinition(
          id: 'deep',
          type: 'sleep',
          duration: Duration(minutes: 10),
          localizationKey: 'premium_sleep_lunar_deep_label',
          soundProfile: 'sleep',
          recordSession: true,
        ),
      ],
    ),
    'sleep_breath_release': const PremiumRoutineDefinition(
      id: 'sleep_breath_release',
      mode: PremiumRoutineMode.sleep,
      segments: [
        PremiumRoutineSegmentDefinition(
          id: 'breath',
          type: 'sleep',
          duration: Duration(minutes: 12),
          localizationKey: 'premium_sleep_release_breath_label',
          soundProfile: _premiumProfile,
          recordSession: false,
        ),
        PremiumRoutineSegmentDefinition(
          id: 'unwind',
          type: 'sleep',
          duration: Duration(minutes: 8),
          localizationKey: 'premium_sleep_release_unwind_label',
          soundProfile: 'sleep_relax',
          recordSession: false,
        ),
        PremiumRoutineSegmentDefinition(
          id: 'drift',
          type: 'sleep',
          duration: Duration(minutes: 10),
          localizationKey: 'premium_sleep_release_drift_label',
          soundProfile: 'sleep',
          recordSession: true,
          enableSmartAlarm: true,
        ),
      ],
    ),
  };

  static PremiumRoutineDefinition? definitionFor(String id) {
    return _definitions[id];
  }

  static TimerPlan? buildPlan({
    required PremiumRoutine routine,
    required Settings settings,
  }) {
    final definition = definitionFor(routine.id);
    if (definition == null) return null;

    final modeString = switch (definition.mode) {
      PremiumRoutineMode.focus => 'focus',
      PremiumRoutineMode.rest => 'rest',
      PremiumRoutineMode.sleep => 'sleep',
    };

    SmartAlarmConfig? smartAlarm;
    if (definition.mode == PremiumRoutineMode.sleep) {
      final windowMinutes = settings.sleepSmartAlarmWindowMinutes
          .clamp(0, 120)
          .toInt();
      final intervalMinutes = settings.sleepSmartAlarmIntervalMinutes
          .clamp(1, 15)
          .toInt();
      if (windowMinutes > 0) {
        smartAlarm = SmartAlarmConfig(
          windowMinutes: windowMinutes,
          intervalMinutes: intervalMinutes,
          fallbackExactAlarm: settings.sleepSmartAlarmExactFallback,
        );
      }
    }

    TimerSegment mapSegment(PremiumRoutineSegmentDefinition segment) {
      final profile =
          segment.soundProfile ?? _defaultProfileForType(segment.type);
      return TimerSegment(
        id: '${definition.id}_${segment.id}',
        type: segment.type,
        duration: segment.duration,
        localizationKey: segment.localizationKey,
        localizationArgs: segment.localizationArgs,
        recordSession: segment.recordSession,
        playSoundProfile: profile,
        autoStartNext: true,
        smartAlarm: segment.enableSmartAlarm ? smartAlarm : null,
      );
    }

    final segments = definition.segments.map(mapSegment).toList();
    return TimerPlan(mode: modeString, segments: segments);
  }

  static String _defaultProfileForType(String type) {
    switch (type) {
      case 'focus':
        return 'focus';
      case 'sleep':
        return 'sleep';
      case 'rest':
      default:
        return 'rest';
    }
  }
}
