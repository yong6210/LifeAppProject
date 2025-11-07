import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/features/timer/sleep_routine_models.dart';
import 'package:life_app/features/timer/sleep_routine_planner.dart';
import 'package:life_app/features/timer/sleep_routine_selection_provider.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/models/settings.dart';
import 'package:life_app/providers/stats_providers.dart';

Future<void> showSleepRoutineBuilderSheet(
  BuildContext context,
  WidgetRef ref,
  Settings settings,
) async {
  final selectionAsync = ref.read(sleepRoutineSelectionProvider);
  final selection = selectionValueOrNull(selectionAsync);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SleepRoutineBuilderSheet(
        initialSelection: selection,
        settings: settings,
      );
    },
  );
}

class SleepRoutineBuilderSheet extends ConsumerStatefulWidget {
  const SleepRoutineBuilderSheet({
    super.key,
    required this.initialSelection,
    required this.settings,
  });

  final SleepRoutineSelection? initialSelection;
  final Settings settings;

  @override
  ConsumerState<SleepRoutineBuilderSheet> createState() =>
      _SleepRoutineBuilderSheetState();
}

class _SleepRoutineBuilderSheetState
    extends ConsumerState<SleepRoutineBuilderSheet> {
  late SleepGoal _goal;
  late SleepIntentType _intentType;
  Duration _duration = const Duration(hours: 7);
  DateTime _wakeTime = DateTime.now().add(const Duration(hours: 7));

  final _planner = SleepRoutinePlanner();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSelection;
    if (initial != null) {
      _goal = initial.goal;
      _intentType = initial.intent.type;
      if (initial.intent.isDuration && initial.intent.duration != null) {
        _duration = initial.intent.duration!;
      }
      if (initial.intent.isWakeTime && initial.intent.wakeTime != null) {
        _wakeTime = initial.intent.wakeTime!;
      }
    } else {
      _goal = SleepGoal.standard;
      _intentType = SleepIntentType.duration;
      _duration = const Duration(hours: 7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final minDuration = _planner.minimumDurationForGoal(_goal);
    final maxDuration = _planner.maximumDurationForGoal(_goal);
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
    final plan = _planner.build(
      goal: _goal,
      intent: _currentIntent(),
      settings: widget.settings,
      usage: usage,
    );

    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.tr('sleep_builder_title'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              if (widget.initialSelection != null)
                TextButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    await ref
                        .read(sleepRoutineSelectionProvider.notifier)
                        .clearSelection();
                    if (!mounted) return;
                    navigator.pop();
                  },
                  child: Text(l10n.tr('sleep_builder_clear_button')),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.tr('sleep_builder_goal_label'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: SleepGoal.values.map((goal) {
              final selected = goal == _goal;
              return ChoiceChip(
                label: Text(_goalLabel(goal, l10n)),
                selected: selected,
                onSelected: (value) {
                  if (!value) return;
                  setState(() => _goal = goal);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.tr('sleep_builder_intent_label'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(l10n.tr('sleep_builder_intent_duration')),
                selected: _intentType == SleepIntentType.duration,
                onSelected: (value) {
                  if (!value) return;
                  setState(() => _intentType = SleepIntentType.duration);
                },
              ),
              ChoiceChip(
                label: Text(l10n.tr('sleep_builder_intent_wake_time')),
                selected: _intentType == SleepIntentType.wakeTime,
                onSelected: (value) {
                  if (!value) return;
                  setState(() => _intentType = SleepIntentType.wakeTime);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_intentType == SleepIntentType.duration)
            _DurationSlider(
              min: minDuration,
              max: maxDuration,
              value: _duration,
              onChanged: (value) => setState(() => _duration = value),
            )
          else
            _WakeTimePicker(
              initial: _wakeTime,
              onChanged: (value) => setState(() => _wakeTime = value),
            ),
          const SizedBox(height: 16),
          _PlanSummary(plan: plan),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final intent = _currentIntent();
                await ref
                    .read(sleepRoutineSelectionProvider.notifier)
                    .setSelection(_goal, intent);
                if (!mounted) return;
                navigator.pop();
              },
              child: Text(l10n.tr('sleep_builder_save_button')),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  SleepIntent _currentIntent() {
    switch (_intentType) {
      case SleepIntentType.duration:
        return SleepIntent.duration(_duration);
      case SleepIntentType.wakeTime:
        return SleepIntent.wakeTime(_wakeTime);
    }
  }

  String _goalLabel(SleepGoal goal, AppLocalizations l10n) {
    switch (goal) {
      case SleepGoal.rest:
        return l10n.tr('sleep_builder_goal_rest');
      case SleepGoal.standard:
        return l10n.tr('sleep_builder_goal_standard');
      case SleepGoal.recovery:
        return l10n.tr('sleep_builder_goal_recovery');
    }
  }
}

class _DurationSlider extends StatelessWidget {
  const _DurationSlider({
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
  });

  final Duration min;
  final Duration max;
  final Duration value;
  final ValueChanged<Duration> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final minMinutes = min.inMinutes;
    final maxMinutes = max.inMinutes;
    final currentMinutes = value.inMinutes.clamp(minMinutes, maxMinutes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.tr('sleep_builder_duration_value', {
            'duration': _localizedDuration(
              context,
              Duration(minutes: currentMinutes),
            ),
          }),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Slider(
          min: minMinutes.toDouble(),
          max: maxMinutes.toDouble(),
          divisions: ((maxMinutes - minMinutes) ~/ 15).clamp(1, 200),
          value: currentMinutes.toDouble(),
          label: _localizedDuration(context, Duration(minutes: currentMinutes)),
          onChanged: (minutes) {
            final clamped = minutes.round().clamp(minMinutes, maxMinutes);
            onChanged(Duration(minutes: clamped));
          },
        ),
      ],
    );
  }
}

class _WakeTimePicker extends StatelessWidget {
  const _WakeTimePicker({required this.initial, required this.onChanged});

  final DateTime initial;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formatted = TimeOfDay.fromDateTime(initial).format(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.tr('sleep_builder_wake_time_label')),
      subtitle: Text(formatted),
      trailing: const Icon(Icons.schedule),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(initial),
        );
        if (picked == null) return;
        final now = DateTime.now();
        var next = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
        while (!next.isAfter(now)) {
          next = next.add(const Duration(days: 1));
        }
        onChanged(next);
      },
    );
  }
}

class _PlanSummary extends StatelessWidget {
  const _PlanSummary({required this.plan});

  final SleepRoutinePlan plan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = MaterialLocalizations.of(context);
    final bed = locale.formatTimeOfDay(
      TimeOfDay.fromDateTime(plan.recommendedBedTime),
    );
    final wake = locale.formatTimeOfDay(
      TimeOfDay.fromDateTime(plan.recommendedWakeTime),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.tr('sleep_builder_summary_header', {
            'bed': bed,
            'wake': wake,
            'duration': _localizedDuration(context, plan.totalDuration),
          }),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        ...plan.segments.map(
          (segment) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.nights_stay, size: 20),
            title: Text(
              l10n.tr(segment.localizationKey, segment.localizationArgs),
            ),
            trailing: Text(_localizedDuration(context, segment.duration)),
          ),
        ),
      ],
    );
  }
}

String _localizedDuration(BuildContext context, Duration duration) {
  final l10n = context.l10n;
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours > 0 && minutes > 0) {
    return l10n.tr('sleep_builder_duration_hours_minutes', {
      'hours': '$hours',
      'minutes': '$minutes',
    });
  }
  if (hours > 0) {
    return l10n.tr('sleep_builder_duration_hours_only', {'hours': '$hours'});
  }
  return l10n.tr('sleep_builder_duration_minutes_only', {
    'minutes': '$minutes',
  });
}
