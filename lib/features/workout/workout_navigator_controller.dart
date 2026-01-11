import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:life_app/features/workout/data/workout_routes.dart';
import 'package:life_app/features/workout/models/workout_navigator_models.dart';
import 'package:life_app/services/analytics/analytics_service.dart';

final workoutNavigatorProvider =
    NotifierProvider<WorkoutNavigatorController, WorkoutNavigatorState>(
      WorkoutNavigatorController.new,
    );

class WorkoutNavigatorState {
  const WorkoutNavigatorState({
    required this.discipline,
    required this.intensity,
    required this.targetType,
    required this.distanceKm,
    required this.durationMinutes,
    required this.voiceGuidanceEnabled,
    required this.recommendation,
    this.isHydrated = false,
  });

  final WorkoutDiscipline discipline;
  final WorkoutIntensity intensity;
  final WorkoutTargetType targetType;
  final double distanceKm;
  final double durationMinutes;
  final bool voiceGuidanceEnabled;
  final WorkoutNavigatorRecommendation recommendation;
  final bool isHydrated;

  WorkoutNavigatorTarget get target {
    return switch (targetType) {
      WorkoutTargetType.distance => WorkoutNavigatorTarget.distance(
        discipline: discipline,
        intensity: intensity,
        kilometers: distanceKm,
      ),
      WorkoutTargetType.duration => WorkoutNavigatorTarget.duration(
        discipline: discipline,
        intensity: intensity,
        minutes: durationMinutes,
      ),
    };
  }

  WorkoutNavigatorState copyWith({
    WorkoutDiscipline? discipline,
    WorkoutIntensity? intensity,
    WorkoutTargetType? targetType,
    double? distanceKm,
    double? durationMinutes,
    bool? voiceGuidanceEnabled,
    WorkoutNavigatorRecommendation? recommendation,
    bool? isHydrated,
  }) {
    return WorkoutNavigatorState(
      discipline: discipline ?? this.discipline,
      intensity: intensity ?? this.intensity,
      targetType: targetType ?? this.targetType,
      distanceKm: distanceKm ?? this.distanceKm,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      voiceGuidanceEnabled: voiceGuidanceEnabled ?? this.voiceGuidanceEnabled,
      recommendation: recommendation ?? this.recommendation,
      isHydrated: isHydrated ?? this.isHydrated,
    );
  }
}

class WorkoutNavigatorController extends Notifier<WorkoutNavigatorState> {
  SharedPreferences? _prefs;
  String _lastRecommendationDigest = '';

  static const _prefsVoiceGuidanceKey = 'workout_voice_guidance_enabled';
  static const _prefsDisciplineKey = 'workout_navigator_last_discipline';
  static const _prefsIntensityKey = 'workout_navigator_last_intensity';
  static const _prefsTargetTypeKey = 'workout_navigator_last_target_type';
  static const _prefsDistanceKey = 'workout_navigator_last_distance_km';
  static const _prefsDurationKey = 'workout_navigator_last_duration_min';

  @override
  WorkoutNavigatorState build() {
    return _buildState(
      discipline: WorkoutDiscipline.running,
      intensity: WorkoutIntensity.moderate,
      targetType: WorkoutTargetType.distance,
      distanceKm: 5.0,
      durationMinutes: 35,
      voiceGuidanceEnabled: true,
    );
  }

  Future<void> restore() async {
    final prefs = await _ensurePrefs();
    final discipline =
        _decodeEnum(
          WorkoutDiscipline.values,
          prefs.getString(_prefsDisciplineKey),
        ) ??
        state.discipline;
    final intensity =
        _decodeEnum(
          WorkoutIntensity.values,
          prefs.getString(_prefsIntensityKey),
        ) ??
        state.intensity;
    final targetType =
        _decodeEnum(
          WorkoutTargetType.values,
          prefs.getString(_prefsTargetTypeKey),
        ) ??
        state.targetType;
    final distanceKm = prefs.getDouble(_prefsDistanceKey) ?? state.distanceKm;
    final durationMinutes =
        prefs.getDouble(_prefsDurationKey) ?? state.durationMinutes;
    final voiceEnabled =
        prefs.getBool(_prefsVoiceGuidanceKey) ?? state.voiceGuidanceEnabled;

    state = _buildState(
      discipline: discipline,
      intensity: intensity,
      targetType: targetType,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      voiceGuidanceEnabled: voiceEnabled,
      isHydrated: true,
    );
  }

