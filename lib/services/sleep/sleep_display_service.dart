import 'dart:io';

import 'package:flutter/services.dart';

abstract class SleepDisplayBridge {
  Future<void> activate({required bool dim});
  Future<void> deactivate();
}

class MethodChannelSleepDisplayBridge implements SleepDisplayBridge {
  MethodChannelSleepDisplayBridge({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'dev.life_app/sleep_display';

  final MethodChannel _channel;
  bool _active = false;

  @override
  Future<void> activate({required bool dim}) async {
    if (!_isSupportedPlatform) return;
    try {
      await _channel.invokeMethod<void>('activate', {'dim': dim});
      _active = true;
    } on MissingPluginException {
      // Ignore when platform implementation is unavailable.
    }
  }

  @override
  Future<void> deactivate() async {
    if (!_isSupportedPlatform) {
      _active = false;
      return;
    }
    if (!_active) return;
    try {
      await _channel.invokeMethod<void>('deactivate');
    } on MissingPluginException {
      // Ignore when platform implementation is unavailable.
    } finally {
      _active = false;
    }
  }

  bool get _isSupportedPlatform => Platform.isAndroid || Platform.isIOS;
}

class NoopSleepDisplayBridge implements SleepDisplayBridge {
  const NoopSleepDisplayBridge();

  @override
  Future<void> activate({required bool dim}) async {}

  @override
  Future<void> deactivate() async {}
}
