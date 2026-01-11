import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:life_app/features/onboarding/onboarding_page.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/providers/remote_config_providers.dart';
import 'package:life_app/services/remote_config/remote_config_service.dart';
import 'package:life_app/providers/settings_providers.dart';

import '../../helpers/fake_settings_mutation_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingPage variants', () {
    testWidgets('default flow shows intro page first', (tester) async {
      await pumpOnboarding(tester, snapshot: RemoteConfigSnapshot.empty);

      final texts = _collectTexts(tester);
      expect(find.byType(OnboardingPage), findsOneWidget);

      bool containsIntro(String value) =>
          texts.any((text) => text.contains(value));

      expect(
        containsIntro('Bring every routine together') ||
            containsIntro('onboarding_intro_focus_title'),
        isTrue,
      );
      expect(
        containsIntro('Pick a starter routine') ||
            containsIntro('onboarding_persona_heading'),
        isFalse,
      );
    });

    testWidgets('persona_first variant starts with persona page', (
      tester,
    ) async {
      await pumpOnboarding(
        tester,
        snapshot: const RemoteConfigSnapshot(
          onboardingVariant: 'persona_first',
        ),
      );

      final texts = _collectTexts(tester);
      bool containsText(String value) =>
          texts.any((text) => text.contains(value));

      expect(
        containsText('Pick a starter routine') ||
            containsText('onboarding_persona_heading'),
        isTrue,
      );
      expect(
        containsText('Bring every routine together') ||
            containsText('onboarding_intro_focus_title'),
        isFalse,
      );
    });

    testWidgets('short_intro variant limits pages to intro + persona', (
      tester,
    ) async {
      await pumpOnboarding(
        tester,
        snapshot: const RemoteConfigSnapshot(onboardingVariant: 'short_intro'),
      );

      final nextButton = find.byWidgetPredicate((widget) {
        if (widget is! Text) return false;
        final value = widget.data ?? widget.textSpan?.toPlainText() ?? '';
        return value.contains('Next') ||
            value.contains('onboarding_next_button');
      });
      expect(nextButton, findsOneWidget);

      await tester.tap(nextButton);
      await tester.pump();
      await tester.pumpAndSettle();

      final secondPageTexts = _collectTexts(tester);

      bool containsSecond(String value) =>
          secondPageTexts.any((text) => text.contains(value));

      expect(
        containsSecond('Pick a starter routine') ||
            containsSecond('onboarding_persona_heading'),
        isTrue,
      );
      expect(
        containsSecond('Bring every routine together') ||
            containsSecond('onboarding_intro_focus_title'),
        isFalse,
      );
    });

    testWidgets('lifestyle selection applies presets when confirmed', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      Map<String, int>? capturedPreset;
      var completeCalled = false;

      await pumpOnboarding(
        tester,
        snapshot: const RemoteConfigSnapshot(onboardingVariant: 'short_intro'),
        overrideMutationProvider: false,
        extraOverrides: [
          settingsMutationControllerProvider.overrideWith(
            () => FakeSettingsMutationController(
              onSavePreset: (data) => capturedPreset = data,
              onComplete: () => completeCalled = true,
            ),
          ),
        ],
      );

      await tester.tap(find.textContaining('Next'));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Focused study days'));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingPage), findsNothing);

      expect(completeCalled, isTrue);
      expect(capturedPreset, isNotNull);
      expect(capturedPreset!['focus'], 25);
      expect(capturedPreset!['rest'], 5);
    });
  });
}

