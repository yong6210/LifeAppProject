import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/services/accessibility/accessibility_controller.dart';

final accessibilityControllerProvider =
    AsyncNotifierProvider<AccessibilityController, AccessibilityState>(
  AccessibilityController.new,
);

final reducedMotionProvider = Provider<bool>((ref) {
  final asyncState = ref.watch(accessibilityControllerProvider);
  return asyncState.maybeWhen(
    data: (state) => state.reducedMotion,
    orElse: () => false,
  );
});
