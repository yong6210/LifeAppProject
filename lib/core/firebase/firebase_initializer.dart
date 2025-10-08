import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:life_app/core/firebase/firebase_options_factory.dart';

/// Initializes Firebase once and caches the [FirebaseApp] instance.
class FirebaseInitializer {
  FirebaseInitializer._();

  static FirebaseApp? _app;

  static Future<FirebaseApp> ensureInitialized() async {
    if (_app != null) {
      return _app!;
    }

    try {
      _app = await Firebase.initializeApp(
        options: firebaseOptionsForCurrentFlavor(),
      );
    } on UnimplementedError {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception:
              'Missing Firebase configuration. '
              'Run `flutterfire configure` to regenerate firebase_options.dart.',
        ),
      );
      rethrow;
    }

    return _app!;
  }
}
