import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_app/features/timer/timer_controller.dart';
import 'package:life_app/features/timer/timer_page.dart';
import 'package:life_app/features/timer/timer_plan.dart';
import 'package:life_app/features/timer/timer_state.dart';
import 'package:life_app/features/workout/workout_navigator_page.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/models/settings.dart';
import 'package:life_app/providers/session_providers.dart';
import 'package:life_app/providers/settings_providers.dart';
import 'package:life_app/services/accessibility/timer_announcer.dart';
import 'package:life_app/services/analytics/analytics_service.dart';
import 'package:life_app/services/permission_service.dart';
import 'package:life_app/services/subscription/revenuecat_service.dart';
import 'package:life_app/services/audio/sleep_sound_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod/src/framework.dart' show Override;

class _FakeTimerController extends TimerController {
  static Settings template = Settings();

  late Settings _settings;

  @override
  TimerState build() {
    _settings = template;
    final plan = TimerPlanFactory.createPlan(_settings.lastMode, _settings);
    return TimerState.idle(
      plan: plan,
      soundEnabled: true,
      workoutPresetId: null,
    );
  }

  TimerPlan _planFor(String mode) {
    _settings.lastMode = mode;
    return TimerPlanFactory.createPlan(mode, _settings);
  }

  @override
  Future<void> selectMode(String mode) async {
    state = TimerState.idle(
      plan: _planFor(mode),
      soundEnabled: state.isSoundEnabled,
      workoutPresetId: null,
    );
  }

  @override
  Future<void> setPreset(String mode, int minutes) async {
    switch (mode) {
      case 'focus':
        _settings.focusMinutes = minutes;
        break;
      case 'rest':
        _settings.restMinutes = minutes;
        break;
      case 'workout':
        _settings.workoutMinutes = minutes;
        break;
      case 'sleep':
        _settings.sleepMinutes = minutes;
        break;
    }
    await selectMode(mode);
  }

  @override
  Future<void> refreshCurrentPlan() async {
    state = TimerState.idle(
      plan: _planFor(state.mode),
      soundEnabled: state.isSoundEnabled,
      workoutPresetId: null,
    );
  }

  @override
  Future<void> toggleSound() async {
    state = state.copyWith(isSoundEnabled: !state.isSoundEnabled);
  }

  @override
  Future<void> previousSegment() async {
    if (state.currentSegmentIndex <= 0) return;
    state = state.copyWith(currentSegmentIndex: state.currentSegmentIndex - 1);
  }

  @override
  Future<void> toggleStartStop() async {
    state = state.copyWith(isRunning: !state.isRunning);
  }

  @override
  Future<void> reset() async {
    state = TimerState.idle(
      plan: _planFor(state.mode),
      soundEnabled: state.isSoundEnabled,
      workoutPresetId: null,
    );
  }

  @override
  Future<void> skipSegment() async {
    if (state.currentSegmentIndex >= state.segments.length - 1) {
      await reset();
      return;
    }
    state = state.copyWith(currentSegmentIndex: state.currentSegmentIndex + 1);
  }
}

class _SilentAnnouncer extends TimerAnnouncer {
  _SilentAnnouncer() : super(announce: (mode, message) async {});
}

SleepSoundCatalog _emptyCatalog() {
  return SleepSoundCatalog(
    layers: const <String, SleepSoundLayer>{},
    presets: <String, SleepSoundPreset>{
      SleepSoundCatalog.defaultPresetId: SleepSoundPreset(
        id: SleepSoundCatalog.defaultPresetId,
        layers: const <String, double>{},
        custom: true,
      ),
    },
  );
}

Settings _baseSettings() {
  final now = DateTime.now();
  final settings = Settings()
    ..deviceId = 'test-device'
    ..focusMinutes = 30
    ..restMinutes = 10
    ..workoutMinutes = 45
    ..sleepMinutes = 30
    ..lastBackupAt = now
    ..lastMode = 'workout';
  return settings;
}

