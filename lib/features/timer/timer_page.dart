import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/features/timer/timer_controller.dart';
import 'package:life_app/features/timer/timer_state.dart';
import 'package:life_app/features/timer/timer_plan.dart';
import 'package:life_app/models/settings.dart';
import 'package:life_app/providers/session_providers.dart';
import 'package:life_app/providers/settings_providers.dart';
import 'package:life_app/providers/accessibility_providers.dart';
import 'package:life_app/services/accessibility/timer_announcer.dart';
import 'package:life_app/services/permission_service.dart';
import 'package:life_app/services/subscription/revenuecat_service.dart';
import 'package:life_app/services/analytics/analytics_service.dart';
import 'package:life_app/features/backup/backup_page.dart';
import 'package:life_app/features/community/community_challenges_page.dart';
import 'package:life_app/features/stats/stats_page.dart';
import 'package:life_app/features/subscription/paywall_page.dart';
import 'package:life_app/features/wearable/wearable_insights_page.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/services/audio/sleep_sound_catalog.dart';

const _sleepPresetOrder = <String>[
  SleepSoundCatalog.defaultPresetId,
  'rain_light',
  'rain_heavy',
  'forest_birds',
  'ocean_waves',
  'fireplace_cozy',
];

enum CoachAction { backup, startFocus, startRest, viewStats, none }

class CoachNudge {
  CoachNudge({
    required this.title,
    required this.message,
    required this.icon,
    required this.action,
    this.actionLabel,
  });

  final String title;
  final String message;
  final IconData icon;
  final CoachAction action;
  final String? actionLabel;

  bool get hasAction => action != CoachAction.none;
}

String _sleepPresetLabel(AppLocalizations l10n, String id) {
  final key = 'timer_sleep_preset_$id';
  final value = l10n.tr(key);
  return value == key ? id : value;
}

String _sleepPresetDescription(AppLocalizations l10n, String id) {
  final key = 'timer_sleep_preset_${id}_desc';
  final value = l10n.tr(key);
  return value == key ? '' : value;
}

String _sleepLayerLabel(AppLocalizations l10n, String id) {
  switch (id) {
    case 'white_noise':
      return l10n.tr('timer_sleep_noise_white');
    case 'pink_noise':
      return l10n.tr('timer_sleep_noise_pink');
    case 'brown_noise':
      return l10n.tr('timer_sleep_noise_brown');
    case 'rain_light':
      return l10n.tr('timer_sleep_noise_rain_light');
    case 'rain_heavy':
      return l10n.tr('timer_sleep_noise_rain_heavy');
    case 'forest_birds':
      return l10n.tr('timer_sleep_noise_forest_birds');
    case 'ocean_waves':
      return l10n.tr('timer_sleep_noise_ocean_waves');
    case 'fireplace_cozy':
      return l10n.tr('timer_sleep_noise_fireplace');
    default:
      return id;
  }
}

String _describePresetLayers(AppLocalizations l10n, SleepSoundPreset preset) {
  return preset.layers.entries
      .where((entry) => entry.value > 0)
      .map(
        (entry) =>
            '${_sleepLayerLabel(l10n, entry.key)} ${(entry.value * 100).round()}%',
      )
      .join(' • ');
}

String _formatTime(int seconds) {
  final minutesPart = (seconds ~/ 60).toString().padLeft(2, '0');
  final secondsPart = (seconds % 60).toString().padLeft(2, '0');
  return '$minutesPart:$secondsPart';
}

String _modeLabel(String mode, AppLocalizations l10n) {
  switch (mode) {
    case 'focus':
      return l10n.tr('timer_mode_focus');
    case 'rest':
      return l10n.tr('timer_mode_rest');
    case 'workout':
      return l10n.tr('timer_mode_workout');
    case 'sleep':
      return l10n.tr('timer_mode_sleep');
    default:
      return mode;
  }
}

String _segmentTypeLabel(String type, AppLocalizations l10n) {
  switch (type) {
    case 'focus':
      return l10n.tr('session_type_focus');
    case 'rest':
      return l10n.tr('session_type_rest');
    case 'workout':
      return l10n.tr('session_type_workout');
    case 'sleep':
      return l10n.tr('session_type_sleep');
    default:
      return type;
  }
}

class TimerPage extends ConsumerStatefulWidget {
  const TimerPage({super.key, this.initialMode, this.autoStart = false});

  final String? initialMode;
  final bool autoStart;

