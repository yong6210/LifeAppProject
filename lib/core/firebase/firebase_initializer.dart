import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:life_app/core/firebase/firebase_options_factory.dart';

/// Initializes Firebase once and caches the [FirebaseApp] instance.
class FirebaseInitializer {
  FirebaseInitializer._();

  static FirebaseApp? _app;
  static bool _available = true;

  static bool get isAvailable => _available;

  static Future<FirebaseApp?> ensureInitialized() async {
    if (_app != null) {
      return _app;
    }
    if (!_available) {
      return null;
    }

    try {
      _app = await Firebase.initializeApp(
        options: firebaseOptionsForCurrentFlavor(),
      );
    } on UnsupportedError catch (error, stack) {
      _available = false;
      final exception =
          error is UnimplementedError
              ? 'Missing Firebase configuration. '
                  'Run `flutterfire configure` to regenerate firebase_options.dart.'
              : error;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: exception,
          stack: stack,
        ),
      );
      return null;
    }

    return _app;
  }
}