  void setDiscipline(WorkoutDiscipline value) {
    _updateAndPersist(discipline: value);
  }

  void setIntensity(WorkoutIntensity value) {
    _updateAndPersist(intensity: value);
  }

  void setTargetType(WorkoutTargetType value) {
    _updateAndPersist(targetType: value);
  }

  void setDistanceKm(double value) {
    _updateAndPersist(distanceKm: value);
  }

  void setDurationMinutes(double value) {
    _updateAndPersist(durationMinutes: value);
  }

  Future<void> setVoiceGuidance(bool value) async {
    final next = state.copyWith(voiceGuidanceEnabled: value);
    final recommendation = _recommend(next.target);
    _logRecommendationEvent(
      next.target,
      recommendation,
      voiceGuidanceEnabled: next.voiceGuidanceEnabled,
    );
    state = next.copyWith(recommendation: recommendation);
    final prefs = await _ensurePrefs();
    await prefs.setBool(_prefsVoiceGuidanceKey, value);
  }

  WorkoutNavigatorRecommendation recommendFor(WorkoutNavigatorTarget target) {
    return _recommend(target);
  }

  WorkoutNavigatorState _buildState({
    required WorkoutDiscipline discipline,
    required WorkoutIntensity intensity,
    required WorkoutTargetType targetType,
    required double distanceKm,
    required double durationMinutes,
    required bool voiceGuidanceEnabled,
    bool isHydrated = false,
  }) {
    final base = WorkoutNavigatorState(
      discipline: discipline,
      intensity: intensity,
      targetType: targetType,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      voiceGuidanceEnabled: voiceGuidanceEnabled,
      recommendation: const WorkoutNavigatorRecommendation(
        route: WorkoutNavigatorRoute(
          id: 'placeholder',
          title: '',
          description: '',
          discipline: WorkoutDiscipline.running,
          intensity: WorkoutIntensity.moderate,
          distanceKm: 0,
          estimatedMinutes: 0,
          offlineSummary: '',
        ),
        tips: <String>[],
      ),
      isHydrated: isHydrated,
    );
    final recommendation = _recommend(base.target);
    _logRecommendationEvent(
      base.target,
      recommendation,
      voiceGuidanceEnabled: voiceGuidanceEnabled,
    );
    return base.copyWith(recommendation: recommendation);
  }

  void _updateAndPersist({
    WorkoutDiscipline? discipline,
    WorkoutIntensity? intensity,
    WorkoutTargetType? targetType,
    double? distanceKm,
    double? durationMinutes,
  }) {
    final next = state.copyWith(
      discipline: discipline,
      intensity: intensity,
      targetType: targetType,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
    );
    final recommendation = _recommend(next.target);
    _logRecommendationEvent(
      next.target,
      recommendation,
      voiceGuidanceEnabled: next.voiceGuidanceEnabled,
    );
    state = next.copyWith(recommendation: recommendation);
    unawaited(_persistSelections());
  }

  Future<void> _persistSelections() async {
    final prefs = await _ensurePrefs();
    await prefs.setString(_prefsDisciplineKey, state.discipline.name);
    await prefs.setString(_prefsIntensityKey, state.intensity.name);
    await prefs.setString(_prefsTargetTypeKey, state.targetType.name);
    await prefs.setDouble(_prefsDistanceKey, state.distanceKm);
    await prefs.setDouble(_prefsDurationKey, state.durationMinutes);
    await prefs.setBool(_prefsVoiceGuidanceKey, state.voiceGuidanceEnabled);
  }