  @override
  ConsumerState<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends ConsumerState<TimerPage> {
  bool _initialModeApplied = false;
  bool _showingFocusDndDialog = false;
  late final TimerAnnouncer _announcer = ref.read(timerAnnouncerProvider);

  @override
  void initState() {
    super.initState();
    ref.listen<TimerState>(timerControllerProvider, (previous, next) {
      final previousMode = previous?.mode ?? '';
      if (next.mode == 'focus' && previousMode != 'focus') {
        _handleFocusModeEntered();
      }
    });
    Future.microtask(() {
      if (!mounted) return;
      final current = ref.read(timerControllerProvider);
      if (current.mode == 'focus') {
        _handleFocusModeEntered();
      }
    });
  }

  @override
  void dispose() {
    _announcer.reset();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeApplyInitialMode();
  }

  void _maybeApplyInitialMode() {
    if (_initialModeApplied) return;
    final initialMode = widget.initialMode;
    if (initialMode == null) {
      _initialModeApplied = true;
      return;
    }
    _initialModeApplied = true;
    Future.microtask(() async {
      final controller = ref.read(timerControllerProvider.notifier);
      await controller.selectMode(initialMode);
      if (!mounted) return;
      if (widget.autoStart) {
        final currentState = ref.read(timerControllerProvider);
        if (!currentState.isRunning) {
          await controller.toggleStartStop();
        }
      }
    });
  }

  Future<void> _handleFocusModeEntered() async {
    if (!mounted || _showingFocusDndDialog) {
      return;
    }
    if (!Platform.isAndroid) {
      return;
    }
    _showingFocusDndDialog = true;
    var promptDisplayed = false;
    try {
      final shouldShow =
          await TimerPermissionService.shouldShowFocusDndPrompt();
      if (!shouldShow || !mounted) {
        return;
      }
      promptDisplayed = true;
      AnalyticsService.logEvent('focus_dnd_prompt', {'state': 'shown'});
      final openSettings = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          final l10n = dialogContext.l10n;
          return AlertDialog(
            icon: const Icon(Icons.do_not_disturb_on, size: 32),
            title: Text(l10n.tr('timer_focus_dnd_prompt_title')),
            content: Text(l10n.tr('timer_focus_dnd_prompt_message')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.tr('timer_focus_dnd_prompt_later')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.tr('timer_focus_dnd_prompt_action')),
              ),
            ],
          );
        },
      );
      if (!mounted) {
        return;
      }
      if (openSettings == true) {
        AnalyticsService.logEvent('focus_dnd_prompt', {
          'state': 'open_settings',
        });
        await TimerPermissionService.openNotificationPolicySettings();
      } else {
        AnalyticsService.logEvent('focus_dnd_prompt', {'state': 'dismissed'});
      }
    } finally {
      if (promptDisplayed) {
        await TimerPermissionService.markFocusDndPromptAcknowledged();
        if (mounted) {
          ref.invalidate(timerPermissionStatusProvider);
        }
      }
      _showingFocusDndDialog = false;
    }
  }

  CoachNudge? _buildCoachNudge({
    required AppLocalizations l10n,
    required Settings settings,
    TodaySummary? summary,
  }) {
    final now = DateTime.now();
    final lastBackup = settings.lastBackupAt;
    final backupDays = lastBackup == null
        ? 7
        : now.difference(lastBackup).inDays;
    if (backupDays >= 7) {
      final daysLabel = backupDays.toString();
      return CoachNudge(
        title: l10n.tr('timer_coach_backup_title'),
        message: l10n.tr('timer_coach_backup_message', {'days': daysLabel}),
        icon: Icons.cloud_upload,
        action: CoachAction.backup,
        actionLabel: l10n.tr('timer_coach_backup_action'),
      );
    }

    if (summary != null) {
      final focusGoal = settings.focusMinutes.clamp(10, 240);
      if (summary.focus < focusGoal) {
        final remaining = (focusGoal - summary.focus).clamp(1, 240);
        return CoachNudge(
          title: l10n.tr('timer_coach_focus_title'),
          message: l10n.tr('timer_coach_focus_message', {
            'minutes': '$remaining',
          }),
          icon: Icons.timer,
          action: CoachAction.startFocus,
          actionLabel: l10n.tr('timer_coach_focus_action'),
        );
      }

      final restGoal = settings.restMinutes.clamp(3, 30);
      if (summary.rest < restGoal) {
        final remaining = (restGoal - summary.rest).clamp(3, 45);
        return CoachNudge(
          title: l10n.tr('timer_coach_rest_title'),
          message: l10n.tr('timer_coach_rest_message', {
            'minutes': '$remaining',
          }),
          icon: Icons.self_improvement,
          action: CoachAction.startRest,
          actionLabel: l10n.tr('timer_coach_rest_action'),
        );
      }
    }

    return CoachNudge(
      title: l10n.tr('timer_coach_default_title'),
      message: l10n.tr('timer_coach_default_message'),
      icon: Icons.insights,
      action: CoachAction.viewStats,
      actionLabel: l10n.tr('timer_coach_default_action'),
    );
  }

  Future<void> _handleCoachAction(CoachAction action) async {
    AnalyticsService.logEvent('coach_action', {'action': action.name});
    final controller = ref.read(timerControllerProvider.notifier);
    switch (action) {
      case CoachAction.backup:
        if (!mounted) return;
        await Navigator.push<void>(
          context,
          MaterialPageRoute<void>(builder: (_) => const BackupPage()),
        );
        break;
      case CoachAction.startFocus:
        await controller.selectMode('focus');
        final current = ref.read(timerControllerProvider);
        if (!current.isRunning) {
          await controller.toggleStartStop();
        }
        break;
      case CoachAction.startRest:
        await controller.selectMode('rest');
        final current = ref.read(timerControllerProvider);
        if (!current.isRunning) {
          await controller.toggleStartStop();
        }
        break;
      case CoachAction.viewStats:
        if (!mounted) return;
        await Navigator.push<void>(
          context,
          MaterialPageRoute<void>(builder: (_) => const StatsPage()),
        );
        break;
      case CoachAction.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final l10n = context.l10n;
    final state = ref.watch(timerControllerProvider);
    final controller = ref.read(timerControllerProvider.notifier);
    final currentSegment = state.currentSegment;
    final permissionStatus = ref.watch(timerPermissionStatusProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final announcer = ref.watch(timerAnnouncerProvider);
    final todaySummaryAsync = ref.watch(todaySummaryProvider);
    final TodaySummary? todaySummary = todaySummaryAsync.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final settingsAsync = ref.watch(settingsFutureProvider);
    final coachNudge = settingsAsync.when<CoachNudge?>(
      data: (settings) => _buildCoachNudge(
        l10n: l10n,
        settings: settings,
        summary: todaySummary,
      ),
      loading: () => null,
      error: (_, __) => null,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (state.isRunning) {
        announcer.maybeAnnounce(context: context, state: state, l10n: l10n);
      } else {
        announcer.reset();
      }
    });

    final totalProgress = state.totalSeconds == 0
        ? 0.0
        : 1 - (state.remainingSeconds / state.totalSeconds);
    final segmentProgress = currentSegment.duration.inSeconds == 0
        ? 0.0
        : 1 -
              (state.segmentRemainingSeconds /
                  currentSegment.duration.inSeconds);

    final permissionTiles = permissionStatus.when<Widget?>(
      data: (status) {
        final tiles = <Widget>[];
        if (!status.notificationGranted) {
          tiles.add(
            _PermissionTile(
              icon: Icons.notifications_off,
              title: l10n.tr('timer_permission_notification_title'),
              message: l10n.tr('timer_permission_notification_message'),
              onPressed: () async {
                await TimerPermissionService.requestNotificationPermission(
                  context,
                );
                ref.invalidate(timerPermissionStatusProvider);
              },
              actionLabel: l10n.tr('timer_permission_notification_action'),
            ),
          );
        }
        if (!status.microphoneGranted) {
          tiles.add(
            _PermissionTile(
              icon: Icons.mic_off,
              title: l10n.tr('timer_permission_microphone_title'),
              message: l10n.tr('timer_permission_microphone_message'),
              onPressed: () async {
                await TimerPermissionService.ensureSleepSoundPermissions(
                  context,
                );
                if (!context.mounted) return;
                ref.invalidate(timerPermissionStatusProvider);
              },
              actionLabel: l10n.tr('timer_permission_microphone_action'),
            ),
          );
        }
        if (Platform.isAndroid) {
          if (!status.exactAlarmGranted) {
            tiles.add(
              _PermissionTile(
                icon: Icons.alarm_on,
                title: l10n.tr('timer_permission_exact_title'),
                message: l10n.tr('timer_permission_exact_message'),
                onPressed: () async {
                  await TimerPermissionService.openExactAlarmSettings();
                  ref.invalidate(timerPermissionStatusProvider);
                },
                actionLabel: l10n.tr('timer_permission_action_open_settings'),
              ),
            );
          }
          if (!status.dndAccessGranted) {
            tiles.add(
              _PermissionTile(
                icon: Icons.do_not_disturb_on,
                title: l10n.tr('timer_permission_dnd_title'),
                message: l10n.tr('timer_permission_dnd_message'),
                onPressed: () async {
                  await TimerPermissionService.openNotificationPolicySettings();
                  ref.invalidate(timerPermissionStatusProvider);
                },
                actionLabel: l10n.tr('timer_permission_action_open_settings'),
              ),
            );
          }
        }
        if (tiles.isEmpty) {
          return null;
        }
        return Column(children: tiles);
      },
      error: (error, _) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(l10n.tr('timer_permission_error', {'error': '$error'})),
      ),
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 12),
        child: LinearProgressIndicator(),
      ),
    );

    return WithForegroundTask(
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.tr('timer_title')),
          actions: [
            IconButton(
              tooltip: l10n.tr('wearable_title'),
              icon: const Icon(Icons.watch_rounded),
              onPressed: () async {
                await Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const WearableInsightsPage(),
                  ),
                );
              },
            ),
            IconButton(
              tooltip: l10n.tr('community_title'),
              icon: const Icon(Icons.groups_rounded),
              onPressed: () async {
                await Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const CommunityChallengesPage(),
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _ModeSelector(
                      currentMode: state.mode,
                      onSelect: controller.selectMode,
                    ),
                    const SizedBox(height: 12),
                    _PresetSelector(mode: state.mode, controller: controller),
                    if (permissionTiles != null) ...[
                      const SizedBox(height: 12),
                      permissionTiles,
                    ],
                    if (coachNudge != null) ...[
                      const SizedBox(height: 16),
                      _CoachCard(
                        nudge: coachNudge,
                        onAction: (action) => _handleCoachAction(action),
                      ),
                    ],
                    if (state.mode == 'sleep') ...[
                      const SizedBox(height: 16),
                      _SleepSmartAlarmCard(
                        onUpdated: controller.refreshCurrentPlan,
                        isPremium: isPremium,
                        onRequestPremium: () async {
                          AnalyticsService.logEvent('premium_gate', {
                            'feature': 'sleep_sound_mixer',
                          });
                          await Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const PaywallPage(),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    _TimerStatusCard(
                      segment: currentSegment,
                      segmentProgress: segmentProgress,
                      totalProgress: totalProgress,
                      state: state,
                      l10n: l10n,
                    ),
                    const SizedBox(height: 16),
                    _SoundControlsCard(
                      isSoundEnabled: state.isSoundEnabled,
                      currentProfile: currentSegment.playSoundProfile,
                      onToggle: controller.toggleSound,
                    ),
                    const SizedBox(height: 16),
                    _SegmentTimelineCard(state: state),
                    const SizedBox(height: 16),
                    const _QuickPresetEditor(),
                  ],
                ),
              ),
              _TimerControlBar(
                state: state,
                onPrevious: controller.previousSegment,
                onToggle: () async {
                  final granted =
                      await TimerPermissionService.ensureTimerPermissions(
                        context,
                      );
                  ref.invalidate(timerPermissionStatusProvider);
                  if (!granted) return;
                  await controller.toggleStartStop();
                },
                onReset: controller.reset,
                onSkip: controller.skipSegment,
                l10n: l10n,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.message,
    required this.onPressed,
    required this.actionLabel,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onPressed;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.settings),
                label: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({required this.nudge, required this.onAction});

  final CoachNudge nudge;
  final ValueChanged<CoachAction> onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Icon(nudge.icon, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nudge.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(nudge.message, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            if (nudge.hasAction && nudge.actionLabel != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => onAction(nudge.action),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(nudge.actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.currentMode, required this.onSelect});

  final String currentMode;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final modes = const ['focus', 'rest', 'workout', 'sleep'];
    final l10n = context.l10n;
    return Wrap(
      spacing: 8,
      children: [
        for (final mode in modes)
          ChoiceChip(
            selected: currentMode == mode,
            label: Text(_modeLabel(mode, l10n)),
            onSelected: (_) => onSelect(mode),
          ),
      ],
    );
  }
}

class _PresetSelector extends ConsumerWidget {
  const _PresetSelector({required this.mode, required this.controller});

  final String mode;
  final TimerController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settingsAsync = ref.watch(settingsFutureProvider);
    return settingsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) =>
          Text(l10n.tr('generic_settings_error', {'error': '$error'})),
      data: (settings) {
        final current = _modeDuration(settings, mode);
        final options = <int>{...?_presetOptions[mode]};
        options.add(current);
        final sorted = options.where((value) => value > 0).toList()..sort();
        return DropdownButtonFormField<int>(
          value: current,
          decoration: InputDecoration(
            labelText: l10n.tr('timer_preset_selector_label'),
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) async {
            if (value == null || value <= 0) return;
            await ref.read(
              savePresetProvider({_modeSettingsKey(mode): value}).future,
            );
            await controller.setPreset(mode, value);
          },
          items: [
            for (final option in sorted)
              DropdownMenuItem<int>(
                value: option,
                child: Text(_formatDurationLabel(option, l10n)),
              ),
          ],
        );
      },
    );
  }
}

