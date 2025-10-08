import 'package:flutter_test/flutter_test.dart';
import 'package:life_app/core/firebase/models/settings_remote.dart';
import 'package:life_app/models/settings.dart';

Settings _settingsWithMixer() {
  final settings = Settings()
    ..theme = 'dark'
    ..locale = 'en'
    ..sleepSmartAlarmWindowMinutes = 30
    ..sleepSmartAlarmIntervalMinutes = 5
    ..sleepSmartAlarmExactFallback = false
    ..sleepMixerWhiteLevel = 0.6
    ..sleepMixerPinkLevel = 0.25
    ..sleepMixerBrownLevel = 0.15
    ..sleepMixerPresetId = 'ocean_waves'
    ..focusMinutes = 42
    ..restMinutes = 7
    ..workoutMinutes = 18
    ..sleepMinutes = 50
    ..lastMode = 'sleep'
    ..schemaVersion = 3
    ..updatedAt = DateTime.utc(2025, 1, 1, 12);
  return settings;
}

void main() {
  group('SettingsRemoteDto', () {
    test('fromSettings captures sleep mixer and smart alarm fields', () {
      final settings = _settingsWithMixer();
      final dto = SettingsRemoteDto.fromSettings(settings);

      expect(
        dto.sleepSmartAlarmWindowMinutes,
        settings.sleepSmartAlarmWindowMinutes,
      );
      expect(
        dto.sleepSmartAlarmIntervalMinutes,
        settings.sleepSmartAlarmIntervalMinutes,
      );
      expect(
        dto.sleepSmartAlarmExactFallback,
        settings.sleepSmartAlarmExactFallback,
      );
      expect(dto.sleepMixerWhiteLevel, settings.sleepMixerWhiteLevel);
      expect(dto.sleepMixerPinkLevel, settings.sleepMixerPinkLevel);
      expect(dto.sleepMixerBrownLevel, settings.sleepMixerBrownLevel);
      expect(dto.sleepMixerPresetId, settings.sleepMixerPresetId);
    });

    test('fromMap falls back to existing values when fields missing', () {
      final fallback = _settingsWithMixer()
        ..sleepMixerPresetId = 'rain_light'
        ..sleepMixerWhiteLevel = 0.1
        ..sleepMixerPinkLevel = 0.2
        ..sleepMixerBrownLevel = 0.3;

      final dto = SettingsRemoteDto.fromMap({'theme': 'system'}, fallback);

      expect(dto.sleepMixerPresetId, fallback.sleepMixerPresetId);
      expect(dto.sleepMixerWhiteLevel, fallback.sleepMixerWhiteLevel);
      expect(
        dto.sleepSmartAlarmWindowMinutes,
        fallback.sleepSmartAlarmWindowMinutes,
      );
    });

    test('applyTo writes sleep mixer fields to target settings', () {
      final original = Settings();
      final dto = SettingsRemoteDto.fromSettings(_settingsWithMixer());

      dto.applyTo(original);

      expect(original.sleepMixerPresetId, 'ocean_waves');
      expect(original.sleepMixerWhiteLevel, closeTo(0.6, 1e-9));
      expect(original.sleepSmartAlarmExactFallback, isFalse);
      expect(original.sleepSmartAlarmWindowMinutes, 30);
    });
  });
}
