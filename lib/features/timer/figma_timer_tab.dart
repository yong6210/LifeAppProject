import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/design/app_theme.dart';
import 'package:life_app/features/stats/stats_page.dart';
import 'package:life_app/features/timer/timer_controller.dart';
import 'package:life_app/services/analytics/analytics_service.dart';
import 'package:life_app/widgets/circular_progress_ring.dart';
import 'package:life_app/widgets/glass_card.dart';

/// Timer preset configuration matching Figma design
class TimerPreset {
  const TimerPreset({
    required this.id,
    required this.name,
    required this.duration,
    required this.emoji,
  });

  final String id;
  final String name;
  final int duration; // in minutes
  final String emoji;
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
    TimerPreset(id: '1', name: 'Focus Boost', duration: 25, emoji: '⚡'),
    TimerPreset(id: '2', name: 'Quick Reset', duration: 5, emoji: '🌊'),
    TimerPreset(id: '3', name: 'Deep Dive', duration: 52, emoji: '🧠'),
    TimerPreset(id: '4', name: 'Power Hour', duration: 60, emoji: '🚀'),
  ];

  static const workoutPresets = [
    TimerPreset(id: '1', name: 'Quick Workout', duration: 15, emoji: '💪'),
    TimerPreset(id: '2', name: 'Full Session', duration: 30, emoji: '🔥'),
    TimerPreset(id: '3', name: 'Power Hour', duration: 60, emoji: '⚡'),
    TimerPreset(id: '4', name: 'Endurance', duration: 90, emoji: '🏃'),
  ];

  static const sleepPresets = [
    TimerPreset(id: '1', name: 'Power Nap', duration: 20, emoji: '😴'),
    TimerPreset(id: '2', name: 'Short Rest', duration: 30, emoji: '🌙'),
    TimerPreset(id: '3', name: 'Deep Sleep', duration: 60, emoji: '💤'),
    TimerPreset(id: '4', name: 'Full Night', duration: 480, emoji: '🛌'),
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
      'preset': preset.name,
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
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final num = int.tryParse(controller.text);
              if (num != null && num >= 0 && num <= maxValue) {
                onSubmit(num);
                Navigator.pop(context);
              }
            },
            child: const Text('OK'),
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
        'preset': _selectedPreset.name,
        'duration': _selectedPreset.duration,
      });
    }

    await controller.toggleStartStop();
  }

  Future<void> _handleReset() async {
    final controller = ref.read(timerControllerProvider.notifier);
    await controller.reset();

    AnalyticsService.logEvent('figma_timer_reset', {
      'preset': _selectedPreset.name,
    });
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            colors: isDark
                ? [
                    const Color(0xFF2a1f1a),
                    const Color(0xFF1a1214),
                    const Color(0xFF140a0e),
                  ]
                : [
                    const Color(0xFFFFF4E8),
                    const Color(0xFFFFEED9),
                    const Color(0xFFFFFBF5),
                  ],
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
                          const Color(0xFFFF9A56).withValues(alpha: 0.3 + _glowController.value * 0.2),
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
                          const Color(0xFFFFD93D).withValues(alpha: 0.3 + (1 - _glowController.value) * 0.2),
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
                          Icon(
                            Icons.psychology,
                            size: 18,
                            color: const Color(0xFFFF9A56),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Neural Focus',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFFFF9A56),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: AppTheme.lime,
                          ),
                        ],
                      ),
                    ),
                    // Preset name
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          const Color(0xFFFF9A56),
                          const Color(0xFFFFD93D),
                        ],
                      ).createShader(bounds),
                      child: Text(
                        _selectedPreset.name,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_selectedPreset.duration} min session',
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
                              isRunning ? '⚡ Focus Mode Active' : 'Ready to focus',
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
                    // Control buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Reset button
                        GlassCard(
                          onTap: _handleReset,
                          padding: const EdgeInsets.all(14),
                          borderRadius: 16,
                          child: Icon(
                            Icons.refresh,
                            size: 24,
                            color: isDark ? Colors.white : const Color(0xFFFF9A56),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Play/Pause button
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFFFF9A56),
                                const Color(0xFFFFD93D),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF9A56).withValues(alpha: 0.5),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _handlePlayPause,
                              borderRadius: BorderRadius.circular(24),
                              child: Center(
                                child: Icon(
                                  isRunning ? Icons.pause : Icons.play_arrow,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Stats button
                        GlassCard(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const StatsPage(),
                              ),
                            );
                          },
                          padding: const EdgeInsets.all(14),
                          borderRadius: 16,
                          child: Icon(
                            Icons.bolt,
                            size: 24,
                            color: isDark ? Colors.white : const Color(0xFFFF9A56),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
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
                                Icons.schedule,
                                size: 18,
                                color: isDark ? Colors.white : const Color(0xFFFF9A56),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Custom Timer',
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
                                          title: 'Enter Hours',
                                          hintText: '0-24',
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
                                              '시간',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: isDark
                                                    ? Colors.white.withValues(alpha: 0.5)
                                                    : const Color(0xFFFF9A56).withValues(alpha: 0.5),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.edit,
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
                                          title: 'Enter Minutes',
                                          hintText: '0-55 (5 min intervals)',
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
                                              '분',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: isDark
                                                    ? Colors.white.withValues(alpha: 0.5)
                                                    : const Color(0xFFFF9A56).withValues(alpha: 0.5),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.edit,
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
                                'Set ${_customHours > 0 ? "${_customHours}h " : ""}${_customMinutes}min',
                                style: const TextStyle(
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
                                preset.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${preset.duration} minutes',
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
                                  'Neural Boost Active',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Your brain works best in focused bursts. Eliminate distractions and let your mind enter the flow state. Deep work creates neural pathways that make you smarter!',
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
