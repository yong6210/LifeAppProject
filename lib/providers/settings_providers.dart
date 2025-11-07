import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/models/settings.dart';
import 'package:life_app/providers/db_provider.dart';
import 'package:life_app/providers/remote_config_providers.dart';
import 'package:life_app/repositories/settings_repository.dart';
import 'package:life_app/services/audio/sleep_sound_catalog.dart';

/// Isar가 열릴 때까지 정상적으로 기다리는 리포지토리
final settingsRepoProvider = FutureProvider<SettingsRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return SettingsRepository(isar);
});

/// Settings 로드
final settingsFutureProvider = FutureProvider<Settings>((ref) async {
  final repo = await ref.watch(settingsRepoProvider.future);
  return repo.get();
});

/// Sleep sound catalog manifest
final sleepSoundCatalogProvider = FutureProvider<SleepSoundCatalog>((
  ref,
) async {
  return SleepSoundCatalog.load();
});

/// 프리셋 저장
final savePresetProvider = FutureProvider.family<void, Map<String, dynamic>>((
  ref,
  data,
) async {
  final repo = await ref.watch(settingsRepoProvider.future);
  await repo.update((s) {
    if (data.containsKey('focus')) s.focusMinutes = data['focus'] as int;
    if (data.containsKey('rest')) s.restMinutes = data['rest'] as int;
    if (data.containsKey('workout')) s.workoutMinutes = data['workout'] as int;
    if (data.containsKey('sleep')) s.sleepMinutes = data['sleep'] as int;
  });
  ref.invalidate(settingsFutureProvider);
});

/// 마지막 모드 저장
final saveLastModeProvider = FutureProvider.family<void, String>((
  ref,
  mode,
) async {
  final repo = await ref.watch(settingsRepoProvider.future);
  await repo.update((s) => s.lastMode = mode);
  ref.invalidate(settingsFutureProvider);
});

final updateBackupPreferredProviderProvider =
    FutureProvider.family<void, String>((ref, provider) async {
      final repo = await ref.watch(settingsRepoProvider.future);
      await repo.update((s) => s.backupPreferredProvider = provider);
      ref.invalidate(settingsFutureProvider);
    });

final setRoutinePersonalizationEnabledProvider =
    FutureProvider.family<void, bool>((ref, enabled) async {
      final repo = await ref.watch(settingsRepoProvider.future);
      await repo.update((s) {
        s.routinePersonalizationEnabled = enabled;
        if (!enabled) {
          s.routinePersonalizationSyncEnabled = false;
        }
        if (s.lifeBuddyTone.isEmpty) {
          s.lifeBuddyTone = 'friend';
        }
      });
      ref.invalidate(settingsFutureProvider);
    });

final setRoutinePersonalizationSyncProvider = FutureProvider.family<void, bool>(
  (ref, enabled) async {
    final repo = await ref.watch(settingsRepoProvider.future);
    await repo.update((s) {
      if (!s.routinePersonalizationEnabled && enabled) {
        return;
      }
      s.routinePersonalizationSyncEnabled =
          enabled && s.routinePersonalizationEnabled;
    });
    ref.invalidate(settingsFutureProvider);
  },
);

final setLifeBuddyToneProvider = FutureProvider.family<void, String>((
  ref,
  tone,
) async {
  if (tone != 'friend' && tone != 'coach') {
    throw ArgumentError.value(tone, 'tone', 'Unsupported tone option');
  }
  final repo = await ref.watch(settingsRepoProvider.future);
  await repo.update((s) => s.lifeBuddyTone = tone);
  ref.invalidate(settingsFutureProvider);
});

final completeOnboardingProvider = FutureProvider<void>((ref) async {
  final repo = await ref.watch(settingsRepoProvider.future);
  await repo.update((s) => s.hasCompletedOnboarding = true);
  ref.invalidate(settingsFutureProvider);
});

enum PaywallVariant { focusValue, backupSecurity }

final paywallVariantProvider = FutureProvider<PaywallVariant>((ref) async {
  final remoteConfigAsync = ref.watch(remoteConfigProvider);
  final remoteVariantString = remoteConfigAsync.maybeWhen(
    data: (config) => config.paywallVariant,
    orElse: () => null,
  );
  if (remoteVariantString != null) {
    switch (remoteVariantString) {
      case 'focus_value':
        return PaywallVariant.focusValue;
      case 'backup_security':
        return PaywallVariant.backupSecurity;
    }
  }

  final settings = await ref.watch(settingsFutureProvider.future);
  final hash = settings.deviceId.hashCode;
  final bucket = hash.abs() % 2;
  return bucket == 0
      ? PaywallVariant.focusValue
      : PaywallVariant.backupSecurity;
});

class SleepSmartAlarmInput {
  const SleepSmartAlarmInput({
    required this.windowMinutes,
    required this.intervalMinutes,
    required this.fallbackExact,
    required this.whiteLevel,
    required this.pinkLevel,
    required this.brownLevel,
    required this.presetId,
  });

  final int windowMinutes;
  final int intervalMinutes;
  final bool fallbackExact;
  final double whiteLevel;
  final double pinkLevel;
  final double brownLevel;
  final String presetId;
}

final updateSleepSmartAlarmProvider =
    FutureProvider.family<void, SleepSmartAlarmInput>((ref, input) async {
      final repo = await ref.watch(settingsRepoProvider.future);
      await repo.update((s) {
        s.sleepSmartAlarmWindowMinutes = input.windowMinutes;
        s.sleepSmartAlarmIntervalMinutes = input.intervalMinutes;
        s.sleepSmartAlarmExactFallback = input.fallbackExact;
        s.sleepMixerWhiteLevel = input.whiteLevel;
        s.sleepMixerPinkLevel = input.pinkLevel;
        s.sleepMixerBrownLevel = input.brownLevel;
        s.sleepMixerPresetId = input.presetId;
      });
      ref.invalidate(settingsFutureProvider);
    });

final appLocaleControllerProvider =
    NotifierProvider<AppLocaleController, Locale?>(AppLocaleController.new);

class AppLocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    unawaited(_load());
    return null;
  }

  Future<void> _load() async {
    final settings = await ref.read(settingsFutureProvider.future);
    state = _decode(settings.locale);
  }

  Future<void> setLocale(String code) async {
    final repo = await ref.read(settingsRepoProvider.future);
    await repo.update((s) => s.locale = code);
    state = _decode(code);
    ref.invalidate(settingsFutureProvider);
  }

  static Locale? _decode(String value) {
    if (value.isEmpty || value == 'system') {
      return null;
    }
    if (value.contains('_')) {
      final parts = value.split('_');
      if (parts.length >= 2) {
        return Locale(parts[0], parts[1]);
      }
    }
    return Locale(value);
  }
}
