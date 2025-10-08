import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/services/remote_config/remote_config_service.dart';

final remoteConfigProvider = FutureProvider<RemoteConfigSnapshot>((ref) async {
  return RemoteConfigService.fetch();
});
