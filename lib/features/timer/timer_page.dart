import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

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
import 'package:life_app/features/workout/workout_navigator_page.dart';
import 'package:life_app/features/workout/models/workout_navigator_models.dart';
import 'package:life_app/features/workout/data/workout_routes.dart';
import 'package:life_app/features/workout/workout_light_presets.dart';
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

/// Mac/desktop 전용 레이아웃은 설계/QA가 끝난 뒤 켭니다.
const bool _enableDesktopLayout = false;

enum CoachAction { backup, startFocus, openWorkoutNavigator, viewStats, none }

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

class _FocusPresetOption {
  const _FocusPresetOption({required this.label, required this.minutes});

  final String label;
  final int minutes;
}

class _FocusPresetChips extends ConsumerWidget {
  const _FocusPresetChips({required this.settings});

  final Settings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(timerControllerProvider.notifier);
    final options = <_FocusPresetOption>[
      for (final preset in settings.presets)
        if (preset.mode == 'focus')
          _FocusPresetOption(
            label: preset.name,
            minutes: preset.durationMinutes,
          ),
    ];
    if (options.isEmpty) {
      options.addAll(const [
        _FocusPresetOption(label: '25분 포모도로', minutes: 25),
        _FocusPresetOption(label: '45분 몰입', minutes: 45),
        _FocusPresetOption(label: '90분 플로우', minutes: 90),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '빠른 집중 루틴',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: options.map((option) {
            return FilledButton.tonal(
              onPressed: () async {
                AnalyticsService.logEvent('focus_quick_preset_start', {
                  'minutes': option.minutes,
                  'label': option.label,
                });
                await controller.selectMode('focus');
                final current = ref.read(timerControllerProvider);
                if (!current.isRunning) {
                  await controller.toggleStartStop();
                }
              },
              child: Text(option.label),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _WorkoutLightPresetChips extends ConsumerWidget {
  const _WorkoutLightPresetChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final controller = ref.read(timerControllerProvider.notifier);
    final state = ref.watch(timerControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.tr('timer_workout_light_section_title'),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.tr('timer_workout_light_section_subtitle'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final double cardWidth = maxWidth > 560
                ? math.min(320.0, maxWidth / 2 - 12)
                : maxWidth;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: workoutLightPresets.map((preset) {
                final selected = state.workoutPresetId == preset.id;
                final cardColor = selected
                    ? colorScheme.primaryContainer
                    : theme.cardColor;
                final onCardColor = selected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface;
                final subtitleColor = selected
                ? colorScheme.onPrimaryContainer.withValues(alpha: 0.85)
                    : colorScheme.onSurfaceVariant;
                final accentColor = selected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.primary;

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: cardWidth,
                    minWidth: math.min(cardWidth, 220.0),
                  ),
                  child: Card(
                    color: cardColor,
                    elevation: selected ? 2 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        AnalyticsService.logEvent(
                          'workout_light_preset_start',
                          {'preset_id': preset.id},
                        );
                        await controller.startWorkoutLightPreset(preset.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.tr(preset.labelKey),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: onCardColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.tr(preset.descriptionKey, {
                                'minutes': '${preset.totalMinutes}',
                              }),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: subtitleColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 16,
                                  color: accentColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.tr('timer_workout_light_minutes', {
                                    'minutes': '${preset.totalMinutes}',
                                  }),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: accentColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
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
  TimerAnnouncer? _announcer;
  ProviderSubscription<TimerState>? _focusSubscription;

  @override
  void initState() {
    super.initState();
    _announcer = ref.read(timerAnnouncerProvider);
    _focusSubscription = ref.listenManual<TimerState>(timerControllerProvider, (
      previous,
      next,
    ) {
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
    _focusSubscription?.close();
    _announcer?.reset();
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

    final workoutGoal = settings.workoutMinutes.clamp(10, 120);
    if (summary == null || summary.workout < workoutGoal) {
      final remainingMinutes = summary == null
          ? workoutGoal
          : (workoutGoal - summary.workout).clamp(5, 120);
      return CoachNudge(
        title: l10n.tr('timer_coach_workout_title'),
        message: l10n.tr('timer_coach_workout_message', {
          'minutes': '$remainingMinutes',
        }),
        icon: Icons.directions_run,
        action: CoachAction.openWorkoutNavigator,
        actionLabel: l10n.tr('timer_coach_workout_action'),
      );
    }

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
      case CoachAction.openWorkoutNavigator:
        AnalyticsService.logEvent('workout_navigator_open', {
          'source': 'coach_card',
        });
        if (!mounted) return;
        await Navigator.push<void>(context, WorkoutNavigatorPage.route());
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

    if (_enableDesktopLayout && !(Platform.isAndroid || Platform.isIOS)) {
      return const _TimerDesktopLayout();
    }
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
    final settings = settingsAsync.asData?.value;
    final coachNudge = settingsAsync.maybeWhen(
      data: (settings) => _buildCoachNudge(
        l10n: l10n,
        settings: settings,
        summary: todaySummary,
      ),
      orElse: () => null,
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
    final featuredRoute = workoutNavigatorRoutes.first;

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

    Future<void> openWorkoutNavigatorQuick() async {
      AnalyticsService.logEvent('workout_quick_card_tap');
      AnalyticsService.logEvent('workout_navigator_open', {
        'source': 'quick_card',
      });
      if (!context.mounted) return;
      await Navigator.push<void>(context, WorkoutNavigatorPage.route());
    }

    final List<Widget> modeHeader = [
      _ModeMascot(mode: state.mode),
      const SizedBox(height: 12),
    ];
    if (settings != null) {
      switch (state.mode) {
        case 'focus':
          modeHeader
            ..add(_FocusQuickCard(settings: settings))
            ..add(const SizedBox(height: 12))
            ..add(_FocusPresetChips(settings: settings))
            ..add(const SizedBox(height: 16));
          break;
        case 'sleep':
          modeHeader
            ..add(_SleepQuickCard(settings: settings))
            ..add(const SizedBox(height: 16));
          break;
        case 'workout':
          modeHeader
            ..add(
              _WorkoutQuickCard(
                route: featuredRoute,
                onOpen: openWorkoutNavigatorQuick,
              ),
            )
            ..add(const SizedBox(height: 16))
            ..add(const _WorkoutLightPresetChips())
            ..add(const SizedBox(height: 16));
          break;
        default:
          modeHeader
            ..add(_FocusQuickCard(settings: settings))
            ..add(const SizedBox(height: 12))
            ..add(_FocusPresetChips(settings: settings))
            ..add(const SizedBox(height: 16));
          break;
      }
    } else {
      modeHeader.add(const SizedBox(height: 4));
    }

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
              tooltip: l10n.tr('timer_workout_navigator_button'),
              icon: const Icon(Icons.route_outlined),
              onPressed: () async {
                AnalyticsService.logEvent('workout_navigator_open', {
                  'source': 'app_bar',
                });
                await Navigator.push<void>(
                  context,
                  WorkoutNavigatorPage.route(),
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
                    ...modeHeader,
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
                    if (state.mode == 'workout' &&
                        state.navigatorRoute != null) ...[
                      const SizedBox(height: 16),
                      _WorkoutNavigatorOverlay(state: state),
                    ],
                    if (state.navigatorLastSummary != null) ...[
                      const SizedBox(height: 16),
                      _NavigatorSummaryCard(
                        summary: state.navigatorLastSummary!,
                      ),
                    ],
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

class _FocusQuickCard extends ConsumerWidget {
  const _FocusQuickCard({required this.settings});

  final Settings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final controller = ref.read(timerControllerProvider.notifier);
    final state = ref.watch(timerControllerProvider);
    final isActive = state.mode == 'focus';
    final isRunning = isActive && state.isRunning;
    final hasProgress = isActive && state.completedSeconds > 0;

    final primaryLabel = isRunning
        ? l10n.tr('timer_focus_card_view')
        : hasProgress
        ? l10n.tr('timer_focus_card_resume')
        : l10n.tr('timer_focus_card_start');

    Future<void> startOrResume() async {
      await controller.selectMode('focus');
      final current = ref.read(timerControllerProvider);
      if (!current.isRunning) {
        await controller.toggleStartStop();
      }
    }

    Future<void> openFocus() async {
      await controller.selectMode('focus');
    }

    final subtitle = l10n.tr('timer_focus_card_subtitle', {
      'minutes': '${settings.focusMinutes}',
    });
    final breakHint = l10n.tr('timer_focus_card_break_hint', {
      'minutes': '${settings.restMinutes}',
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.center_focus_strong_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.tr('timer_focus_card_title'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              breakHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: openFocus,
                  child: Text(l10n.tr('timer_focus_card_open')),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: isRunning ? openFocus : startOrResume,
                  child: Text(primaryLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepQuickCard extends ConsumerWidget {
  const _SleepQuickCard({required this.settings});

  final Settings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final controller = ref.read(timerControllerProvider.notifier);
    final state = ref.watch(timerControllerProvider);
    final isActive = state.mode == 'sleep';
    final windowMinutes = settings.sleepSmartAlarmWindowMinutes;
    final subtitle = l10n.tr('timer_sleep_card_subtitle', {
      'minutes': '${settings.sleepMinutes}',
    });
    final windowLabel = windowMinutes > 0
        ? l10n.tr('timer_sleep_card_window', {'minutes': '$windowMinutes'})
        : l10n.tr('timer_sleep_card_window_off');

    Future<void> openSleep() async {
      await controller.selectMode('sleep');
    }

    Future<void> startSleep() async {
      await controller.selectMode('sleep');
      final current = ref.read(timerControllerProvider);
      if (!current.isRunning) {
        await controller.toggleStartStop();
      }
    }

    final primaryLabel = isActive
        ? l10n.tr('timer_sleep_card_view')
        : l10n.tr('timer_sleep_card_cta');
    final canStartSleep = !(isActive && state.isRunning);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bedtime_outlined,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.tr('timer_sleep_card_title'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              windowLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: canStartSleep ? startSleep : null,
                  child: Text(l10n.tr('timer_sleep_card_start')),
                ),
                const SizedBox(width: 12),
                FilledButton(onPressed: openSleep, child: Text(primaryLabel)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutQuickCard extends StatelessWidget {
  const _WorkoutQuickCard({required this.route, required this.onOpen});

  final WorkoutNavigatorRoute route;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final distanceLabel = l10n.tr('timer_workout_card_distance', {
      'distance': route.distanceKm.toStringAsFixed(1),
    });
    final durationLabel = l10n.tr('timer_workout_card_duration', {
      'minutes': route.estimatedMinutes.round().toString(),
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fitness_center_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.tr('timer_workout_card_title'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tr('timer_workout_card_subtitle'),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.tr('timer_workout_card_featured'),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              route.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              route.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _InfoBadge(
                  icon: Icons.social_distance_outlined,
                  label: distanceLabel,
                ),
                _InfoBadge(icon: Icons.schedule_outlined, label: durationLabel),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(l10n.tr('timer_workout_card_cta')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeMascot extends StatefulWidget {
  const _ModeMascot({required this.mode});

  final String mode;

  @override
  State<_ModeMascot> createState() => _ModeMascotState();
}

class _ModeMascotState extends State<_ModeMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final icon = _iconFor(widget.mode);
    final baseColor = _colorFor(scheme, widget.mode);
    final title = _titleFor(widget.mode);
    final subtitle = _subtitleFor(widget.mode);
    final gradient = LinearGradient(
      colors: [
        baseColor.withValues(alpha: 0.2),
        baseColor.withValues(alpha: 0.08),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return SizedBox(
      height: 160,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * 2 * math.pi;
          final dy = math.sin(angle) * 6;
          final scale = 0.96 + (math.cos(angle) * 0.04);
          return Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(scale: scale, child: child),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 72,
                  width: 72,
                  decoration: BoxDecoration(
                    color: baseColor.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 36, color: baseColor),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.8,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String mode) {
    switch (mode) {
      case 'focus':
        return Icons.center_focus_strong_rounded;
      case 'sleep':
        return Icons.bedtime_rounded;
      case 'workout':
        return Icons.directions_run_rounded;
      default:
        return Icons.timer_rounded;
    }
  }

  Color _colorFor(ColorScheme scheme, String mode) {
    switch (mode) {
      case 'focus':
        return scheme.primary;
      case 'sleep':
        return scheme.secondary;
      case 'workout':
        return scheme.tertiary;
      default:
        return scheme.primary;
    }
  }

  String _titleFor(String mode) {
    switch (mode) {
      case 'focus':
        return '집중 세션 준비';
      case 'sleep':
        return '수면 루틴 준비';
      case 'workout':
        return '운동 세션 준비';
      default:
        return '타이머 준비';
    }
  }

  String _subtitleFor(String mode) {
    switch (mode) {
      case 'focus':
        return '원하는 루틴을 골라 바로 시작하세요.';
      case 'sleep':
        return '수면 시간과 기상 알림을 확인하세요.';
      case 'workout':
        return '코스와 목표를 확인하고 출발해요.';
      default:
        return '모드를 선택해 타이머를 시작하세요.';
    }
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

class _WorkoutNavigatorOverlay extends StatelessWidget {
  const _WorkoutNavigatorOverlay({required this.state});

  final TimerState state;

  @override
  Widget build(BuildContext context) {
    final route = state.navigatorRoute!;
    final theme = Theme.of(context);
    final now = DateTime.now();
    final elapsed = state.sessionStartedAt != null
        ? now.difference(state.sessionStartedAt!)
        : Duration.zero;
    final lastCueMessage = state.navigatorLastCueMessage;
    final lastCueAt = state.navigatorLastCueAt;
    final lastCueAgo = lastCueAt != null ? now.difference(lastCueAt) : null;
    final total = route.totalDuration > Duration.zero
        ? route.totalDuration
        : Duration(minutes: route.estimatedMinutes.round().clamp(5, 240));
    final progress = total.inSeconds == 0
        ? 0.0
        : (elapsed.inSeconds / total.inSeconds).clamp(0.0, 1.0);
    final remaining = total - elapsed;
    final nextCue = route.voiceCues
        .where((cue) => cue.offset > elapsed)
        .fold<WorkoutNavigatorCue?>(
          null,
          (previous, cue) =>
              previous == null || cue.offset < previous.offset ? cue : previous,
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(route.description),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _InfoBadge(
                      icon: Icons.social_distance_outlined,
                      label: '${route.distanceKm.toStringAsFixed(1)} km',
                    ),
                    const SizedBox(height: 8),
                    _InfoBadge(
                      icon: Icons.schedule_outlined,
                      label: '${route.estimatedMinutes.round()} min',
                    ),
                  ],
                ),
              ],
            ),
            if (route.mapAssetPath != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  route.mapAssetPath!,
                  fit: BoxFit.cover,
                  height: 160,
                  width: double.infinity,
                  errorBuilder: (context, error, stack) => Container(
                    height: 160,
                    alignment: Alignment.center,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Text(
                      'Map preview coming soon',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text(
              remaining.isNegative
                  ? 'Session complete'
                  : 'Time remaining ${_formatRemaining(remaining)}',
              style: theme.textTheme.bodySmall,
            ),
            if (state.navigatorTarget != null) ...[
              const SizedBox(height: 12),
              Text(
                state.navigatorTarget!.type == WorkoutTargetType.distance
                    ? 'Target • ${state.navigatorTarget!.value.toStringAsFixed(1)} km'
                    : 'Target • ${state.navigatorTarget!.value.toStringAsFixed(0)} min',
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.record_voice_over_outlined, size: 18),
                const SizedBox(width: 6),
                Text(
                  state.navigatorVoiceEnabled
                      ? 'Voice guidance • On'
                      : 'Voice guidance • Off',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            if (lastCueMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withValues(
                    alpha: 0.6,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last cue • ${_formatCueAgo(lastCueAgo)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(lastCueMessage),
                  ],
                ),
              ),
            ],
            if (nextCue != null) ...[
              const SizedBox(height: 12),
              Text(
                'Next cue in ${_formatRemaining(nextCue.offset - elapsed)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(nextCue.message),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (context) => SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: SingleChildScrollView(
                          child: Text(route.offlineSummary),
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.offline_pin_outlined),
                label: const Text('Offline instructions'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCueAgo(Duration? duration) {
    if (duration == null || duration.isNegative || duration.inSeconds <= 1) {
      return 'Just now';
    }
    if (duration.inMinutes == 0) {
      return '${duration.inSeconds}s ago';
    }
    if (duration.inHours == 0) {
      return '${duration.inMinutes}m ago';
    }
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (minutes == 0) {
      return '${hours}h ago';
    }
    return '${hours}h ${minutes}m ago';
  }

  String _formatRemaining(Duration duration) {
    if (duration.isNegative) {
      return '0:00';
    }
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    if (minutes >= 60) {
      final hours = duration.inHours;
      final remainingMinutes = minutes.remainder(60);
      return '${hours}h ${remainingMinutes}m';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _NavigatorSummaryCard extends StatelessWidget {
  const _NavigatorSummaryCard({required this.summary});

  final NavigatorCompletionSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    WorkoutNavigatorRoute? matchedRoute;
    for (final route in workoutNavigatorRoutes) {
      if (route.id == summary.routeId) {
        matchedRoute = route;
        break;
      }
    }

    final duration = Duration(seconds: summary.elapsedSeconds);
    final durationLabel = _formatDuration(duration);
    final voiceLabel = summary.voiceGuidanceEnabled ? 'On' : 'Off';
    final checklistLabel = summary.checklistCheckedCount == 1
        ? '1 item'
        : '${summary.checklistCheckedCount} items';
    String? targetLabel;
    if (summary.targetType != null && summary.targetValue != null) {
      targetLabel = summary.targetType == WorkoutTargetType.distance
          ? '${summary.targetValue!.toStringAsFixed(1)} km distance'
          : '${summary.targetValue!.toStringAsFixed(0)} min duration';
    }
    final completedTime = TimeOfDay.fromDateTime(summary.completedAt);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Workout navigator summary',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Completed at ${completedTime.format(context)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                if (matchedRoute != null)
                  _InfoBadge(
                    icon: Icons.route_outlined,
                    label: matchedRoute.title,
                  ),
              ],
            ),
            if (matchedRoute == null) ...[
              const SizedBox(height: 8),
              Text(summary.routeId, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _InfoBadge(
                  icon: Icons.schedule_outlined,
                  label: 'Duration • $durationLabel',
                ),
                if (targetLabel != null)
                  _InfoBadge(
                    icon: Icons.flag_outlined,
                    label: 'Target • $targetLabel',
                  ),
                _InfoBadge(
                  icon: Icons.record_voice_over_outlined,
                  label: 'Voice guidance • $voiceLabel',
                ),
                _InfoBadge(
                  icon: Icons.checklist_rtl_outlined,
                  label: 'Checklist • $checklistLabel',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration value) {
    if (value.inHours > 0) {
      final hours = value.inHours;
      final minutes = value.inMinutes.remainder(60);
      if (minutes == 0) return '${hours}h';
      return '${hours}h ${minutes}m';
    }
    if (value.inMinutes > 0) {
      final minutes = value.inMinutes;
      final seconds = value.inSeconds.remainder(60);
      if (seconds == 0) return '${minutes}m';
      return '${minutes}m ${seconds}s';
    }
    return '${value.inSeconds}s';
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = scheme.surfaceContainerHighest.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.25 : 0.4,
    );
    final textStyle = theme.textTheme.labelLarge?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: scheme.primary.withValues(alpha: 0.9)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: textStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
              separatorBuilder: (_, index) => const SizedBox(height: 8),
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
  const SleepPresetSummary({super.key, required this.settings, this.catalog});

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
                      if (!context.mounted) return;
                      final updated = await _showEditor(
                        context,
                        ref,
                        settings,
                        reducedMotion,
                        catalog,
                      );
                      if (!context.mounted) return;
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
      data: (s) {
        Widget buildSection({
          required String title,
          required List<Widget> chips,
        }) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: chips),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSection(
              title: l10n.tr('timer_preset_section_focus'),
              chips: [
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
                  label: l10n.tr('timer_preset_break_label', {
                    'minutes': '${s.restMinutes}',
                  }),
                  onTap: () async {
                    final n = await _askMinutes(
                      context,
                      l10n.tr('timer_preset_break_title'),
                      s.restMinutes,
                    );
                    if (n == null || n <= 0) return;
                    await ref.read(savePresetProvider({'rest': n}).future);
                    await controller.setPreset('rest', n);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            buildSection(
              title: l10n.tr('timer_preset_section_workout'),
              chips: [
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
              ],
            ),
            const SizedBox(height: 16),
            buildSection(
              title: l10n.tr('timer_preset_section_sleep'),
              chips: [
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
          ],
        );
      },
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

class _TimerDesktopLayout extends ConsumerStatefulWidget {
  const _TimerDesktopLayout();

  @override
  ConsumerState<_TimerDesktopLayout> createState() => _TimerDesktopLayoutState();
}

class _TimerDesktopLayoutState extends ConsumerState<_TimerDesktopLayout> {
  static const List<int> _focusOptions = [15, 25, 45, 60, 90];
  static const List<int> _sleepOptions = [45, 60, 75, 90, 120];

  int? _focusMinutes;
  int? _sleepMinutes;
  String? _workoutPresetId;
  bool? _sleepSmartWindowEnabled;
  ProviderSubscription<AsyncValue<Settings>>? _settingsSubscription;
  ProviderSubscription<TimerState>? _timerSubscription;

  @override
  void initState() {
    super.initState();
    _settingsSubscription =
        ref.listenManual<AsyncValue<Settings>>(
      settingsFutureProvider,
      (previous, next) {
        next.whenData((settings) {
          if (!mounted) return;
          setState(() {
            _focusMinutes ??= settings.focusMinutes;
            _sleepMinutes ??= settings.sleepMinutes;
            _sleepSmartWindowEnabled ??=
                settings.sleepSmartAlarmWindowMinutes > 0;
          });
        });
      },
      fireImmediately: true,
    );

    _timerSubscription = ref.listenManual<TimerState>(
      timerControllerProvider,
      (previous, next) {
        if (!mounted) return;
        if (_workoutPresetId == null && next.workoutPresetId != null) {
          setState(() {
            _workoutPresetId = next.workoutPresetId;
          });
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _settingsSubscription?.close();
    _timerSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = ref.watch(timerControllerProvider);
    final controller = ref.read(timerControllerProvider.notifier);
    final settingsAsync = ref.watch(settingsFutureProvider);
    final settings = settingsAsync.asData?.value;

    final focusMinutes = _focusMinutes ?? settings?.focusMinutes ?? 25;
    final sleepMinutes = _sleepMinutes ?? settings?.sleepMinutes ?? 60;
    final defaultPresetId = _workoutPresetId ??
        state.workoutPresetId ??
        (workoutLightPresets.isNotEmpty ? workoutLightPresets.first.id : null);
    final sleepSmartEnabled =
        _sleepSmartWindowEnabled ?? (settings?.sleepSmartAlarmWindowMinutes ?? 0) > 0;

    final totalProgress = state.totalSeconds == 0
        ? 0.0
        : 1 - (state.remainingSeconds / state.totalSeconds);
    final segmentProgress = state.currentSegment.duration.inSeconds == 0
        ? 0.0
        : 1 -
            (state.segmentRemainingSeconds /
                state.currentSegment.duration.inSeconds);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('timer_title')),
        actions: [
          IconButton(
            tooltip: l10n.tr('timer_workout_navigator_button'),
            icon: const Icon(Icons.route_outlined),
            onPressed: () async {
              AnalyticsService.logEvent('workout_navigator_open', {
                'source': 'desktop_app_bar',
              });
              if (!context.mounted) return;
              await Navigator.push<void>(context, WorkoutNavigatorPage.route());
            },
          ),
          IconButton(
            tooltip: l10n.tr('timer_button_start'),
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () async {
              if (!context.mounted) return;
              await Navigator.push<void>(
                context,
                MaterialPageRoute<void>(builder: (_) => const StatsPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DesktopStatusCard(
                state: state,
                totalProgress: totalProgress,
                segmentProgress: segmentProgress,
                onToggle: () => _handleToggle(context, controller),
                onReset: controller.reset,
                onNext: controller.skipSegment,
                onPrevious: controller.previousSegment,
                onSoundToggle: controller.toggleSound,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 960;
                    final cards = <Widget>[
                      _ModeCard(
                        icon: Icons.timer_outlined,
                        title: l10n.tr('timer_mode_focus'),
                        description: l10n.tr('timer_desktop_focus_hint'),
                        child: _buildFocusControls(
                          context,
                          theme,
                          focusMinutes,
                          onMinutesChanged: (value) {
                            setState(() => _focusMinutes = value);
                            unawaited(
                              ref
                                  .read(savePresetProvider({'focus': value}).future),
                            );
                          },
                          onStart: () => _startFocus(context, focusMinutes),
                        ),
                      ),
                      _ModeCard(
                        icon: Icons.directions_run,
                        title: l10n.tr('timer_mode_workout'),
                        description: l10n.tr('timer_desktop_workout_hint'),
                        child: _buildWorkoutControls(
                          context,
                          theme,
                          defaultPresetId,
                          onPresetChanged: (id) {
                            setState(() => _workoutPresetId = id);
                          },
                          onStart: () =>
                              _startWorkout(context, controller, defaultPresetId),
                        ),
                      ),
                      _ModeCard(
                        icon: Icons.bedtime_outlined,
                        title: l10n.tr('timer_mode_sleep'),
                        description: l10n.tr('timer_desktop_sleep_hint'),
                        child: _buildSleepControls(
                          context,
                          theme,
                          sleepMinutes,
                          smartWindowEnabled: sleepSmartEnabled,
                          onMinutesChanged: (value) {
                            setState(() => _sleepMinutes = value);
                            unawaited(
                              ref
                                  .read(savePresetProvider({'sleep': value}).future),
                            );
                          },
                          onSmartWindowChanged: (value) async {
                            await _toggleSmartWindow(value, settings);
                          },
                          onStart: () => _startSleep(context, sleepMinutes),
                        ),
                      ),
                    ];

                    if (isNarrow) {
                      return Column(
                        children: [
                          ...cards.map(
                            (card) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: SizedBox(width: double.infinity, child: card),
                            ),
                          ),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: cards
                          .map(
                            (card) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: card,
                              ),
                            ),
                          )
                          .toList()
                        ..last = Expanded(child: cards.last),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleSmartWindow(bool enabled, Settings? settings) async {
    final current = settings;
    if (current == null) {
      setState(() => _sleepSmartWindowEnabled = enabled);
      return;
    }
    setState(() => _sleepSmartWindowEnabled = enabled);
    final windowMinutes = enabled ? current.sleepSmartAlarmWindowMinutes.clamp(15, 120) : 0;
    await ref
        .read(
          updateSleepSmartAlarmProvider(
            SleepSmartAlarmInput(
              windowMinutes: windowMinutes,
              intervalMinutes: current.sleepSmartAlarmIntervalMinutes,
              fallbackExact: current.sleepSmartAlarmExactFallback,
              whiteLevel: current.sleepMixerWhiteLevel,
              pinkLevel: current.sleepMixerPinkLevel,
              brownLevel: current.sleepMixerBrownLevel,
              presetId: current.sleepMixerPresetId.isEmpty
                  ? SleepSoundCatalog.defaultPresetId
                  : current.sleepMixerPresetId,
            ),
          ).future,
        );
  }

  Widget _buildFocusControls(
    BuildContext context,
    ThemeData theme,
    int focusMinutes, {
    required ValueChanged<int> onMinutesChanged,
    required VoidCallback onStart,
  }) {
    final l10n = context.l10n;
    final options = {..._focusOptions, focusMinutes}..removeWhere((value) => value <= 0);
    final sortedOptions = options.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.tr('timer_desktop_focus_duration', {
            'minutes': '$focusMinutes',
          }),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        DropdownButton<int>(
          value: focusMinutes,
          onChanged: (value) {
            if (value == null) return;
            onMinutesChanged(value);
          },
          items: sortedOptions
              .map(
                (minutes) => DropdownMenuItem<int>(
                  value: minutes,
                  child: Text(l10n.tr('timer_desktop_minutes_label', {
                    'minutes': '$minutes',
                  })),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(l10n.tr('timer_button_start')),
          onPressed: onStart,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.tr('timer_desktop_focus_tip'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutControls(
    BuildContext context,
    ThemeData theme,
    String? selectedId, {
    required ValueChanged<String> onPresetChanged,
    required VoidCallback onStart,
  }) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<String>(
          value: selectedId,
          isExpanded: true,
          onChanged: (value) {
            if (value == null) return;
            onPresetChanged(value);
          },
          items: workoutLightPresets
              .map(
                (preset) => DropdownMenuItem<String>(
                  value: preset.id,
                  child: Text(l10n.tr(preset.labelKey)),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(l10n.tr('timer_button_start')),
          onPressed: selectedId == null ? null : onStart,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () async {
            AnalyticsService.logEvent('workout_navigator_open', {
              'source': 'desktop_card',
            });
            if (!context.mounted) return;
            await Navigator.push<void>(context, WorkoutNavigatorPage.route());
          },
          child: Text(l10n.tr('timer_desktop_open_navigator')),
        ),
      ],
    );
  }

  Widget _buildSleepControls(
    BuildContext context,
    ThemeData theme,
    int sleepMinutes, {
    required bool smartWindowEnabled,
    required ValueChanged<int> onMinutesChanged,
    required ValueChanged<bool> onSmartWindowChanged,
    required VoidCallback onStart,
  }) {
    final l10n = context.l10n;
    final options = {..._sleepOptions, sleepMinutes}..removeWhere((value) => value <= 0);
    final sortedOptions = options.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<int>(
          value: sleepMinutes,
          onChanged: (value) {
            if (value == null) return;
            onMinutesChanged(value);
          },
          items: sortedOptions
              .map(
                (minutes) => DropdownMenuItem<int>(
                  value: minutes,
                  child: Text(l10n.tr('timer_desktop_minutes_label', {
                    'minutes': '$minutes',
                  })),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: smartWindowEnabled,
          onChanged: (value) => onSmartWindowChanged(value),
          title: Text(l10n.tr('timer_sleep_smart_alarm_title')), // reuse existing key or create new? ensure exists.
          subtitle: Text(
            smartWindowEnabled
                ? l10n.tr('timer_sleep_smart_alarm_on')
                : l10n.tr('timer_sleep_smart_alarm_off'),
            style: theme.textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(l10n.tr('timer_button_start')),
          onPressed: onStart,
        ),
      ],
    );
  }

  Future<void> _startFocus(BuildContext context, int minutes) async {
    final granted = await _ensurePermissions(context);
    if (!granted) return;
    await ref.read(savePresetProvider({'focus': minutes}).future);
    await ref.read(timerControllerProvider.notifier).selectMode('focus');
    final current = ref.read(timerControllerProvider);
    if (!current.isRunning) {
      await ref.read(timerControllerProvider.notifier).toggleStartStop();
    }
  }

  Future<void> _startWorkout(
    BuildContext context,
    TimerController controller,
    String? presetId,
  ) async {
    if (presetId == null) return;
    final granted = await _ensurePermissions(context);
    if (!granted) return;
    await controller.startWorkoutLightPreset(presetId);
    final current = ref.read(timerControllerProvider);
    if (!current.isRunning) {
      await controller.toggleStartStop();
    }
  }

  Future<void> _startSleep(BuildContext context, int minutes) async {
    final granted = await _ensurePermissions(context);
    if (!granted) return;
    await ref.read(savePresetProvider({'sleep': minutes}).future);
    await ref.read(timerControllerProvider.notifier).selectMode('sleep');
    final current = ref.read(timerControllerProvider);
    if (!current.isRunning) {
      await ref.read(timerControllerProvider.notifier).toggleStartStop();
    }
  }

  Future<bool> _ensurePermissions(BuildContext context) async {
    final granted = await TimerPermissionService.ensureTimerPermissions(context);
    ref.invalidate(timerPermissionStatusProvider);
    return granted;
  }

  Future<void> _handleToggle(
    BuildContext context,
    TimerController controller,
  ) async {
    final granted = await _ensurePermissions(context);
    if (!granted) return;
    await controller.toggleStartStop();
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _DesktopStatusCard extends StatelessWidget {
  const _DesktopStatusCard({
    required this.state,
    required this.totalProgress,
    required this.segmentProgress,
    required this.onToggle,
    required this.onReset,
    required this.onNext,
    required this.onPrevious,
    required this.onSoundToggle,
  });

  final TimerState state;
  final double totalProgress;
  final double segmentProgress;
  final Future<void> Function() onToggle;
  final Future<void> Function() onReset;
  final Future<void> Function() onNext;
  final Future<void> Function() onPrevious;
  final Future<void> Function()? onSoundToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final modeLabel = _modeLabel(l10n, state.mode);
    final segmentLabel = state.currentSegment.labelFor(l10n);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              modeLabel,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              segmentLabel,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: totalProgress.clamp(0, 1)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: segmentProgress.clamp(0, 1),
              color: theme.colorScheme.secondary,
              backgroundColor:
                  theme.colorScheme.secondary.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  icon: Icon(
                    state.isRunning ? Icons.pause_rounded : Icons.play_arrow,
                  ),
                  label: Text(
                    state.isRunning
                        ? l10n.tr('timer_button_pause')
                        : l10n.tr('timer_button_start'),
                  ),
                  onPressed: onToggle,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.skip_previous_rounded),
                  label: Text(l10n.tr('timer_button_previous')),
                  onPressed: onPrevious,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.skip_next_rounded),
                  label: Text(l10n.tr('timer_button_next')),
                  onPressed: onNext,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.tr('timer_button_reset')),
                  onPressed: onReset,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: state.isSoundEnabled,
              onChanged: (_) => onSoundToggle?.call(),
              title: Text(l10n.tr('timer_sound_switch_title')),
              subtitle: Text(
                state.isSoundEnabled
                    ? l10n.tr('timer_sound_switch_enabled', {
                        'profile': state.currentSegment.playSoundProfile ??
                            l10n.tr('timer_sound_profile_default'),
                      })
                    : l10n.tr('timer_sound_switch_disabled'),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _modeLabel(AppLocalizations l10n, String mode) {
    switch (mode) {
      case 'focus':
        return l10n.tr('timer_mode_focus');
      case 'workout':
        return l10n.tr('timer_mode_workout');
      case 'sleep':
        return l10n.tr('timer_mode_sleep');
      case 'rest':
        return l10n.tr('timer_mode_rest');
      default:
        return l10n.tr('timer_title');
    }
  }
}
