import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityState {
  const AccessibilityState({required this.reducedMotion});

  final bool reducedMotion;

  AccessibilityState copyWith({bool? reducedMotion}) {
    return AccessibilityState(
      reducedMotion: reducedMotion ?? this.reducedMotion,
    );
  }
}

class AccessibilityController extends AsyncNotifier<AccessibilityState> {
  static const _prefsKeyReducedMotion = 'accessibility_reduced_motion';
  SharedPreferences? _prefs;

  @override
  Future<AccessibilityState> build() async {
    _prefs = await SharedPreferences.getInstance();
    final reducedMotion = _prefs?.getBool(_prefsKeyReducedMotion) ?? false;
    return AccessibilityState(reducedMotion: reducedMotion);
  }

  Future<void> setReducedMotion(bool value) async {
    await _prefs?.setBool(_prefsKeyReducedMotion, value);
    state = AsyncData(state.value?.copyWith(reducedMotion: value) ??
        AccessibilityState(reducedMotion: value));
  }
}
