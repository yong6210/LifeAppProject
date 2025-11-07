import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:life_app/features/workout/data/workout_routes.dart';
import 'package:life_app/features/workout/models/workout_navigator_models.dart';
import 'package:life_app/features/workout/workout_navigator_controller.dart';
import 'package:life_app/services/analytics/analytics_service.dart';

void main() {
  late ProviderContainer container;
  late WorkoutNavigatorController controller;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    container = ProviderContainer();
    controller = container.read(workoutNavigatorProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  test('recommends closest predefined running route', () {
    final recommendation = controller.recommendFor(
      WorkoutNavigatorTarget.distance(
        discipline: WorkoutDiscipline.running,
        intensity: WorkoutIntensity.moderate,
        kilometers: 5.0,
      ),
    );

    expect(recommendation.route.discipline, WorkoutDiscipline.running);
    expect(recommendation.route.intensity, WorkoutIntensity.moderate);
    expect(recommendation.route.distanceKm, closeTo(5.2, 0.5));
    expect(recommendation.tips, isNotEmpty);
    expect(recommendation.route.voiceCues, isNotEmpty);
    expect(recommendation.route.segments, isNotEmpty);
  });

  test('falls back to dynamic route when no preset matches', () {
    final recommendation = controller.recommendFor(
      WorkoutNavigatorTarget.duration(
        discipline: WorkoutDiscipline.cycling,
        intensity: WorkoutIntensity.light,
        minutes: 55,
      ),
    );

    expect(recommendation.route.discipline, WorkoutDiscipline.cycling);
    expect(recommendation.route.intensity, WorkoutIntensity.light);
    expect(recommendation.route.title, contains('Ride'));
    expect(recommendation.route.estimatedMinutes, greaterThan(0));
    expect(recommendation.route.offlineSummary, contains('Warm up'));
  });

  test('predefined routes have offline summaries and segments', () {
    expect(workoutNavigatorRoutes, isNotEmpty);
    expect(
      workoutNavigatorRoutes.every((route) => route.offlineSummary.isNotEmpty),
      isTrue,
    );
    expect(
      workoutNavigatorRoutes.where((route) => route.segments.isNotEmpty),
      isNotEmpty,
    );
  });

  test('logs recommendation view when target changes', () async {
    final events = <Map<String, Object?>>[];
    AnalyticsService.setTestObserver((name, params) {
      events.add({'name': name, 'params': params});
    });
    addTearDown(() => AnalyticsService.setTestObserver(null));

    controller.setDistanceKm(8);
    await Future<void>.delayed(Duration.zero);

    final firstView = events.where(
      (event) => event['name'] == 'workout_navigator_recommendation_view',
    );
    expect(firstView, isNotEmpty);

    events.clear();
    controller.setDistanceKm(8);
    await Future<void>.delayed(Duration.zero);
    expect(
      events.where(
        (event) => event['name'] == 'workout_navigator_recommendation_view',
      ),
      isEmpty,
    );

    controller.setTargetType(WorkoutTargetType.duration);
    await Future<void>.delayed(Duration.zero);
    expect(
      events.where(
        (event) => event['name'] == 'workout_navigator_recommendation_view',
      ),
      isNotEmpty,
    );
  });
}