class _TimerStatusCard extends StatelessWidget {
  const _TimerStatusCard({
    required this.segment,
    required this.segmentProgress,
    required this.totalProgress,
    required this.state,
    required this.l10n,
  });

  final TimerSegment segment;
  final double segmentProgress;
  final double totalProgress;
  final TimerState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(segment.labelFor(l10n), style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              width: 180,
              child: Semantics(
                label: l10n.tr('timer_status_segment_remaining'),
                value: _formatTime(state.segmentRemainingSeconds),
                liveRegion: true,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: segmentProgress.clamp(0, 1),
                      strokeWidth: 12,
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(state.segmentRemainingSeconds),
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.tr('timer_status_segment_remaining'),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.tr('timer_segment_progress_label')),
                const SizedBox(height: 4),
                LinearProgressIndicator(value: segmentProgress.clamp(0, 1)),
                const SizedBox(height: 12),
                Text(l10n.tr('timer_progress_overall')),
                const SizedBox(height: 4),
                LinearProgressIndicator(value: totalProgress.clamp(0, 1)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SoundControlsCard extends StatelessWidget {
  const _SoundControlsCard({
    required this.isSoundEnabled,
    required this.currentProfile,
    required this.onToggle,
  });

  final bool isSoundEnabled;
  final String? currentProfile;
  final Future<void> Function() onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SwitchListTile(
        value: isSoundEnabled,
        onChanged: (_) => onToggle(),
        title: Text(l10n.tr('timer_sound_switch_title')),
        subtitle: Text(
          isSoundEnabled
              ? l10n.tr('timer_sound_switch_enabled', {
                  'profile':
                      currentProfile ?? l10n.tr('timer_sound_profile_default'),
                })
              : l10n.tr('timer_sound_switch_disabled'),
          style: theme.textTheme.bodySmall,
        ),
      ),
    );
  }
}

class _SegmentTimelineCard extends StatelessWidget {
  const _SegmentTimelineCard({required this.state});