Future<void> pumpOnboarding(
  WidgetTester tester, {
  required RemoteConfigSnapshot snapshot,
  List<Override> extraOverrides = const <Override>[],
  bool overrideMutationProvider = true,
}) async {
  final l10n = AppLocalizations.testing(translations: _testTranslations);
  final view = tester.view;
  final originalPhysicalSize = view.physicalSize;
  final originalDevicePixelRatio = view.devicePixelRatio;
  view.physicalSize = const Size(1080, 1920);
  view.devicePixelRatio = 1.0;
  addTearDown(() {
    view.physicalSize = originalPhysicalSize;
    view.devicePixelRatio = originalDevicePixelRatio;
  });

  final overrides = <Override>[
    remoteConfigProvider.overrideWith((ref) => snapshot),
    if (overrideMutationProvider)
      settingsMutationControllerProvider.overrideWith(
        () => FakeSettingsMutationController(),
      ),
    ...extraOverrides,
  ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: [
          _TestLocalizationsDelegate(l10n),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: OnboardingPage(),
      ),
    ),
  );

  // Allow the widget tree to build and localization assets to load.
  await tester.pump();
  await tester.pumpAndSettle();

  // In CI the localizations Future can take an extra frame; poll briefly.
  for (var i = 0; i < 5; i++) {
    if (find.byType(OnboardingPage).evaluate().isNotEmpty) {
      break;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
}

List<String> _collectTexts(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
}

class _TestLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _TestLocalizationsDelegate(this.l10n);

  final AppLocalizations l10n;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(l10n);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

const Map<String, String> _testTranslations = <String, String>{
  'onboarding_appbar_title': 'Get Started',
  'onboarding_intro_focus_title': 'Bring every routine together',
  'onboarding_intro_focus_body':
      'Manage focus, rest, movement, and sleep timers in one offline-first flow.',
  'onboarding_intro_backup_title': 'Keep data lightweight & safe',
  'onboarding_intro_backup_body':
      'Use light sync to restore essentials in seconds and encrypted full backups when you choose.',
  'onboarding_persona_heading': 'Pick a starter routine',
  'onboarding_persona_subtitle':
      'Customize later — we will set up baseline timers for you now.',
  'onboarding_persona_student_title': 'Focused study days',
  'onboarding_persona_student_body':
      'Stay ahead on classes with longer focus blocks and dedicated review breaks.',
  'onboarding_persona_knowledge_title': 'Creative deep work',
  'onboarding_persona_knowledge_body':
      'Blend deep work sprints with collaboration slots to recharge between sessions.',
  'onboarding_persona_wellbeing_title': 'Restorative balance',
  'onboarding_persona_wellbeing_body':
      'Lean on calming routines, recovery stretches, and gentle focus while you reset.',
  'onboarding_lifestyle_hint':
      'Select up to two lifestyles and we will tailor your starter plan.',
  'onboarding_lifestyle_selected_count': '{count}/{max} selected',
  'onboarding_lifestyle_preview_button': 'Preview plan',
  'onboarding_lifestyle_limit_reached': 'You can pick up to two lifestyles.',
  'onboarding_lifestyle_preview_title': 'Suggested starting plan',
  'onboarding_lifestyle_preview_description':
      'Here is how Life Buddy will adjust your timers based on what you picked.',
  'onboarding_lifestyle_student_title': 'Focused study days',
  'onboarding_lifestyle_student_body':
      'Stay ahead on classes with longer focus blocks and dedicated review breaks.',
  'onboarding_lifestyle_student_highlight_1':
      '45-minute deep focus with restorative micro-breaks.',
  'onboarding_lifestyle_student_highlight_2':
      'Evening wind-down reminder keeps late study sessions balanced.',
  'onboarding_lifestyle_office_title': 'Deep work & meetings',
  'onboarding_lifestyle_office_body':
      'Balance intense focus slots with mobility reminders around your workday.',
  'onboarding_lifestyle_office_highlight_1':
      'Morning 50-minute focus block plus midday reset.',
  'onboarding_lifestyle_office_highlight_2':
      'After-work unwind routine to disconnect from screens.',
  'onboarding_lifestyle_caregiver_title': 'Care & family rhythm',
  'onboarding_lifestyle_caregiver_body':
      'Keep routines flexible around care responsibilities and household tasks.',
  'onboarding_lifestyle_caregiver_highlight_1':
      'Short focus bursts paired with check-in reminders.',
  'onboarding_lifestyle_caregiver_highlight_2':
      'Longer sleep buffer with gentle wind-down guidance.',
  'onboarding_lifestyle_shift_title': 'Shift-friendly schedule',
  'onboarding_lifestyle_shift_body':
      'Rotate focus and recovery around overnight or rotating shifts.',
  'onboarding_lifestyle_shift_highlight_1':
      'Focus sessions align with your active hours, not the typical morning.',
  'onboarding_lifestyle_shift_highlight_2':
      'Pre-shift rest routine with a 38-minute sleep buffer.',
  'onboarding_lifestyle_freelancer_title': 'Flexible freelance flow',
  'onboarding_lifestyle_freelancer_body':
      'Shape your day with creative sprints, movement, and recharge breaks.',
  'onboarding_lifestyle_freelancer_highlight_1':
      'Alternate 40-minute creation blocks with stretch reminders.',
  'onboarding_lifestyle_freelancer_highlight_2':
      'Afternoon outdoor movement prompt to reset energy.',
  'onboarding_lifestyle_recovery_title': 'Recovery-first routine',
  'onboarding_lifestyle_recovery_body':
      'Prioritise rest, gentle movement, and low-intensity focus while you heal.',
  'onboarding_lifestyle_recovery_highlight_1':
      'Light focus blocks capped at 20 minutes to avoid overload.',
  'onboarding_lifestyle_recovery_highlight_2':
      'Longer sleep routine with breathing prompts and check-ins.',
  'onboarding_lifestyle_custom_title': "I'll set things myself",
  'onboarding_lifestyle_custom_body':
      'Skip the preset and adjust timers manually later.',
  'onboarding_next_button': 'Next',
  'onboarding_start_button': 'Start',
  'onboarding_progress': '{current} / {total}',
  'onboarding_preset_error': 'Failed to apply preset: {error}',
};