  Future<SharedPreferences> _ensurePrefs() async {
    if (_prefs != null) {
      return _prefs!;
    }
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  WorkoutNavigatorRecommendation _recommend(WorkoutNavigatorTarget target) {
    final candidates = workoutNavigatorRoutes.where(
      (route) =>
          route.discipline == target.discipline &&
          route.intensity == target.intensity,
    );

    final sorted = candidates.toList()
      ..sort((a, b) {
        if (target.type == WorkoutTargetType.distance) {
          final diff =
              (a.distanceKm - target.value).abs() -
              (b.distanceKm - target.value).abs();
          return diff.sign.toInt();
        } else {
          final diff =
              (a.estimatedMinutes - target.value).abs() -
              (b.estimatedMinutes - target.value).abs();
          return diff.sign.toInt();
        }
      });

    final best = sorted.isNotEmpty ? sorted.first : _fallbackRoute(target);

    return WorkoutNavigatorRecommendation(route: best, tips: _tipsFor(best));
  }

  void _logRecommendationEvent(
    WorkoutNavigatorTarget target,
    WorkoutNavigatorRecommendation recommendation, {
    required bool voiceGuidanceEnabled,
  }) {
    final digest = [
      target.discipline.name,
      target.intensity.name,
      target.type.name,
      target.value.toStringAsFixed(2),
      recommendation.route.id,
    ].join('|');
    if (_lastRecommendationDigest == digest) {
      return;
    }
    _lastRecommendationDigest = digest;
    unawaited(
      AnalyticsService.logEvent('workout_navigator_recommendation_view', {
        'route_id': recommendation.route.id,
        'discipline': target.discipline.name,
        'intensity': target.intensity.name,
        'target_type': target.type.name,
        'target_value': target.value,
        'voice_guidance_enabled': voiceGuidanceEnabled,
        'has_map_preview': recommendation.route.mapAssetPath != null,
        'has_voice_cues': recommendation.route.voiceCues.isNotEmpty,
        'is_dynamic_route': recommendation.route.id.startsWith('dynamic_'),
        'tips_count': recommendation.tips.length,
      }),
    );
  }

  WorkoutNavigatorRoute _fallbackRoute(WorkoutNavigatorTarget target) {
    final targetDistanceKm = target.type == WorkoutTargetType.distance
        ? target.value
        : _defaultDistance(target.discipline, target.intensity);
    final targetDurationMinutes = target.type == WorkoutTargetType.duration
        ? target.value
        : _defaultDuration(target.discipline, target.intensity);
    final targetDurationInt = max(5, targetDurationMinutes.round());
    final cooldownStartMinutes = max(0, targetDurationInt - 2);

    return WorkoutNavigatorRoute(
      id: 'dynamic_${target.discipline.name}_${target.intensity.name}',
      title: _fallbackTitle(target),
      description: _fallbackDescription(target),
      discipline: target.discipline,
      intensity: target.intensity,
      distanceKm: targetDistanceKm,
      estimatedMinutes: targetDurationMinutes,
      offlineSummary: '''
- Warm up for 3 minutes.
- Hold your target effort through the middle of the session.
- Finish with a short cooldown walk or spin.''',
      segments: [
        const WorkoutNavigatorSegment(
          startOffset: Duration.zero,
          endOffset: Duration(minutes: 3),
          focus: 'Warm-up',
          cue: 'Keep the opening minutes relaxed and let breathing settle.',
        ),
        WorkoutNavigatorSegment(
          startOffset: const Duration(minutes: 3),
          endOffset: Duration(minutes: targetDurationInt),
          focus: 'Main effort',
          cue:
              'Stay within sustainable effort. Adjust pace if breathing spikes.',
        ),
        WorkoutNavigatorSegment(
          startOffset: Duration(minutes: cooldownStartMinutes),
          endOffset: Duration(minutes: targetDurationInt),
          focus: 'Cooldown',
          cue: 'Ease off the effort and finish with light breathing work.',
        ),
      ],
      voiceCues: [
        const WorkoutNavigatorCue(
          offset: Duration(minutes: 3),
          message: 'Move into your main effort; keep shoulders relaxed.',
        ),
        WorkoutNavigatorCue(
          offset: Duration(
            minutes: min(targetDurationInt - 1, max(4, targetDurationInt ~/ 2)),
          ),
          message: 'Final minutes—focus on smooth form before cooling down.',
        ),
      ],
    );
  }

  String _fallbackTitle(WorkoutNavigatorTarget target) {
    final disciplineLabel = target.discipline == WorkoutDiscipline.running
        ? 'Neighborhood Run'
        : 'City Ride';
    final intensityLabel = switch (target.intensity) {
      WorkoutIntensity.light => 'Easy',
      WorkoutIntensity.moderate => 'Steady',
      WorkoutIntensity.vigorous => 'Power',
    };
    return '$intensityLabel $disciplineLabel';
  }

  String _fallbackDescription(WorkoutNavigatorTarget target) {
    if (target.type == WorkoutTargetType.distance) {
      return 'Stay at a comfortable pace for ${target.value.toStringAsFixed(1)} km. '
          'Adjust speed if breathing feels strained.';
    }
    return 'Maintain a sustainable pace for ${target.value.toStringAsFixed(0)} minutes. '
        'Break into thirds: warm up, steady state, finish strong.';
  }

  double _defaultDistance(
    WorkoutDiscipline discipline,
    WorkoutIntensity intensity,
  ) {
    return switch ((discipline, intensity)) {
      (WorkoutDiscipline.running, WorkoutIntensity.light) => 4.0,
      (WorkoutDiscipline.running, WorkoutIntensity.moderate) => 6.5,
      (WorkoutDiscipline.running, WorkoutIntensity.vigorous) => 8.0,
      (WorkoutDiscipline.cycling, WorkoutIntensity.light) => 8.0,
      (WorkoutDiscipline.cycling, WorkoutIntensity.moderate) => 15.0,
      (WorkoutDiscipline.cycling, WorkoutIntensity.vigorous) => 22.0,
    };
  }

  double _defaultDuration(
    WorkoutDiscipline discipline,
    WorkoutIntensity intensity,
  ) {
    return switch ((discipline, intensity)) {
      (WorkoutDiscipline.running, WorkoutIntensity.light) => 25,
      (WorkoutDiscipline.running, WorkoutIntensity.moderate) => 35,
      (WorkoutDiscipline.running, WorkoutIntensity.vigorous) => 45,
      (WorkoutDiscipline.cycling, WorkoutIntensity.light) => 30,
      (WorkoutDiscipline.cycling, WorkoutIntensity.moderate) => 45,
      (WorkoutDiscipline.cycling, WorkoutIntensity.vigorous) => 60,
    };
  }

  List<String> _tipsFor(WorkoutNavigatorRoute route) {
    final pacing = switch (route.intensity) {
      WorkoutIntensity.light =>
        'Keep your heart rate low and focus on smooth breathing.',
      WorkoutIntensity.moderate =>
        'Aim for sustainable effort—breathing harder but still able to talk.',
      WorkoutIntensity.vigorous =>
        'Use intervals: short surges followed by controlled recovery sections.',
    };
    return [
      pacing,
      'Hydrate before starting. Bring a small bottle if you expect warmer weather.',
      route.mapAssetPath != null
          ? 'Preview the map image before you head out so you recognise key turns.'
          : 'Decide on your loop in advance; note landmarks to keep track of distance.',
    ];
  }

  T? _decodeEnum<T extends Enum>(List<T> values, String? source) {
    if (source == null) return null;
    for (final value in values) {
      if (value.name == source) {
        return value;
      }
    }
    return null;
  }
}
