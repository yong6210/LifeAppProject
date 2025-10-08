import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_app/features/timer/timer_page.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/models/settings.dart';
import 'package:life_app/services/audio/sleep_sound_catalog.dart';

class _PreloadedLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  _PreloadedLocalizationsDelegate(this.instance);

  final AppLocalizations instance;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) => SynchronousFuture(instance);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

Future<(AppLocalizations, Finder)> _pumpSummary(
  WidgetTester tester,
  Settings settings, {
  SleepSoundCatalog? catalog,
}) async {
  final l10n = await tester.runAsync<AppLocalizations?>(
    () => AppLocalizations.load(const Locale('en')),
  );
  final resolved = l10n!;

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: [
        _PreloadedLocalizationsDelegate(resolved),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: Scaffold(
        body: Center(
          child: SleepPresetSummary(settings: settings, catalog: catalog),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (resolved, find.byType(SleepPresetSummary));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SleepPresetSummary', () {
    testWidgets('shows mixer off when levels disabled', (tester) async {
      final settings = Settings()
        ..sleepMixerWhiteLevel = 0
        ..sleepMixerPinkLevel = 0
        ..sleepMixerBrownLevel = 0
        ..sleepMixerPresetId = SleepSoundCatalog.defaultPresetId;

      final (l10n, summaryFinder) = await _pumpSummary(tester, settings);

      expect(summaryFinder, findsOneWidget);
      expect(find.text(l10n.tr('timer_sleep_sound_mix_off')), findsOneWidget);
    });

    testWidgets('shows custom ratio when default preset has levels', (
      tester,
    ) async {
      final settings = Settings()
        ..sleepMixerWhiteLevel = 0.4
        ..sleepMixerPinkLevel = 0.3
        ..sleepMixerBrownLevel = 0.2
        ..sleepMixerPresetId = SleepSoundCatalog.defaultPresetId;

      final (l10n, summaryFinder) = await _pumpSummary(tester, settings);

      expect(summaryFinder, findsOneWidget);
      final expectedText = l10n.tr('timer_sleep_sound_mix_ratio', {
        'white': '${(settings.sleepMixerWhiteLevel * 100).round()}',
        'pink': '${(settings.sleepMixerPinkLevel * 100).round()}',
        'brown': '${(settings.sleepMixerBrownLevel * 100).round()}',
      });
      expect(find.text(expectedText), findsOneWidget);
    });

    testWidgets('shows preset metadata when catalog preset selected', (
      tester,
    ) async {
      final settings = Settings()
        ..sleepMixerWhiteLevel = 0
        ..sleepMixerPinkLevel = 0
        ..sleepMixerBrownLevel = 0
        ..sleepMixerPresetId = 'rain_light';

      final catalog = SleepSoundCatalog(
        layers: {
          'rain_light': const SleepSoundLayer(
            id: 'rain_light',
            type: 'ambience',
            fallbackNoise: 'rain_light',
          ),
          'white_noise': const SleepSoundLayer(
            id: 'white_noise',
            type: 'noise',
            fallbackNoise: 'white_noise',
          ),
        },
        presets: {
          SleepSoundCatalog.defaultPresetId: SleepSoundPreset(
            id: SleepSoundCatalog.defaultPresetId,
            custom: true,
            layers: const {},
          ),
          'rain_light': SleepSoundPreset(
            id: 'rain_light',
            layers: const {'rain_light': 0.7, 'white_noise': 0.2},
          ),
        },
      );

      final (l10n, summaryFinder) = await _pumpSummary(
        tester,
        settings,
        catalog: catalog,
      );

      expect(summaryFinder, findsOneWidget);
      final presetLabel = l10n.tr('timer_sleep_sound_preset_label', {
        'preset': l10n.tr('timer_sleep_preset_rain_light'),
      });
      final layersLabel = l10n.tr('timer_sleep_sound_layers_label', {
        'layers':
            '${l10n.tr('timer_sleep_noise_rain_light')} 70% • '
            '${l10n.tr('timer_sleep_noise_white')} 20%',
      });

      expect(find.text(presetLabel), findsOneWidget);
      expect(
        find.text(l10n.tr('timer_sleep_preset_rain_light_desc')),
        findsOneWidget,
      );
      expect(find.text(layersLabel), findsOneWidget);
    });
  });
}
