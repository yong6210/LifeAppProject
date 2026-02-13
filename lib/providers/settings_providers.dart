import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/models/settings.dart';
import 'package:life_app/providers/db_provider.dart';
import 'package:life_app/providers/remote_config_providers.dart';
import 'package:life_app/repositories/settings_repository.dart';
import 'package:life_app/services/audio/sleep_sound_catalog.dart';
import 'package:life_app/services/remote_config/remote_config_service.dart';

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

final settingsMutationControllerProvider =
    AsyncNotifierProvider.autoDispose<SettingsMutationController, void>(
  SettingsMutationController.new,
);

class SettingsMutationController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> savePreset(Map<String, int> data) => _mutate((repo) async {
        await repo.update((s) {
          if (data.containsKey('focus')) s.focusMinutes = data['focus']!;
          if (data.containsKey('rest')) s.restMinutes = data['rest']!;
          if (data.containsKey('workout')) s.workoutMinutes = data['workout']!;
          if (data.containsKey('sleep')) s.sleepMinutes = data['sleep']!;
        });
      });

  Future<void> saveLastMode(String mode) =>
      _mutate((repo) async => repo.update((s) => s.lastMode = mode));

  Future<void> updateBackupPreferredProvider(String provider) =>
      _mutate((repo) async {
        await repo.update((s) => s.backupPreferredProvider = provider);
      });

  Future<void> setRoutinePersonalizationEnabled(bool enabled) =>
      _mutate((repo) async {
        await repo.update((s) {
          s.routinePersonalizationEnabled = enabled;
          if (!enabled) {
            s.routinePersonalizationSyncEnabled = false;
          }
          if (s.lifeBuddyTone.isEmpty) {
            s.lifeBuddyTone = 'friend';
          }
        });
      });

  Future<void> setRoutinePersonalizationSync(bool enabled) =>
      _mutate((repo) async {
        await repo.update((s) {
          if (!s.routinePersonalizationEnabled && enabled) {
            return;
          }
          s.routinePersonalizationSyncEnabled =
              enabled && s.routinePersonalizationEnabled;
        });
      });

  Future<void> setLifeBuddyTone(String tone) {
    if (tone != 'friend' && tone != 'coach') {
      throw ArgumentError.value(tone, 'tone', 'Unsupported tone option');
    }
    return _mutate((repo) async {
      await repo.update((s) => s.lifeBuddyTone = tone);
    });
  }

  Future<void> completeOnboarding() => _mutate(
        (repo) async => repo.update((s) => s.hasCompletedOnboarding = true),
      );

  Future<void> updateSleepSmartAlarm(SleepSmartAlarmInput input) =>
      _mutate((repo) async {
        await repo.update((s) {
          s.sleepSmartAlarmWindowMinutes = input.windowMinutes;
          s.sleepSmartAlarmIntervalMinutes = input.intervalMinutes;
          s.sleepSmartAlarmExactFallback = input.fallbackExact;
          s.sleepMixerWhiteLevel = input.whiteLevel;
          s.sleepMixerPinkLevel = input.pinkLevel;
          s.sleepMixerBrownLevel = input.brownLevel;
          s.sleepMixerPresetId = input.presetId;
        });
      });

  Future<void> _mutate(
    Future<void> Function(SettingsRepository repo) action,
  ) async {
    state = const AsyncValue.loading();
    final next = await AsyncValue.guard(() async {
      final repo = await ref.read(settingsRepoProvider.future);
      await action(repo);
      if (ref.mounted) {
        ref.invalidate(settingsFutureProvider);
      }
    });
    if (!ref.mounted) return;
    state = next;
  }
}

enum PaywallVariant { focusValue, backupSecurity, coachMomentum }

class PaywallExperimentConfig {
  const PaywallExperimentConfig({
    required this.variant,
    required this.experimentId,
    required this.emphasizeAnnualPlan,
  });

  final PaywallVariant variant;
  final String experimentId;
  final bool emphasizeAnnualPlan;
}

final paywallExperimentProvider = FutureProvider<PaywallExperimentConfig>((
  ref,
) async {
  RemoteConfigSnapshot? remoteConfig;
  try {
    remoteConfig = await ref.watch(remoteConfigProvider.future);
  } catch (_) {
    remoteConfig = null;
  }

  final remoteVariantString = remoteConfig?.paywallVariant;
  final remoteVariant = switch (remoteVariantString) {
    'focus_value' => PaywallVariant.focusValue,
    'backup_security' => PaywallVariant.backupSecurity,
    'coach_momentum' => PaywallVariant.coachMomentum,
    _ => null,
  };

  final variant = remoteVariant ?? await _resolveVariantByDeviceHash(ref);
  final experimentId =
      (remoteConfig?.paywallExperimentId?.trim().isNotEmpty ?? false)
          ? remoteConfig!.paywallExperimentId!.trim()
          : 'baseline_2026q1';
  final emphasizeAnnualPlan = remoteConfig?.paywallAnnualEmphasis ?? true;

  return PaywallExperimentConfig(
    variant: variant,
    experimentId: experimentId,
    emphasizeAnnualPlan: emphasizeAnnualPlan,
  );
});

Future<PaywallVariant> _resolveVariantByDeviceHash(Ref ref) async {
  final settings = await ref.watch(settingsFutureProvider.future);
  final hash = settings.deviceId.hashCode.abs();
  switch (hash % 3) {
    case 0:
      return PaywallVariant.focusValue;
    case 1:
      return PaywallVariant.backupSecurity;
    default:
      return PaywallVariant.coachMomentum;
  }
}

final paywallVariantProvider = FutureProvider<PaywallVariant>((ref) async {
  final config = await ref.watch(paywallExperimentProvider.future);
  return config.variant;
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

final appLocaleControllerProvider =
    NotifierProvider<AppLocaleController, Locale?>(AppLocaleController.new);

class AppLocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    // settingsFutureProvider의 상태를 감시하고,
    // 성공적으로 로드되면 값을 사용하여 state를 빌드합니다.
    final settings = ref.watch(settingsFutureProvider);
    return settings.when(
      data: (settings) => _decode(settings.locale),
      loading: () => null, // 로딩 중에는 이전 상태를 유지하거나 null을 반환
      error: (err, stack) => null, // 에러 발생 시 null 반환
    );
  }

  Future<void> setLocale(String code) async {
    final repo = await ref.read(settingsRepoProvider.future);
    await repo.update((s) => s.locale = code);
    // settingsFutureProvider를 무효화하면
    // build 메서드가 다시 실행되어 state가 업데이트됩니다.
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
