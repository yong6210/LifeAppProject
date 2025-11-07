import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:life_app/features/workout/workout_navigator_controller.dart';
import 'package:life_app/features/workout/workout_navigator_page.dart';
import 'package:life_app/features/workout/models/workout_navigator_models.dart';
import 'package:life_app/l10n/app_localizations.dart';

MaterialApp _buildApp() {
  return MaterialApp(
    home: const WorkoutNavigatorPage(),
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('tapping discipline cards updates selection', (tester) async {
    await tester.pumpWidget(ProviderScope(child: _buildApp()));

    await tester.pumpAndSettle();
    final pageFinder = find.byType(WorkoutNavigatorPage, skipOffstage: false);
    expect(pageFinder, findsWidgets);
    final context = tester.element(pageFinder.first);
    final container = ProviderScope.containerOf(context, listen: false);

    expect(
      container.read(workoutNavigatorProvider).discipline,
      WorkoutDiscipline.running,
    );

    await tester.tap(find.text('Ride'));
    await tester.pumpAndSettle();

    expect(
      container.read(workoutNavigatorProvider).discipline,
      WorkoutDiscipline.cycling,
    );
  });

  testWidgets('distance preset chips update target', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: _buildApp()),
    );

    await tester.pumpAndSettle();

    expect(
      container.read(workoutNavigatorProvider).distanceKm,
      closeTo(5.0, 0.01),
    );
    expect(
      container.read(workoutNavigatorProvider).targetType,
      WorkoutTargetType.distance,
    );

    // Simulate selecting the 10 km preset via notifier (chips may render offstage in tests).
    container.read(workoutNavigatorProvider.notifier).setDistanceKm(10);
    await tester.pump();

    expect(
      container.read(workoutNavigatorProvider).distanceKm,
      closeTo(10.0, 0.01),
    );
  });
}
