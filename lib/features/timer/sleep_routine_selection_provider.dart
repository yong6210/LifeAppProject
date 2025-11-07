import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/features/timer/sleep_routine_models.dart';
import 'package:life_app/features/timer/sleep_routine_planner.dart';
import 'package:life_app/providers/settings_providers.dart';
import 'package:life_app/providers/stats_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SleepRoutineSelection {
  const SleepRoutineSelection({required this.goal, required this.intent});

  final SleepGoal goal;
  final SleepIntent intent;
}

class SleepRoutineSelectionNotifier
    extends AsyncNotifier<SleepRoutineSelection?> {
  static const _prefsKey = 'sleep_routine_selection_v1';

  SharedPreferences? _prefs;

  @override
  Future<SleepRoutineSelection?> build() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
    final raw = _prefs!.getString(_prefsKey);
    if (raw == null) {
      return null;
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final goalName = map['goal'] as String?;
      final intentType = map['intentType'] as String?;
      if (goalName == null || intentType == null) return null;
      final goal = SleepGoal.values.firstWhere(
        (value) => value.name == goalName,
        orElse: () => SleepGoal.standard,
      );
      final intent = intentType == SleepIntentType.duration.name
          ? SleepIntent.duration(
              Duration(minutes: (map['durationMinutes'] as num?)?.toInt() ?? 0),
            )
          : SleepIntent.wakeTime(
              DateTime.parse(
                map['wakeTime'] as String? ?? DateTime.now().toIso8601String(),
              ),
            );
      return SleepRoutineSelection(goal: goal, intent: intent);
    } catch (_) {
      return null;
    }
  }

  Future<void> setSelection(SleepGoal goal, SleepIntent intent) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'goal': goal.name,
      'intentType': intent.type.name,
    };
    if (intent.isDuration) {
      payload['durationMinutes'] = intent.duration!.inMinutes;
    } else if (intent.isWakeTime) {
      payload['wakeTime'] = intent.wakeTime!.toIso8601String();
    }
    await prefs.setString(_prefsKey, jsonEncode(payload));
    state = AsyncData(SleepRoutineSelection(goal: goal, intent: intent));
  }

  Future<void> clearSelection() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    state = const AsyncData(null);
  }
}

final sleepRoutineSelectionProvider =
    AsyncNotifierProvider<
      SleepRoutineSelectionNotifier,
      SleepRoutineSelection?
    >(SleepRoutineSelectionNotifier.new);

final sleepRoutinePlanProvider = FutureProvider<SleepRoutinePlan?>((ref) async {
  final selectionAsync = ref.watch(sleepRoutineSelectionProvider);
  final selection = selectionValueOrNull(selectionAsync);
  if (selection == null) {
    return null;
  }
  final settings = await ref.watch(settingsFutureProvider.future);
  final usageTotalsAsync = ref.watch(dailyTotalsProvider);
  final usage = usageTotalsAsync.maybeWhen(
    data: (totals) => DailyUsageContext(
      focusMinutes: totals.focusMinutes,
      restMinutes: totals.restMinutes,
      workoutMinutes: totals.workoutMinutes,
      sleepMinutes: totals.sleepMinutes,
    ),
    orElse: () => null,
  );
  final planner = SleepRoutinePlanner();
  return planner.build(
    goal: selection.goal,
    intent: selection.intent,
    settings: settings,
    usage: usage,
  );
});

SleepRoutineSelection? selectionValueOrNull(
  AsyncValue<SleepRoutineSelection?> asyncValue,
) {
  return asyncValue.asData?.value;
}

bool sleepSelectionsEqual(SleepRoutineSelection? a, SleepRoutineSelection? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  if (a.goal != b.goal) return false;
  if (a.intent.type != b.intent.type) return false;
  if (a.intent.isDuration && b.intent.isDuration) {
    return a.intent.duration == b.intent.duration;
  }
  if (a.intent.isWakeTime && b.intent.isWakeTime) {
    return a.intent.wakeTime == b.intent.wakeTime;
  }
  return false;
}
