import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:life_app/providers/onboarding_providers.dart';

void main() {
  group('LifestyleSelectionController', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('starts empty', () {
      expect(container.read(lifestyleSelectionProvider), isEmpty);
    });

    test('adds selection up to max and rejects extra', () {
      final notifier = container.read(lifestyleSelectionProvider.notifier);

      expect(notifier.toggle('student'), isTrue);
      expect(notifier.toggle('office'), isTrue);
      expect(
        container.read(lifestyleSelectionProvider),
        equals({'student', 'office'}),
      );

      // Third unique selection should fail.
      expect(notifier.toggle('freelancer'), isFalse);
      expect(
        container.read(lifestyleSelectionProvider),
        equals({'student', 'office'}),
      );
    });

    test('reselecting manual clears others', () {
      final notifier = container.read(lifestyleSelectionProvider.notifier);

      notifier.toggle('student');
      notifier.toggle('office');
      notifier.setSelections(['custom']);

      expect(container.read(lifestyleSelectionProvider), equals({'custom'}));
    });

    test('clear removes all selections', () {
      final notifier = container.read(lifestyleSelectionProvider.notifier);
      notifier.toggle('student');
      notifier.clear();
      expect(container.read(lifestyleSelectionProvider), isEmpty);
    });
  });
}
