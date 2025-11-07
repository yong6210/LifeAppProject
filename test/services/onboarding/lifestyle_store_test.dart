import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:life_app/services/onboarding/lifestyle_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('returns empty snapshot when nothing saved', () async {
    final snapshot = await LifestylePreferenceStore.load();
    expect(snapshot.preferences, isEmpty);
    expect(snapshot.version, 1);
    expect(snapshot.updatedAt, isNull);
  });

  test('saves and loads lifestyle selections', () async {
    final now = DateTime.now();
    final serialized = jsonEncode({
      'preferences': ['student', 'office'],
      'version': 1,
      'updatedAt': now.toIso8601String(),
    });
    SharedPreferences.setMockInitialValues({
      'lifestyle_preferences_v1': serialized,
    });

    var snapshot = await LifestylePreferenceStore.load();
    expect(snapshot.preferences, equals(['student', 'office']));

    await LifestylePreferenceStore.save(['student', 'shift']);
    snapshot = await LifestylePreferenceStore.load();
    expect(snapshot.preferences, equals(['student', 'shift']));
    expect(snapshot.updatedAt, isNotNull);
  });
}