TodaySummary _summaryWithWorkoutGap() {
  return const TodaySummary(focus: 60, rest: 20, workout: 5, sleep: 0);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    AnalyticsService.setTestConsent(
      const AnalyticsConsent(
        analytics: true,
        crashlytics: false,
        performance: false,
      ),
    );
    AnalyticsService.setTestObserver(null);
  });

  testWidgets(
    'workout navigator entry points open navigator and log analytics',
    (tester) async {
      Future<void> pumpTimerPage({
        required Settings settings,
        required TodaySummary summary,
        List<Override> extraOverrides = const <Override>[],
      }) async {
        _FakeTimerController.template = settings;
        final view = tester.view;
        final originalPhysicalSize = view.physicalSize;
        final originalDevicePixelRatio = view.devicePixelRatio;
        view.physicalSize = const Size(1080, 1920);
        view.devicePixelRatio = 1.0;
        addTearDown(() {
          view.physicalSize = originalPhysicalSize;
          view.devicePixelRatio = originalDevicePixelRatio;
        });
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              timerControllerProvider.overrideWith(_FakeTimerController.new),
              timerPermissionStatusProvider.overrideWith(
                (ref) async => const TimerPermissionStatus(
                  notificationGranted: true,
                  exactAlarmGranted: true,
                  dndAccessGranted: true,
                  microphoneGranted: true,
                ),
              ),
              todaySummaryProvider.overrideWith(
                (ref) => Stream<TodaySummary>.value(summary),
              ),
              settingsFutureProvider.overrideWith((ref) async => settings),
              sleepSoundCatalogProvider.overrideWith(
                (ref) async => _emptyCatalog(),
              ),
              isPremiumProvider.overrideWith((ref) => false),
              timerAnnouncerProvider.overrideWithValue(_SilentAnnouncer()),
              ...extraOverrides,
            ],
            child: MaterialApp(
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              locale: const Locale('en'),
              supportedLocales: AppLocalizations.supportedLocales,
              home: const TimerPage(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Scenario 1: App bar icon
      final appBarEvents = <String>[];
      AnalyticsService.setTestObserver((name, _) => appBarEvents.add(name));
      final settings = _baseSettings();
      final summary = _summaryWithWorkoutGap();
      await pumpTimerPage(settings: settings, summary: summary);

      await tester.tap(find.byTooltip('Open Workout Navigator'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(WorkoutNavigatorPage), findsOneWidget);
      expect(appBarEvents.contains('workout_navigator_open'), isTrue);
      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      AnalyticsService.setTestObserver(null);

      // Clear tree before next scenario.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      // Scenario 2: Coach card action
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final coachEvents = <String, List<Map<String, Object?>>>{
        'coach_action': <Map<String, Object?>>[],
        'workout_navigator_open': <Map<String, Object?>>[],
        'workout_quick_card_tap': <Map<String, Object?>>[],
      };
      AnalyticsService.setTestObserver((name, params) {
        coachEvents
            .putIfAbsent(name, () => <Map<String, Object?>>[])
            .add(params);
      });

      await pumpTimerPage(
        settings: _baseSettings(),
        summary: _summaryWithWorkoutGap(),
      );

      await tester.pump(const Duration(milliseconds: 100));
      final workoutCardFinder = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_WorkoutQuickCard',
      );
      final quickCardWidget = tester.widget(workoutCardFinder);
      // ignore: avoid_dynamic_calls
      (quickCardWidget as dynamic).onOpen();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(WorkoutNavigatorPage), findsOneWidget);
      expect(coachEvents['workout_quick_card_tap']?.isNotEmpty, isTrue);
      expect(coachEvents['workout_navigator_open']?.isNotEmpty, isTrue);
      final sourceValues = coachEvents['workout_navigator_open']!
          .map((event) => event['source'])
          .toList();
      expect(sourceValues, contains('quick_card'));
      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      AnalyticsService.setTestObserver(null);
    },
  );
}
