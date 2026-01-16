import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:life_app/features/timer/widgets/sleep_analysis_result_card.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/providers/sleep_analysis_providers.dart';
import 'package:life_app/services/audio/sleep_sound_analyzer.dart';

late AppLocalizations _testLocalizations;

class _TestAppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _TestAppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(_testLocalizations);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

// A helper to pump the widget with necessary providers.
Future<void> pumpSleepCard(
  WidgetTester tester,
  Override summaryOverride,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [summaryOverride],
      child: const MaterialApp(
        localizationsDelegates: [
          _TestAppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SleepAnalysisResultCard(),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    _testLocalizations = await AppLocalizations.load(const Locale('en'));
  });

  group('SleepAnalysisResultCard', () {
    testWidgets('shows loading indicator when provider is loading',
        (tester) async {
      final completer = Completer<SleepSoundSummary?>();
      addTearDown(() {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });
      await pumpSleepCard(
        tester,
        latestSleepSoundSummaryProvider.overrideWith(
          (ref) => completer.future,
        ),
      );
      // Pump a short duration to show the loading indicator
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when provider has error', (tester) async {
      final error = Exception('Failed to load');
      await pumpSleepCard(
        tester,
        latestSleepSoundSummaryProvider.overrideWith((ref) => Future.error(error)),
      );
      await tester.pumpAndSettle(); // Settle the future
      expect(find.textContaining('Error:'), findsOneWidget);
    });

    testWidgets('shows no data message when summary is null', (tester) async {
      await pumpSleepCard(
        tester,
        latestSleepSoundSummaryProvider.overrideWith((ref) => Future.value(null)),
      );
      await tester.pumpAndSettle(); // Settle the future
      expect(find.text('No Sleep Analysis Data'), findsOneWidget);
    });

    testWidgets('shows restful state correctly', (tester) async {
      final summary = SleepSoundSummary(
        recordingPath: null,
        duration: const Duration(hours: 8),
        averageAmplitude: 0.1,
        maxAmplitude: 0.2,
        loudEventCount: 2,
        sampleCount: 100,
        restfulSampleRatio: 0.8,
      );

      await pumpSleepCard(
        tester,
        latestSleepSoundSummaryProvider.overrideWith((ref) => Future.value(summary)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mostly Restful Sleep'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.textContaining('About 384 minutes'), findsOneWidget);
      expect(find.textContaining('2 loud events'), findsOneWidget);
    });

    testWidgets('shows moderate state correctly', (tester) async {
      final summary = SleepSoundSummary(
        recordingPath: null,
        duration: const Duration(hours: 8),
        averageAmplitude: 0.2,
        maxAmplitude: 0.5,
        loudEventCount: 6,
        sampleCount: 100,
        restfulSampleRatio: 0.6,
      );

      await pumpSleepCard(
        tester,
        latestSleepSoundSummaryProvider.overrideWith((ref) => Future.value(summary)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Some Disruptions Detected'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('shows disrupted state correctly', (tester) async {
      final summary = SleepSoundSummary(
        recordingPath: null,
        duration: const Duration(hours: 8),
        averageAmplitude: 0.4,
        maxAmplitude: 0.8,
        loudEventCount: 10,
        sampleCount: 100,
        restfulSampleRatio: 0.4,
      );

      await pumpSleepCard(
        tester,
        latestSleepSoundSummaryProvider.overrideWith((ref) => Future.value(summary)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Disrupted Sleep Detected'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });
}