  final TimerState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tr('timer_segment_timeline_title'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final segment = state.segments[index];
                final isCurrent = index == state.currentSegmentIndex;
                final completed = index < state.currentSegmentIndex;
                final tileColor = completed
                    ? theme.colorScheme.secondaryContainer
                    : isCurrent
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surface;
                return Container(
                  decoration: BoxDecoration(
                    color: tileColor.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    selected: isCurrent,
                    leading: Icon(
                      completed
                          ? Icons.check_circle
                          : isCurrent
                          ? Icons.play_arrow
                          : Icons.circle_outlined,
                      color: isCurrent
                          ? theme.colorScheme.primary
                          : completed
                          ? Colors.green
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(segment.labelFor(l10n)),
                    subtitle: Text(
                      '${_segmentTypeLabel(segment.type, l10n)} • ${l10n.tr('session_duration_minutes', {'minutes': '${segment.duration.inMinutes}'})}',
                    ),
                    trailing: isCurrent
                        ? Text(_formatTime(state.segmentRemainingSeconds))
                        : Text(
                            l10n.tr('session_duration_minutes', {
                              'minutes': '${segment.duration.inMinutes}',
                            }),
                          ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: state.segments.length,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerControlBar extends StatelessWidget {
  const _TimerControlBar({
    required this.state,
    required this.onPrevious,
    required this.onToggle,
    required this.onReset,
    required this.onSkip,
    required this.l10n,
  });

  final TimerState state;
  final VoidCallback onPrevious;
  final Future<void> Function() onToggle;
  final VoidCallback onReset;
  final VoidCallback onSkip;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            SizedBox(
              width: 140,
              child: Semantics(
                button: true,
                label: l10n.tr('timer_button_previous'),
                child: OutlinedButton.icon(
                  onPressed: onPrevious,
                  icon: const Icon(Icons.skip_previous),
                  label: Text(l10n.tr('timer_button_previous')),
                ),
              ),
            ),
            SizedBox(
              width: 180,
              child: Semantics(
                button: true,
                label: state.isRunning
                    ? l10n.tr('timer_button_pause')
                    : l10n.tr('timer_button_start'),
                child: FilledButton.icon(
                  onPressed: onToggle,
                  icon: Icon(state.isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(
                    state.isRunning
                        ? l10n.tr('timer_button_pause')
                        : l10n.tr('timer_button_start'),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 140,
              child: Semantics(
                button: true,
                label: l10n.tr('timer_button_reset'),
                child: OutlinedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.restart_alt),
                  label: Text(l10n.tr('timer_button_reset')),
                ),
              ),
            ),
            SizedBox(
              width: 140,
              child: Semantics(
                button: true,
                label: l10n.tr('timer_button_next'),
                child: OutlinedButton.icon(
                  onPressed: onSkip,
                  icon: const Icon(Icons.skip_next),
                  label: Text(l10n.tr('timer_button_next')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const Map<String, List<int>> _presetOptions = {
  'focus': [15, 25, 40, 50],
  'rest': [5, 10, 15],
  'workout': [10, 20, 30],
  'sleep': [15, 30, 45, 60],
};

String _modeSettingsKey(String mode) {
  switch (mode) {
    case 'rest':
      return 'rest';
    case 'workout':
      return 'workout';
    case 'sleep':
      return 'sleep';
    case 'focus':
    default:
      return 'focus';
  }
}

int _modeDuration(Settings settings, String mode) {
  switch (mode) {
    case 'rest':
      return settings.restMinutes;
    case 'workout':
      return settings.workoutMinutes;
    case 'sleep':
      return settings.sleepMinutes;
    case 'focus':
    default:
      return settings.focusMinutes;
  }
}

String _formatDurationLabel(int minutes, AppLocalizations l10n) {
  return l10n.tr('session_duration_minutes', {'minutes': '$minutes'});
}

class _NoiseSlider extends StatelessWidget {
  const _NoiseSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.color,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              '${(value * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        Slider(
          min: 0,
          max: 1,
          divisions: 10,
          value: value,
          activeColor: color,
          label: '${(value * 100).round()}%',
          onChanged: onChanged,
          semanticFormatterCallback: (sliderValue) =>
              '${(sliderValue * 100).round()}%',
        ),
      ],
    );
  }
}

class SleepPresetSummary extends StatelessWidget {
  const SleepPresetSummary({required this.settings, this.catalog});

  final Settings settings;
  final SleepSoundCatalog? catalog;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final presetId = settings.sleepMixerPresetId;
    final presetName = _sleepPresetLabel(l10n, presetId);
    final totalLevel =
        settings.sleepMixerWhiteLevel +
        settings.sleepMixerPinkLevel +
        settings.sleepMixerBrownLevel;

    if (catalog == null || presetId == SleepSoundCatalog.defaultPresetId) {
      if (totalLevel == 0) {
        return Text(
          l10n.tr('timer_sleep_sound_mix_off'),
          style: theme.textTheme.bodySmall,
        );
      }
      return Text(
        l10n.tr('timer_sleep_sound_mix_ratio', {
          'white': '${(settings.sleepMixerWhiteLevel * 100).round()}',
          'pink': '${(settings.sleepMixerPinkLevel * 100).round()}',
          'brown': '${(settings.sleepMixerBrownLevel * 100).round()}',
        }),
        style: theme.textTheme.bodySmall,
      );
    }

    final preset = catalog!.presetById(presetId);
    final description = _sleepPresetDescription(l10n, presetId);
    final layers = preset.layers.entries
        .where((entry) => entry.value > 0)
        .map(
          (entry) =>
              '${_sleepLayerLabel(l10n, entry.key)} ${(entry.value * 100).round()}%',
        )
        .join(' • ');

    if (layers.isEmpty && totalLevel == 0) {
      return Text(
        l10n.tr('timer_sleep_sound_mix_off'),
        style: theme.textTheme.bodySmall,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.tr('timer_sleep_sound_preset_label', {'preset': presetName}),
          style: theme.textTheme.bodySmall,
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(description, style: theme.textTheme.bodySmall),
        ],
        if (layers.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            l10n.tr('timer_sleep_sound_layers_label', {'layers': layers}),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _SleepSmartAlarmCard extends ConsumerWidget {
  const _SleepSmartAlarmCard({
    required this.onUpdated,
    required this.isPremium,
    required this.onRequestPremium,
  });

  final Future<void> Function() onUpdated;
  final bool isPremium;
  final VoidCallback onRequestPremium;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settingsAsync = ref.watch(settingsFutureProvider);
    final reducedMotion = ref.watch(reducedMotionProvider);
    final catalogAsync = ref.watch(sleepSoundCatalogProvider);
    return settingsAsync.when(
      data: (settings) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bedtime),
                  const SizedBox(width: 8),
                  Text(
                    l10n.tr('timer_sleep_title'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      SleepSoundCatalog? catalog;
                      try {
                        catalog = await ref.read(
                          sleepSoundCatalogProvider.future,
                        );
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.tr('generic_settings_error', {
                                  'error': '$error',
                                }),
                              ),
                            ),
                          );
                        }
                      }
                      if (catalog == null) return;
                      final updated = await _showEditor(
                        context,
                        ref,
                        settings,
                        reducedMotion,
                        catalog,
                      );
                      if (updated == true) {
                        await onUpdated();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.tr('timer_sleep_update_success'),
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: Text(l10n.tr('timer_sleep_edit_button')),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (settings.sleepSmartAlarmWindowMinutes <= 0)
                Text(l10n.tr('timer_sleep_window_disabled'))
              else ...[
                Text(
                  l10n.tr('timer_sleep_window_length', {
                    'minutes': settings.sleepSmartAlarmWindowMinutes.toString(),
                  }),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.tr('timer_sleep_interval', {
                    'minutes': settings.sleepSmartAlarmIntervalMinutes
                        .toString(),
                  }),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  settings.sleepSmartAlarmExactFallback
                      ? l10n.tr('timer_sleep_fallback_on')
                      : l10n.tr('timer_sleep_fallback_off'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              if (!isPremium)
                Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: ListTile(
                    title: Text(l10n.tr('timer_sleep_premium_title')),
                    subtitle: Text(l10n.tr('timer_sleep_premium_message')),
                    trailing: FilledButton.tonal(
                      onPressed: onRequestPremium,
                      child: Text(l10n.tr('timer_sleep_premium_button')),
                    ),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.tr('timer_sleep_sound_mix_label'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    SleepPresetSummary(
                      settings: settings,
                      catalog: catalogAsync.asData?.value,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: LinearProgressIndicator(),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            context.l10n.tr('generic_settings_error', {'error': '$error'}),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showEditor(
    BuildContext context,
    WidgetRef ref,
    Settings settings,
    bool reducedMotion,
    SleepSoundCatalog catalog,
  ) async {
    var windowMinutes = settings.sleepSmartAlarmWindowMinutes.clamp(0, 120);
    var intervalMinutes = settings.sleepSmartAlarmIntervalMinutes.clamp(1, 15);
    var fallbackExact = settings.sleepSmartAlarmExactFallback;
    var whiteLevel = settings.sleepMixerWhiteLevel.clamp(0.0, 1.0);
    var pinkLevel = settings.sleepMixerPinkLevel.clamp(0.0, 1.0);
    var brownLevel = settings.sleepMixerBrownLevel.clamp(0.0, 1.0);
    var presetId = settings.sleepMixerPresetId.isEmpty
        ? SleepSoundCatalog.defaultPresetId
        : settings.sleepMixerPresetId;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, controller) {
            final sheetL10n = context.l10n;
            return StatefulBuilder(
              builder: (context, setState) {
                final availablePresetIds = _sleepPresetOrder
                    .where((id) => catalog.presets.containsKey(id))
                    .toList();
                final selectedPreset = catalog.presetById(presetId);
                final isCustomPreset = selectedPreset.custom;
                final presetDescription = _sleepPresetDescription(
                  sheetL10n,
                  presetId,
                );
                final presetLayers = _describePresetLayers(
                  sheetL10n,
                  selectedPreset,
                );
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView(
                    controller: controller,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        sheetL10n.tr('timer_sleep_edit_sheet_title'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildSwitchTile(
                        reducedMotion: reducedMotion,
                        value: windowMinutes > 0,
                        title: sheetL10n.tr('timer_sleep_edit_enable'),
                        subtitle: sheetL10n.tr(
                          'timer_sleep_edit_enable_subtitle',
                        ),
                        onChanged: (value) {
                          setState(() {
                            windowMinutes = value ? 10 : 0;
                          });
                        },
                      ),
                      if (windowMinutes > 0) ...[
                        const SizedBox(height: 12),
                        Text(
                          sheetL10n.tr('timer_sleep_edit_window_length', {
                            'minutes': '$windowMinutes',
                          }),
                        ),
                        Slider(
                          min: 5,
                          max: 60,
                          divisions: 11,
                          label: sheetL10n.tr('session_duration_minutes', {
                            'minutes': '$windowMinutes',
                          }),
                          value: windowMinutes.toDouble(),
                          onChanged: (v) {
                            setState(() {
                              windowMinutes = v.round();
                              if (windowMinutes < intervalMinutes) {
                                intervalMinutes = windowMinutes.clamp(1, 15);
                              }
                            });
                          },
                          semanticFormatterCallback: (sliderValue) =>
                              sheetL10n.tr('session_duration_minutes', {
                                'minutes': '${sliderValue.round()}',
                              }),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          sheetL10n.tr('timer_sleep_edit_interval', {
                            'minutes': '$intervalMinutes',
                          }),
                        ),
                        Slider(
                          min: 1,
                          max: 10,
                          divisions: 9,
                          value: intervalMinutes.toDouble(),
                          label: sheetL10n.tr('session_duration_minutes', {
                            'minutes': '$intervalMinutes',
                          }),
                          onChanged: (v) {
                            setState(() {
                              intervalMinutes = v.round().clamp(
                                1,
                                windowMinutes,
                              );
                            });
                          },
                          semanticFormatterCallback: (sliderValue) =>
                              sheetL10n.tr('session_duration_minutes', {
                                'minutes': '${sliderValue.round()}',
                              }),
                        ),
                        _buildSwitchTile(
                          reducedMotion: reducedMotion,
                          value: fallbackExact,
                          title: sheetL10n.tr('timer_sleep_edit_fallback'),
                          subtitle: sheetL10n.tr(
                            'timer_sleep_edit_fallback_subtitle',
                          ),
                          onChanged: (value) => setState(() {
                            fallbackExact = value;
                          }),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Divider(color: Theme.of(context).dividerColor),
                      const SizedBox(height: 12),
                      Text(
                        sheetL10n.tr('timer_sleep_edit_mix_title'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sheetL10n.tr('timer_sleep_edit_mix_body'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final id in availablePresetIds)
                            ChoiceChip(
                              label: Text(_sleepPresetLabel(sheetL10n, id)),
                              selected: presetId == id,
                              onSelected: (selected) {
                                if (!selected) return;
                                setState(() {
                                  presetId = id;
                                });
                              },
                            ),
                        ],
                      ),
                      if (!isCustomPreset && presetDescription.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            presetDescription,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      if (!isCustomPreset && presetLayers.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            sheetL10n.tr('timer_sleep_edit_preset_layers', {
                              'layers': presetLayers,
                            }),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      if (!isCustomPreset)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            sheetL10n.tr('timer_sleep_edit_mix_locked'),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                        ),
                      const SizedBox(height: 16),
                      AnimatedOpacity(
                        opacity: isCustomPreset ? 1.0 : 0.4,
                        duration: const Duration(milliseconds: 200),
                        child: IgnorePointer(
                          ignoring: !isCustomPreset,
                          child: Column(
                            children: [
                              _NoiseSlider(
                                label: sheetL10n.tr('timer_sleep_noise_white'),
                                value: whiteLevel,
                                color: Colors.blueAccent,
                                onChanged: (v) => setState(() {
                                  whiteLevel = v;
                                }),
                              ),
                              _NoiseSlider(
                                label: sheetL10n.tr('timer_sleep_noise_pink'),
                                value: pinkLevel,
                                color: Colors.pinkAccent,
                                onChanged: (v) => setState(() {
                                  pinkLevel = v;
                                }),
                              ),
                              _NoiseSlider(
                                label: sheetL10n.tr('timer_sleep_noise_brown'),
                                value: brownLevel,
                                color: Colors.brown,
                                onChanged: (v) => setState(() {
                                  brownLevel = v;
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (isCustomPreset)
                        Text(
                          (whiteLevel + pinkLevel + brownLevel) == 0
                              ? sheetL10n.tr('timer_sleep_mix_off_status')
                              : sheetL10n.tr('timer_sleep_mix_status_format', {
                                  'white': '${(whiteLevel * 100).round()}',
                                  'pink': '${(pinkLevel * 100).round()}',
                                  'brown': '${(brownLevel * 100).round()}',
                                }),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(sheetL10n.tr('dialog_cancel')),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final input = SleepSmartAlarmInput(
                                windowMinutes: windowMinutes.clamp(0, 120),
                                intervalMinutes: windowMinutes > 0
                                    ? intervalMinutes.clamp(1, windowMinutes)
                                    : 1,
                                fallbackExact: fallbackExact,
                                whiteLevel: whiteLevel,
                                pinkLevel: pinkLevel,
                                brownLevel: brownLevel,
                                presetId: presetId,
                              );
                              try {
                                await ref.read(
                                  updateSleepSmartAlarmProvider(input).future,
                                );
                                if (context.mounted) {
                                  Navigator.pop(context, true);
                                }
                              } catch (error) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        sheetL10n.tr('generic_save_error', {
                                          'error': '$error',
                                        }),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Text(sheetL10n.tr('dialog_confirm_save')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSwitchTile({
    required bool reducedMotion,
    required bool value,
    required ValueChanged<bool> onChanged,
    required String title,
    String? subtitle,
  }) {
    final subtitleWidget = subtitle != null ? Text(subtitle) : null;
    if (reducedMotion) {
      return SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(title),
        subtitle: subtitleWidget,
      );
    }
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      title: Text(title),
      subtitle: subtitleWidget,
    );
  }
}

class _QuickPresetEditor extends ConsumerWidget {
  const _QuickPresetEditor();

  Future<int?> _askMinutes(
    BuildContext context,
    String label,
    int current,
  ) async {
    final l10n = context.l10n;
    final ctrl = TextEditingController(text: current.toString());
    final val = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.tr('timer_preset_dialog_title', {'label': label})),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: l10n.tr('timer_preset_dialog_hint'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.tr('dialog_cancel')),
          ),
          TextButton(
            onPressed: () {
              final n = int.tryParse(ctrl.text.trim());
              Navigator.pop(context, n);
            },
            child: Text(l10n.tr('dialog_confirm_save')),
          ),
        ],
      ),
    );
    return val;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsFutureProvider);
    final controller = ref.read(timerControllerProvider.notifier);
    final l10n = context.l10n;

    return settingsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Text(l10n.tr('generic_settings_error', {'error': '$e'})),
      data: (s) => Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _EditChip(
            label: l10n.tr('timer_preset_label', {
              'label': l10n.tr('timer_mode_focus'),
              'minutes': '${s.focusMinutes}',
            }),
            onTap: () async {
              final n = await _askMinutes(
                context,
                l10n.tr('timer_mode_focus'),
                s.focusMinutes,
              );
              if (n == null || n <= 0) return;
              await ref.read(savePresetProvider({'focus': n}).future);
              await controller.setPreset('focus', n);
            },
          ),
          _EditChip(
            label: l10n.tr('timer_preset_label', {
              'label': l10n.tr('timer_mode_rest'),
              'minutes': '${s.restMinutes}',
            }),
            onTap: () async {
              final n = await _askMinutes(
                context,
                l10n.tr('timer_mode_rest'),
                s.restMinutes,
              );
              if (n == null || n <= 0) return;
              await ref.read(savePresetProvider({'rest': n}).future);
              await controller.setPreset('rest', n);
            },
          ),
          _EditChip(
            label: l10n.tr('timer_preset_label', {
              'label': l10n.tr('timer_mode_workout'),
              'minutes': '${s.workoutMinutes}',
            }),
            onTap: () async {
              final n = await _askMinutes(
                context,
                l10n.tr('timer_mode_workout'),
                s.workoutMinutes,
              );
              if (n == null || n <= 0) return;
              await ref.read(savePresetProvider({'workout': n}).future);
              await controller.setPreset('workout', n);
            },
          ),
          _EditChip(
            label: l10n.tr('timer_preset_label', {
              'label': l10n.tr('timer_mode_sleep'),
              'minutes': '${s.sleepMinutes}',
            }),
            onTap: () async {
              final n = await _askMinutes(
                context,
                l10n.tr('timer_mode_sleep'),
                s.sleepMinutes,
              );
              if (n == null || n <= 0) return;
              await ref.read(savePresetProvider({'sleep': n}).future);
              await controller.setPreset('sleep', n);
            },
          ),
        ],
      ),
    );
  }
}

class _EditChip extends StatelessWidget {
  const _EditChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(label: Text(label), onPressed: onTap);
  }
}
