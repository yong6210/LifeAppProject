import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// The plugin class for the web that bridges to JS to determine the timezone.
class FlutterNativeTimezonePlugin {
  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
      'flutter_native_timezone',
      const StandardMethodCodec(),
      registrar,
    );
    final FlutterNativeTimezonePlugin instance = FlutterNativeTimezonePlugin();
    channel.setMethodCallHandler(instance.handleMethodCall);
  }

  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'getLocalTimezone':
        return _getLocalTimeZone();
      case 'getAvailableTimezones':
        return <String>[_getLocalTimeZone()];
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details:
              "The flutter_native_timezone plugin for web doesn't implement "
              "the method '${call.method}'",
        );
    }
  }

  String _getLocalTimeZone() {
    final options = _dateTimeFormat().resolvedOptions();
    final timeZone = options.timeZone.toDart;
    if (timeZone.isNotEmpty) {
      return timeZone;
    }
    throw StateError('Unable to determine local timezone from the browser.');
  }
}

@JS('Intl.DateTimeFormat')
external JsDateTimeFormat _dateTimeFormat();

@JS()
@staticInterop
class JsDateTimeFormat {}

extension JsDateTimeFormatExtension on JsDateTimeFormat {
  external JsResolvedOptions resolvedOptions();
}

@JS()
@staticInterop
class JsResolvedOptions {}

extension JsResolvedOptionsExtension on JsResolvedOptions {
  external JSString get timeZone;
}
