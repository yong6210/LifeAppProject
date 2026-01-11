import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_app/features/timer/timer_plan.dart';
import 'package:life_app/features/timer/timer_state.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/services/accessibility/timer_announcer.dart';

late AppLocalizations _testL10n;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<BuildContext> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(key: ValueKey('l10n-host')),
      ),
    );
    await tester.pump();
    return tester.firstElement(find.byKey(const ValueKey('l10n-host')));
  }

  TimerState buildState({
    required List<TimerSegment> segments,
    required int index,
    required int segmentRemaining,
    required int remaining,
    bool isRunning = true,
  }) {
    return TimerState(
      mode: 'focus',
      segments: segments,
      currentSegmentIndex: index,
      totalSeconds: segments.fold(
        0,
        (sum, segment) => sum + segment.duration.inSeconds,
      ),
      remainingSeconds: remaining,
      segmentRemainingSeconds: segmentRemaining,
      isRunning: isRunning,
      sessionStartedAt: DateTime.now(),
      segmentStartedAt: DateTime.now(),
      isSoundEnabled: true,
      workoutPresetId: null,
    );
  }

  setUpAll(() {
    _testL10n = AppLocalizations.testing(
      translations: const {
        'timer_announcer_minutes_seconds': '{minutes}m {seconds}s',
        'timer_announcer_seconds_only': '{seconds}s',
        'timer_announcer_segment': '{segment} · {time}',
      },
    );
  });

  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(accessibleNavigation: true);
  });

  testWidgets('announces once per interval and on segment change', (
    tester,
  ) async {
    final context = await pumpHost(tester);
    final events = <String>[];
    final announcer = TimerAnnouncer(
      minInterval: const Duration(seconds: 30),
      sendAnnouncement: (_, message, __) {
        events.add(message);
        return Future<void>.value();
      },
    );

    final segments = [
      TimerSegment(
        id: 'focus_1',
        label: 'Deep focus',
        type: 'focus',
        duration: const Duration(minutes: 25),
      ),
      TimerSegment(
        id: 'rest_1',
        label: 'Short rest',
        type: 'rest',
        duration: const Duration(minutes: 5),
      ),
    ];

    final state1 = buildState(
      segments: segments,
      index: 0,
      segmentRemaining: 90,
      remaining:
          segments[0].duration.inSeconds + segments[1].duration.inSeconds,
    );

    announcer.maybeAnnounce(context: context, state: state1, l10n: _testL10n);
    announcer.maybeAnnounce(context: context, state: state1, l10n: _testL10n);

    final state2 = state1.copyWith(
      currentSegmentIndex: 1,
      segmentRemainingSeconds: 45,
      remainingSeconds: 45,
    );

    announcer.maybeAnnounce(context: context, state: state2, l10n: _testL10n);

    expect(events.length, 2);
    expect(events.first, contains('Deep focus'));
    expect(events.last, contains('Short rest'));
  });

  testWidgets('does not announce when accessibility features are disabled', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();

    final context = await pumpHost(tester);
    final events = <String>[];
    final announcer = TimerAnnouncer(
      sendAnnouncement: (_, message, __) {
        events.add(message);
        return Future<void>.value();
      },
    );
    final segments = [
      TimerSegment(
        id: 'focus_1',
        label: 'Focus',
        type: 'focus',
        duration: const Duration(minutes: 1),
      ),
    ];

    final state = buildState(
      segments: segments,
      index: 0,
      segmentRemaining: 30,
      remaining: 30,
    );

    announcer.maybeAnnounce(context: context, state: state, l10n: _testL10n);
    expect(events, isEmpty);
  });
}
