import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/design/app_theme.dart';
import 'package:life_app/features/stats/stats_page.dart';
import 'package:life_app/features/timer/timer_controller.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/services/analytics/analytics_service.dart';
import 'package:life_app/widgets/circular_progress_ring.dart';
import 'package:life_app/widgets/glass_card.dart';

/// Timer preset configuration matching Figma design
class TimerPreset {
  const TimerPreset({
    required this.id,
    required this.nameKey,
    required this.duration,
    required this.emoji,
  });

  final String id;
  final String nameKey;
  final int duration; // in minutes
  final String emoji;

  String label(AppLocalizations l10n) => l10n.tr(nameKey);
}

/// Figma-styled timer tab with glassmorphism and beautiful animations
class FigmaTimerTab extends ConsumerStatefulWidget {
  const FigmaTimerTab({
    super.key,
    this.initialMode = 'focus',
    this.autoStart = false,
  });

  final String initialMode;
  final bool autoStart;

  @override
  ConsumerState<FigmaTimerTab> createState() => _FigmaTimerTabState();
}

class _FigmaTimerTabState extends ConsumerState<FigmaTimerTab>
    with SingleTickerProviderStateMixin {
  static const focusPresets = [
    TimerPreset(
      id: '1',
      nameKey: 'figma_timer_preset_focus_boost',
      duration: 25,
      emoji: '⚡',
    ),
    TimerPreset(
      id: '2',
      nameKey: 'figma_timer_preset_quick_reset',
      duration: 5,
      emoji: '🌊',
    ),
    TimerPreset(
      id: '3',
      nameKey: 'figma_timer_preset_deep_dive',
      duration: 52,
      emoji: '🧠',
    ),
    TimerPreset(
      id: '4',
      nameKey: 'figma_timer_preset_power_hour_focus',
      duration: 60,
      emoji: '🚀',
    ),
  ];

  static const workoutPresets = [
    TimerPreset(
      id: '1',
      nameKey: 'figma_timer_preset_quick_workout',
      duration: 15,
      emoji: '💪',
    ),
    TimerPreset(
      id: '2',
      nameKey: 'figma_timer_preset_full_session',
      duration: 30,
      emoji: '🔥',
    ),
    TimerPreset(
      id: '3',
      nameKey: 'figma_timer_preset_power_hour_workout',
      duration: 60,
      emoji: '⚡',
    ),
    TimerPreset(
      id: '4',
      nameKey: 'figma_timer_preset_endurance',
      duration: 90,
      emoji: '🏃',
    ),
  ];

  static const sleepPresets = [
    TimerPreset(
      id: '1',
      nameKey: 'figma_timer_preset_power_nap',
      duration: 20,
      emoji: '😴',
    ),
    TimerPreset(
      id: '2',
      nameKey: 'figma_timer_preset_short_rest',
      duration: 30,
      emoji: '🌙',
    ),
    TimerPreset(
      id: '3',
      nameKey: 'figma_timer_preset_deep_sleep',
      duration: 60,
      emoji: '💤',
    ),
    TimerPreset(
      id: '4',
      nameKey: 'figma_timer_preset_full_night',
      duration: 480,
      emoji: '🛌',
    ),
  ];

  late List<TimerPreset> _currentPresets;
  late TimerPreset _selectedPreset;
  late AnimationController _glowController;

  // Custom time selection
  int _customHours = 0;
  int _customMinutes = 25;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();

    // Select presets based on mode
    _currentPresets = switch (widget.initialMode) {
      'workout' => workoutPresets,
      'sleep' => sleepPresets,
      _ => focusPresets,
    };
    _selectedPreset = _currentPresets[0];

    // Initialize time picker controllers
    _hourController = FixedExtentScrollController(initialItem: _customHours);
    _minuteController = FixedExtentScrollController(initialItem: _customMinutes ~/ 5);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Initialize timer with initial mode and preset
    Future.microtask(() async {
      final controller = ref.read(timerControllerProvider.notifier);
      await controller.selectMode(widget.initialMode);
      await controller.setPreset(widget.initialMode, _selectedPreset.duration);

      // Auto start if requested
      if (widget.autoStart) {
        await controller.toggleStartStop();
      }
    });
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _handlePresetSelect(TimerPreset preset) async {
    final timerState = ref.read(timerControllerProvider);
    if (timerState.isRunning) return;

    setState(() {
      _selectedPreset = preset;
    });

    final controller = ref.read(timerControllerProvider.notifier);
    await controller.setPreset(widget.initialMode, preset.duration);

    AnalyticsService.logEvent('figma_timer_preset_select', {
      'mode': widget.initialMode,
      'preset_key': preset.nameKey,
      'duration': preset.duration,
    });
  }

  Future<void> _handleCustomTimeSet() async {
    final timerState = ref.read(timerControllerProvider);
    if (timerState.isRunning) return;

    final totalMinutes = (_customHours * 60) + _customMinutes;
    if (totalMinutes == 0) return;

    final controller = ref.read(timerControllerProvider.notifier);
    await controller.setPreset(widget.initialMode, totalMinutes);

    AnalyticsService.logEvent('figma_timer_custom_time_set', {
      'mode': widget.initialMode,
      'hours': _customHours,
      'minutes': _customMinutes,
      'total_minutes': totalMinutes,
    });
  }

  Future<void> _showDirectInputDialog({
    required BuildContext context,
    required String title,
    required String hintText,
    required int maxValue,
    required int currentValue,
    required ValueChanged<int> onSubmit,
  }) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: currentValue.toString());
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) {
            final num = int.tryParse(value);
            if (num != null && num >= 0 && num <= maxValue) {
              onSubmit(num);
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.tr('common_cancel')),
          ),
          FilledButton(
            onPressed: () {
              final num = int.tryParse(controller.text);
              if (num != null && num >= 0 && num <= maxValue) {
                onSubmit(num);
                Navigator.pop(context);
              }
            },
            child: Text(l10n.tr('common_ok')),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePlayPause() async {
    final controller = ref.read(timerControllerProvider.notifier);
    final timerState = ref.read(timerControllerProvider);

    if (!timerState.isRunning) {
      AnalyticsService.logEvent('figma_timer_start', {
        'preset_key': _selectedPreset.nameKey,
        'duration': _selectedPreset.duration,
      });
    }

    await controller.toggleStartStop();
  }

  Future<void> _handleReset() async {
    final controller = ref.read(timerControllerProvider.notifier);
    await controller.reset();

    AnalyticsService.logEvent('figma_timer_reset', {
      'preset_key': _selectedPreset.nameKey,
    });
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  String _modeLabel(AppLocalizations l10n) {
    switch (widget.initialMode) {
      case 'workout':
        return l10n.tr('timer_mode_workout');
      case 'sleep':
        return l10n.tr('timer_mode_sleep');
      default:
        return l10n.tr('timer_mode_focus');
    }
  }

  String _badgeLabel(AppLocalizations l10n) {
    switch (widget.initialMode) {
      case 'workout':
        return l10n.tr('figma_timer_badge_workout');
      case 'sleep':
        return l10n.tr('figma_timer_badge_sleep');
      default:
        return l10n.tr('figma_timer_badge_focus');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final backgroundColors = [
      theme.colorScheme.surface,
      theme.colorScheme.surfaceContainerLowest,
    ];
    final customTimeLabel = _customHours > 0
        ? l10n.tr('figma_timer_time_label_hours_minutes', {
            'hours': '$_customHours',
            'minutes': '$_customMinutes',
          })
        : l10n.tr('figma_timer_time_label_minutes', {
            'minutes': '$_customMinutes',
          });

    // Watch timer state from TimerController
    final timerState = ref.watch(timerControllerProvider);
    final timeRemaining = timerState.segmentRemainingSeconds;
    final isRunning = timerState.isRunning;
    final totalSeconds = timerState.segmentTotalSeconds;
    final progress = totalSeconds > 0
        ? ((totalSeconds - timeRemaining) / totalSeconds) * 100
        : 0.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: backgroundColors,
          ),
        ),
        child: Stack(
          children: [
            // Animated background blobs
            Positioned(
              top: 100,
              left: MediaQuery.of(context).size.width * 0.25,
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFF9A56).withValues(
                            alpha: 0.12 + _glowController.value * 0.12,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: 200,
              right: MediaQuery.of(context).size.width * 0.25,
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFFD93D).withValues(
                            alpha: 0.12 + (1 - _glowController.value) * 0.12,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Content
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Back button
                    Row(
                      children: [
                        GlassCard(
                          onTap: () => Navigator.of(context).pop(),
                          padding: const EdgeInsets.all(12),
                          borderRadius: 12,
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: 20,
                            color: isDark ? Colors.white : const Color(0xFFFF9A56),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Header badge
                    GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 16),
                      borderRadius: 20,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.psychology_rounded,
                            size: 18,
                            color: Color(0xFFFF9A56),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _badgeLabel(l10n),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFFFF9A56),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 14,
                            color: AppTheme.lime,
                          ),
                        ],
                      ),
                    ),
                    // Preset name
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFFFF9A56),
                          Color(0xFFFFD93D),
                        ],
                      ).createShader(bounds),
                      child: Text(
                        _selectedPreset.label(l10n),
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.tr('figma_timer_session_duration', {
                        'minutes': '${_selectedPreset.duration}',
                      }),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isDark
                            ? const Color(0xFFFF9A56).withValues(alpha: 0.8)
                            : const Color(0xFFFF9A56),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Circular timer with glow
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow
                        AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, child) {
                            return Container(
                              width: 280,
                              height: 280,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF9A56).withValues(alpha: 
                                      0.3 + _glowController.value * 0.3,
                                    ),
                                    blurRadius: 60,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        // Circular progress ring
                        CircularProgressRing(
                          progress: progress,
                          size: 260,
                          strokeWidth: 14,
                          color: const Color(0xFFFF9A56),
                          centerText: '',
                        ),
                        // Timer content
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedPreset.emoji,
                              style: const TextStyle(fontSize: 48),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _formatTime(timeRemaining),
                              style: theme.textTheme.displayLarge?.copyWith(
                                fontSize: 56,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : theme.colorScheme.onSurface,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isRunning
                                  ? l10n.tr('figma_timer_status_active', {
                                      'mode': _modeLabel(l10n),
                                    })
                                  : l10n.tr('figma_timer_status_ready', {
                                      'mode': _modeLabel(l10n),
                                    }),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? const Color(0xFFFF9A56).withValues(alpha: 0.8)
                                    : const Color(0xFFFF9A56),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    // Primary action
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isRunning
                              ? [
                                  Colors.grey.shade600,
                                  Colors.grey.shade700,
                                ]
                              : [
                                  const Color(0xFFFF9A56),
                                  const Color(0xFFFFD93D),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (isRunning
                                    ? Colors.grey
                                    : const Color(0xFFFF9A56))
                                .withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _handlePlayPause,
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isRunning
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isRunning
                                      ? l10n.tr('figma_timer_action_pause')
                                      : l10n.tr('figma_timer_action_start'),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GlassCard(
                          onTap: _handleReset,
                          padding: const EdgeInsets.all(12),
                          borderRadius: 14,
                          child: Icon(
                            Icons.refresh_rounded,
                            size: 22,
                            color: isDark ? Colors.white : const Color(0xFFFF9A56),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GlassCard(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const StatsPage(),
                              ),
                            );
                          },
                          padding: const EdgeInsets.all(12),
                          borderRadius: 14,
                          child: Icon(
                            Icons.bolt,
                            size: 22,
                            color: isDark ? Colors.white : const Color(0xFFFF9A56),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Custom time picker
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      borderRadius: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 18,
                                color: isDark ? Colors.white : const Color(0xFFFF9A56),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.tr('figma_timer_custom_title'),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // iOS-style time picker
                          Container(
                            height: 180,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Hour picker
                                Expanded(
                                  child: Column(
                                    children: [
                                      GestureDetector(
                                        onTap: () => _showDirectInputDialog(
                                          context: context,
                                          title: l10n.tr(
                                            'figma_timer_input_hours_title',
                                          ),
                                          hintText: l10n.tr(
                                            'figma_timer_input_hours_hint',
                                          ),
                                          maxValue: 24,
                                          currentValue: _customHours,
                                          onSubmit: (value) {
                                            setState(() {
                                              _customHours = value;
                                              _hourController.jumpToItem(value);
                                            });
                                          },
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              l10n.tr(
                                                'figma_timer_picker_hours',
                                              ),
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: isDark
                                                    ? Colors.white.withValues(alpha: 0.5)
                                                    : const Color(0xFFFF9A56).withValues(alpha: 0.5),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.edit_rounded,
                                              size: 12,
                                              color: isDark
                                                  ? Colors.white.withValues(alpha: 0.3)
                                                  : const Color(0xFFFF9A56).withValues(alpha: 0.3),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Expanded(
                                        child: CupertinoPicker(
                                          scrollController: _hourController,
                                          itemExtent: 50,
                                          onSelectedItemChanged: (index) {
                                            setState(() {
                                              _customHours = index;
                                            });
                                          },
                                          selectionOverlay: Container(
                                            decoration: BoxDecoration(
                                              border: Border.symmetric(
                                                horizontal: BorderSide(
                                                  color: const Color(0xFFFF9A56).withValues(alpha: 0.3),
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                          children: List.generate(25, (index) {
                                            return Center(
                                              child: Text(
                                                '$index',
                                                style: theme.textTheme.headlineSmall?.copyWith(
                                                  color: isDark ? Colors.white : const Color(0xFFFF9A56),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                // Minute picker
                                Expanded(
                                  child: Column(
                                    children: [
                                      GestureDetector(
                                        onTap: () => _showDirectInputDialog(
                                          context: context,
                                          title: l10n.tr(
                                            'figma_timer_input_minutes_title',
                                          ),
                                          hintText: l10n.tr(
                                            'figma_timer_input_minutes_hint',
                                          ),
                                          maxValue: 55,
                                          currentValue: _customMinutes,
                                          onSubmit: (value) {
                                            // Round to nearest 5
                                            final roundedValue = (value / 5).round() * 5;
                                            setState(() {
                                              _customMinutes = roundedValue;
                                              _minuteController.jumpToItem(roundedValue ~/ 5);
                                            });
                                          },
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              l10n.tr(
                                                'figma_timer_picker_minutes',
                                              ),
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: isDark
                                                    ? Colors.white.withValues(alpha: 0.5)
                                                    : const Color(0xFFFF9A56).withValues(alpha: 0.5),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.edit_rounded,
                                              size: 12,
                                              color: isDark
                                                  ? Colors.white.withValues(alpha: 0.3)
                                                  : const Color(0xFFFF9A56).withValues(alpha: 0.3),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Expanded(
                                        child: CupertinoPicker(
                                          scrollController: _minuteController,
                                          itemExtent: 50,
                                          onSelectedItemChanged: (index) {
                                            setState(() {
                                              _customMinutes = index * 5;
                                            });
                                          },
                                          selectionOverlay: Container(
                                            decoration: BoxDecoration(
                                              border: Border.symmetric(
                                                horizontal: BorderSide(
                                                  color: const Color(0xFFFF9A56).withValues(alpha: 0.3),
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                          children: List.generate(12, (index) {
                                            final minute = index * 5;
                                            return Center(
                                              child: Text(
                                                '$minute',
                                                style: theme.textTheme.headlineSmall?.copyWith(
                                                  color: isDark ? Colors.white : const Color(0xFFFF9A56),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Set button
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: isRunning ? null : _handleCustomTimeSet,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFFF9A56),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                l10n.tr('figma_timer_set_button', {
                                  'label': customTimeLabel,
                                }),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Preset grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.4,
                      ),
                      itemCount: _currentPresets.length,
                      itemBuilder: (context, index) {
                        final preset = _currentPresets[index];
                        final isSelected = preset.id == _selectedPreset.id;
                        return GlassCard(
                          onTap: isRunning ? null : () => _handlePresetSelect(preset),
                          padding: const EdgeInsets.all(16),
                          borderRadius: 20,
                          gradient: isSelected
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isDark
                                      ? [
                                          const Color(0xFFFF9A56).withValues(alpha: 0.3),
                                          const Color(0xFFFFD93D).withValues(alpha: 0.2),
                                        ]
                                      : [
                                          const Color(0xFFFF9A56).withValues(alpha: 0.15),
                                          const Color(0xFFFFD93D).withValues(alpha: 0.1),
                                        ],
                                )
                              : null,
                          shadowColor: isSelected ? const Color(0xFFFF9A56) : null,
                          shadowOpacity: isSelected ? 0.3 : 0.2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                preset.emoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                preset.label(l10n),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.tr('figma_timer_preset_duration', {
                                  'minutes': '${preset.duration}',
                                }),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? const Color(0xFFFF9A56).withValues(alpha: 0.8)
                                      : const Color(0xFFFF9A56),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Focus tips
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      borderRadius: 20,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🧠',
                            style: TextStyle(fontSize: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.tr('figma_timer_focus_tip_title'),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.tr('figma_timer_focus_tip_body'),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.7)
                                        : theme.colorScheme.onSurfaceVariant,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
