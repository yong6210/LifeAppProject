import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/providers/remote_config_providers.dart';

/// Feature flag provider for the sleep sound analysis proof-of-concept.
final sleepSoundFeatureEnabledProvider = Provider<bool>((ref) {
  final remoteConfig = ref.watch(remoteConfigProvider);
  return remoteConfig.maybeWhen(
    data: (snapshot) => snapshot.sleepSoundEnabled ?? true,
    orElse: () => true,
  );
});
