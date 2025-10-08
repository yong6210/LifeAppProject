import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:life_app/firebase_options.dart' as staging_options;
import 'package:life_app/firebase_options_dev.dart' as dev_options;
import 'package:life_app/firebase_options_prod.dart' as prod_options;
import 'package:life_app/firebase_options_staging.dart'
    as staging_named_options;

const String _flavor = String.fromEnvironment(
  'FLAVOR',
  defaultValue: 'staging',
);

FirebaseOptions firebaseOptionsForCurrentFlavor() {
  if (kIsWeb) {
    throw UnsupportedError(
      'Firebase web configuration is not set up. Run flutterfire configure for web.',
    );
  }

  switch (_flavor) {
    case 'dev':
      return dev_options.DefaultFirebaseOptions.currentPlatform;
    case 'prod':
      return prod_options.DefaultFirebaseOptions.currentPlatform;
    case 'staging':
      return staging_named_options.DefaultFirebaseOptions.currentPlatform;
    default:
      // Fallback to the CLI-generated default to avoid crashes if FLAVOR is unknown.
      return staging_options.DefaultFirebaseOptions.currentPlatform;
  }
}

@visibleForTesting
String get currentFlavor => _flavor;
