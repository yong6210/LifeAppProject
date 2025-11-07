import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/features/timer/timer_controller.dart';
import 'package:life_app/features/workout/models/workout_navigator_models.dart';
import 'package:life_app/features/workout/workout_navigator_controller.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/services/analytics/analytics_service.dart';

class WorkoutNavigatorPage extends ConsumerStatefulWidget {
  const WorkoutNavigatorPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const WorkoutNavigatorPage(),
    );
  }

  @override
  ConsumerState<WorkoutNavigatorPage> createState() =>
      _WorkoutNavigatorPageState();
}

class _WorkoutNavigatorPageState extends ConsumerState<WorkoutNavigatorPage> {
  final Map<String, bool> _checklistState = {};
  List<_ChecklistItem> _checklistItems(AppLocalizations l10n) => [
    _ChecklistItem(
      id: 'hydrate',
      label: l10n.tr('workoutNavigatorChecklistHydrate'),
    ),
    _ChecklistItem(
      id: 'warmup',
      label: l10n.tr('workoutNavigatorChecklistWarmup'),
    ),
    _ChecklistItem(id: 'gear', label: l10n.tr('workoutNavigatorChecklistGear')),
    _ChecklistItem(
      id: 'volume',
      label: l10n.tr('workoutNavigatorChecklistVolume'),
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workoutNavigatorProvider.notifier).restore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final navigatorState = ref.watch(workoutNavigatorProvider);
    final recommendation = navigatorState.recommendation;
    final theme = Theme.of(context);
    final navigator = Navigator.of(context);
    final checklistItems = _checklistItems(l10n);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tr('workoutNavigatorTitle'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            l10n.tr('workoutNavigatorChooseActivity'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SelectableCard(
                  isSelected:
                      navigatorState.discipline == WorkoutDiscipline.running,
                  icon: Icons.directions_run,
                  title: l10n.tr('workoutNavigatorRunLabel'),
                  subtitle: l10n.tr('workoutNavigatorRunSubtitle'),
                  onTap: () => ref
                      .read(workoutNavigatorProvider.notifier)
                      .setDiscipline(WorkoutDiscipline.running),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SelectableCard(
                  isSelected:
                      navigatorState.discipline == WorkoutDiscipline.cycling,
                  icon: Icons.directions_bike,
                  title: l10n.tr('workoutNavigatorRideLabel'),
                  subtitle: l10n.tr('workoutNavigatorRideSubtitle'),
                  onTap: () => ref
                      .read(workoutNavigatorProvider.notifier)
                      .setDiscipline(WorkoutDiscipline.cycling),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.65,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.cloud_outlined,
                    size: 28,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.tr('workoutNavigatorConditionsTitle'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.tr('workoutNavigatorConditionsSubtitle'),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.tr('workoutNavigatorIntensity'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: WorkoutIntensity.values
                .map((intensity) {
                  return _SelectableCard(
                    isSelected: navigatorState.intensity == intensity,
                    icon: _iconForIntensity(intensity),
                    title: _labelForIntensity(l10n, intensity),
                    subtitle: _descriptionForIntensity(l10n, intensity),
                    onTap: () => ref
                        .read(workoutNavigatorProvider.notifier)
                        .setIntensity(intensity),
                    dense: true,
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.tr('workoutNavigatorGoal'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<WorkoutTargetType>(
            segments: [
              ButtonSegment(
                value: WorkoutTargetType.distance,
                label: Text(l10n.tr('workoutNavigatorTargetDistance')),
                icon: const Icon(Icons.route_outlined),
              ),
              ButtonSegment(
                value: WorkoutTargetType.duration,
                label: Text(l10n.tr('workoutNavigatorTargetDuration')),
                icon: const Icon(Icons.timer_outlined),
              ),
            ],
            selected: <WorkoutTargetType>{navigatorState.targetType},
            onSelectionChanged: (selection) {
              ref
                  .read(workoutNavigatorProvider.notifier)
                  .setTargetType(selection.first);
            },
          ),
          const SizedBox(height: 12),
          _GoalPresetChips(
            l10n: l10n,
            discipline: navigatorState.discipline,
            targetType: navigatorState.targetType,
            distanceKm: navigatorState.distanceKm,
            durationMinutes: navigatorState.durationMinutes,
            onDistanceSelected: (value) => ref
                .read(workoutNavigatorProvider.notifier)
                .setDistanceKm(value),
            onDurationSelected: (value) => ref
                .read(workoutNavigatorProvider.notifier)
                .setDurationMinutes(value),
          ),
          const SizedBox(height: 12),
          if (navigatorState.targetType == WorkoutTargetType.distance)
            _SliderTile(
              label: l10n.tr('workoutNavigatorSliderDistanceLabel'),
              value: navigatorState.distanceKm,
              min: 2,
              max: 20,
              divisions: 18,
              valueFormatter: (value) => l10n.tr('workoutNavigatorUnitKm', {
                'value': value.toStringAsFixed(1),
              }),
              onChanged: (value) => ref
                  .read(workoutNavigatorProvider.notifier)
                  .setDistanceKm(value),
            )
          else
            _SliderTile(
              label: l10n.tr('workoutNavigatorSliderDurationLabel'),
              value: navigatorState.durationMinutes,
              min: 20,
              max: 90,
              divisions: 14,
              valueFormatter: (value) => l10n.tr(
                'workoutNavigatorUnitMinutes',
                {'value': value.toStringAsFixed(0)},
              ),
              onChanged: (value) => ref
                  .read(workoutNavigatorProvider.notifier)
                  .setDurationMinutes(value),
            ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recommendation.route.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(recommendation.route.description),
                  if (recommendation.route.mapAssetPath != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        recommendation.route.mapAssetPath!,
                        fit: BoxFit.cover,
                        height: 180,
                        width: double.infinity,
                        errorBuilder: (context, error, stack) => Container(
                          height: 180,
                          width: double.infinity,
                          color: theme.colorScheme.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: Text(
                            l10n.tr('workoutNavigatorMapPlaceholder'),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _InfoBadge(
                        icon: Icons.social_distance_outlined,
                        label: l10n.tr('workoutNavigatorUnitKm', {
                          'value': recommendation.route.distanceKm
                              .toStringAsFixed(1),
                        }),
                      ),
                      _InfoBadge(
                        icon: Icons.schedule_outlined,
                        label: l10n.tr('workoutNavigatorDurationMinutes', {
                          'minutes': recommendation.route.estimatedMinutes
                              .round()
                              .toString(),
                        }),
                      ),
                      _InfoBadge(
                        icon: Icons.bolt_outlined,
                        label: _labelForIntensity(
                          l10n,
                          recommendation.route.intensity,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.tr('workoutNavigatorTipsTitle'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...recommendation.tips.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: theme.textTheme.bodyMedium),
                          Expanded(
                            child: Text(tip, style: theme.textTheme.bodyMedium),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (recommendation.route.segments.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      l10n.tr('workoutNavigatorPlanTitle'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...recommendation.route.segments.map(
                      (segment) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_formatDuration(l10n, segment.startOffset)} – ${_formatDuration(l10n, segment.endOffset)} · ${segment.focus}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(segment.cue),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (recommendation.route.voiceCues.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      l10n.tr('workoutNavigatorVoicePreviewTitle'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...recommendation.route.voiceCues.map(
                      (cue) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '${_formatDuration(l10n, cue.offset)} · ${cue.message}',
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    value: navigatorState.voiceGuidanceEnabled,
                    onChanged: _onVoiceGuidanceChanged,
                    secondary: const Icon(Icons.record_voice_over_outlined),
                    title: Text(l10n.tr('workoutNavigatorVoiceToggle')),
                    subtitle: Text(
                      l10n.tr('workoutNavigatorVoiceToggleDescription'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ExpansionTile(
                    leading: const Icon(Icons.checklist_rtl_outlined),
                    title: Text(l10n.tr('workoutNavigatorChecklistTitle')),
                    childrenPadding: const EdgeInsets.only(
                      left: 8,
                      right: 16,
                      bottom: 12,
                    ),
                    children: [
                      for (final item in checklistItems)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(item.label),
                          value: _checklistState[item.id] ?? false,
                          onChanged: (value) {
                            setState(() {
                              _checklistState[item.id] = value ?? false;
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () =>
                        _showOfflineFallback(context, recommendation),
                    icon: const Icon(Icons.download_outlined),
                    label: Text(l10n.tr('workoutNavigatorOfflineButton')),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () async {
                      final target = navigatorState.target;
                      final checked = _checklistState.entries
                          .where((entry) => entry.value)
                          .length;
                      await AnalyticsService.logEvent(
                        'workout_navigator_start_button',
                        {
                          'route_id': recommendation.route.id,
                          'discipline': recommendation.route.discipline.name,
                          'intensity': recommendation.route.intensity.name,
                          'target_type': target.type.name,
                          'target_value': target.value,
                          'voice_guidance_enabled':
                              navigatorState.voiceGuidanceEnabled,
                          'checklist_checked_count': checked,
                        },
                      );
                      await ref
                          .read(timerControllerProvider.notifier)
                          .startNavigatorWorkout(
                            route: recommendation.route,
                            target: target,
                            voiceGuidanceEnabled:
                                navigatorState.voiceGuidanceEnabled,
                            checklistCheckedCount: checked,
                          );
                      if (!mounted) return;
                      navigator.pop();
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(l10n.tr('workoutNavigatorStartButton')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _labelForIntensity(AppLocalizations l10n, WorkoutIntensity intensity) {
    switch (intensity) {
      case WorkoutIntensity.light:
        return l10n.tr('workoutNavigatorIntensityLight');
      case WorkoutIntensity.moderate:
        return l10n.tr('workoutNavigatorIntensityModerate');
      case WorkoutIntensity.vigorous:
        return l10n.tr('workoutNavigatorIntensityVigorous');
    }
  }

  IconData _iconForIntensity(WorkoutIntensity intensity) {
    switch (intensity) {
      case WorkoutIntensity.light:
        return Icons.spa_outlined;
      case WorkoutIntensity.moderate:
        return Icons.insights_outlined;
      case WorkoutIntensity.vigorous:
        return Icons.whatshot_outlined;
    }
  }

  String _descriptionForIntensity(
    AppLocalizations l10n,
    WorkoutIntensity intensity,
  ) {
    switch (intensity) {
      case WorkoutIntensity.light:
        return l10n.tr('workoutNavigatorIntensityLightDescription');
      case WorkoutIntensity.moderate:
        return l10n.tr('workoutNavigatorIntensityModerateDescription');
      case WorkoutIntensity.vigorous:
        return l10n.tr('workoutNavigatorIntensityVigorousDescription');
    }
  }

  Future<void> _showOfflineFallback(
    BuildContext context,
    WorkoutNavigatorRecommendation recommendation,
  ) {
    final l10n = context.l10n;
    return showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.tr('workoutNavigatorOfflineTitle'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  recommendation.route.offlineSummary,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(AppLocalizations l10n, Duration duration) {
    final totalMinutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    if (seconds == 0) {
      return l10n.tr('workoutNavigatorDurationMinutes', {
        'minutes': totalMinutes.toString(),
      });
    }
    final secondsLabel = seconds.toString().padLeft(2, '0');
    return l10n.tr('workoutNavigatorDurationMinutesSeconds', {
      'minutes': totalMinutes.toString(),
      'seconds': secondsLabel,
    });
  }

  Future<void> _onVoiceGuidanceChanged(bool value) async {
    await ref.read(workoutNavigatorProvider.notifier).setVoiceGuidance(value);
    final navigatorState = ref.read(workoutNavigatorProvider);
    await AnalyticsService.logEvent('workout_navigator_voice_toggle', {
      'enabled': value,
      'discipline': navigatorState.discipline.name,
      'intensity': navigatorState.intensity.name,
      'target_type': navigatorState.targetType.name,
      'target_value': navigatorState.targetType == WorkoutTargetType.distance
          ? navigatorState.distanceKm
          : navigatorState.durationMinutes,
    });
  }
}

class _GoalPresetChips extends StatelessWidget {
  const _GoalPresetChips({
    required this.l10n,
    required this.discipline,
    required this.targetType,
    required this.distanceKm,
    required this.durationMinutes,
    required this.onDistanceSelected,
    required this.onDurationSelected,
  });

  final AppLocalizations l10n;
  final WorkoutDiscipline discipline;
  final WorkoutTargetType targetType;
  final double distanceKm;
  final double durationMinutes;
  final ValueChanged<double> onDistanceSelected;
  final ValueChanged<double> onDurationSelected;

  @override
  Widget build(BuildContext context) {
    final presets = targetType == WorkoutTargetType.distance
        ? _distancePresets(discipline)
        : _durationPresets(discipline);
    final selectedValue = targetType == WorkoutTargetType.distance
        ? distanceKm
        : durationMinutes;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presets
          .map(
            (value) => ChoiceChip(
              label: Text(
                targetType == WorkoutTargetType.distance
                    ? l10n.tr('workoutNavigatorUnitKm', {
                        'value': value.toStringAsFixed(0),
                      })
                    : l10n.tr('workoutNavigatorUnitMinutes', {
                        'value': value.toStringAsFixed(0),
                      }),
              ),
              selected: (selectedValue - value).abs() < 0.01,
              onSelected: (_) {
                if (targetType == WorkoutTargetType.distance) {
                  onDistanceSelected(value);
                } else {
                  onDurationSelected(value);
                }
              },
            ),
          )
          .toList(growable: false),
    );
  }

  List<double> _distancePresets(WorkoutDiscipline discipline) {
    if (discipline == WorkoutDiscipline.running) {
      return const [3, 5, 10];
    }
    return const [10, 15, 25];
  }

  List<double> _durationPresets(WorkoutDiscipline discipline) {
    if (discipline == WorkoutDiscipline.running) {
      return const [20, 30, 45];
    }
    return const [30, 45, 60];
  }
}

class _SelectableCard extends StatelessWidget {
  const _SelectableCard({
    required this.isSelected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.dense = false,
  });

  final bool isSelected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = theme.colorScheme.primaryContainer;
    final baseColor = theme.colorScheme.surfaceContainerHighest;

    return Material(
      color: isSelected ? selectedColor : baseColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: dense ? 14 : 20,
          ),
          child: Row(
            crossAxisAlignment: dense
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Icon(icon, size: dense ? 22 : 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChecklistItem {
  const _ChecklistItem({required this.id, required this.label});

  final String id;
  final String label;
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.valueFormatter,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    final displayValue = valueFormatter != null
        ? valueFormatter!(value)
        : value.toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            Text(displayValue),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: displayValue,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 18), const SizedBox(width: 6), Text(label)],
      ),
    );
  }
}
