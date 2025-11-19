import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:life_app/providers/settings_providers.dart';

/// No-op implementation of [SettingsMutationController] for tests.
class FakeSettingsMutationController extends SettingsMutationController {
  FakeSettingsMutationController({
    this.onSavePreset,
    this.onComplete,
    this.onSaveLastMode,
  });

  final void Function(Map<String, int>)? onSavePreset;
  final VoidCallback? onComplete;
  final void Function(String)? onSaveLastMode;

  @override
  FutureOr<void> build() {}

  @override
  Future<void> savePreset(Map<String, int> data) async {
    onSavePreset?.call(data);
  }

  @override
  Future<void> saveLastMode(String mode) async {
    onSaveLastMode?.call(mode);
  }

  @override
  Future<void> updateBackupPreferredProvider(String provider) async {}

  @override
  Future<void> setRoutinePersonalizationEnabled(bool enabled) async {}

  @override
  Future<void> setRoutinePersonalizationSync(bool enabled) async {}

  @override
  Future<void> setLifeBuddyTone(String tone) async {}

  @override
  Future<void> completeOnboarding() async {
    onComplete?.call();
  }

  @override
  Future<void> updateSleepSmartAlarm(SleepSmartAlarmInput input) async {}
}
