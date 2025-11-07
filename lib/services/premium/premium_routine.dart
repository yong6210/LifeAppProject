import 'package:flutter/material.dart';

enum PremiumRoutineMode { focus, rest, sleep }

typedef LocaleStringResolver = String Function(String key);

class PremiumRoutine {
  const PremiumRoutine({
    required this.id,
    required this.mode,
    required this.titleKey,
    required this.descriptionKey,
    required this.durationMinutes,
    required this.audioAsset,
    required this.previewAsset,
    this.sample = false,
    this.recommendedSlot,
  });

  final String id;
  final PremiumRoutineMode mode;
  final String titleKey;
  final String descriptionKey;
  final int durationMinutes;
  final String audioAsset;
  final String previewAsset;
  final bool sample;
  final PremiumRoutineSlot? recommendedSlot;
}

class PremiumRoutineSlot {
  const PremiumRoutineSlot({required this.labelKey, this.icon});

  final String labelKey;
  final IconData? icon;
}

class PremiumRoutineCatalog {
  const PremiumRoutineCatalog();

  List<PremiumRoutine> routinesFor(PremiumRoutineMode mode) {
    return _routines.where((routine) => routine.mode == mode).toList();
  }

  PremiumRoutine? routineById(String id) {
    for (final routine in _routines) {
      if (routine.id == id) return routine;
    }
    return null;
  }
}

const List<PremiumRoutine> _routines = [
  PremiumRoutine(
    id: 'focus_deep_work',
    mode: PremiumRoutineMode.focus,
    titleKey: 'premium_focus_deep_work_title',
    descriptionKey: 'premium_focus_deep_work_desc',
    durationMinutes: 50,
    audioAsset: 'assets/audio/premium/focus_deep_work_full.mp3',
    previewAsset: 'assets/audio/premium/focus_deep_work_preview.mp3',
    recommendedSlot: PremiumRoutineSlot(
      labelKey: 'premium_reco_morning',
      icon: Icons.wb_sunny_outlined,
    ),
  ),
  PremiumRoutine(
    id: 'focus_flow_cycle',
    mode: PremiumRoutineMode.focus,
    titleKey: 'premium_focus_flow_cycle_title',
    descriptionKey: 'premium_focus_flow_cycle_desc',
    durationMinutes: 45,
    audioAsset: 'assets/audio/premium/focus_flow_cycle.mp3',
    previewAsset: 'assets/audio/premium/focus_flow_cycle_preview.mp3',
    sample: true,
    recommendedSlot: PremiumRoutineSlot(
      labelKey: 'premium_reco_afternoon',
      icon: Icons.wb_sunny,
    ),
  ),
  PremiumRoutine(
    id: 'rest_mindful_break',
    mode: PremiumRoutineMode.rest,
    titleKey: 'premium_rest_mindful_break_title',
    descriptionKey: 'premium_rest_mindful_break_desc',
    durationMinutes: 30,
    audioAsset: 'assets/audio/premium/rest_mindful_break.mp3',
    previewAsset: 'assets/audio/premium/rest_mindful_break_preview.mp3',
    sample: true,
    recommendedSlot: PremiumRoutineSlot(
      labelKey: 'premium_reco_noon',
      icon: Icons.self_improvement,
    ),
  ),
  PremiumRoutine(
    id: 'rest_guided_unwind',
    mode: PremiumRoutineMode.rest,
    titleKey: 'premium_rest_guided_unwind_title',
    descriptionKey: 'premium_rest_guided_unwind_desc',
    durationMinutes: 25,
    audioAsset: 'https://cdn.lifeapp.com/premium/rest_guided_unwind_full.mp3',
    previewAsset: 'https://cdn.lifeapp.com/premium/rest_guided_unwind_preview.mp3',
  ),
  PremiumRoutine(
    id: 'sleep_lunar_waves',
    mode: PremiumRoutineMode.sleep,
    titleKey: 'premium_sleep_lunar_waves_title',
    descriptionKey: 'premium_sleep_lunar_waves_desc',
    durationMinutes: 40,
    audioAsset: 'https://cdn.lifeapp.com/premium/sleep_lunar_waves_full.mp3',
    previewAsset: 'https://cdn.lifeapp.com/premium/sleep_lunar_waves_preview.mp3',
    recommendedSlot: PremiumRoutineSlot(
      labelKey: 'premium_reco_night',
      icon: Icons.nightlight_round,
    ),
  ),
  PremiumRoutine(
    id: 'sleep_breath_release',
    mode: PremiumRoutineMode.sleep,
    titleKey: 'premium_sleep_breath_release_title',
    descriptionKey: 'premium_sleep_breath_release_desc',
    durationMinutes: 30,
    audioAsset: 'https://cdn.lifeapp.com/premium/sleep_breath_release_full.mp3',
    previewAsset: 'https://cdn.lifeapp.com/premium/sleep_breath_release_preview.mp3',
    sample: true,
  ),
];
