import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/design/app_theme.dart';
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
  const FigmaTimerTab({super.key});

  @override
  ConsumerState<FigmaTimerTab> createState() => _FigmaTimerTabState();
}

class _FigmaTimerTabState extends ConsumerState<FigmaTimerTab>
    with SingleTickerProviderStateMixin {
  static const presets = [
    TimerPreset(id: '1', name: 'Focus Boost', duration: 25, emoji: '⚡'),
    TimerPreset(id: '2', name: 'Quick Reset', duration: 5, emoji: '🌊'),
    TimerPreset(id: '3', name: 'Deep Dive', duration: 52, emoji: '🧠'),
    TimerPreset(id: '4', name: 'Power Hour', duration: 60, emoji: '🚀'),
  ];

  TimerPreset _selectedPreset = presets[0];
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Initialize timer with first preset
    Future.microtask(() async {
      final controller = ref.read(timerControllerProvider.notifier);
      await controller.selectMode('focus');
      await controller.setPreset('focus', _selectedPreset.duration);
    });
  }

  @override
  void dispose() {
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
    await controller.setPreset('focus', preset.duration);

    AnalyticsService.logEvent('figma_timer_preset_select', {
      'preset': preset.name,
      'duration': preset.duration,
    });
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
                    const Color(0xFF1a1f3a),
                    const Color(0xFF0f1419),
                    const Color(0xFF0a0e14),
                  ]
                : [
                    const Color(0xFFF0F4FF),
                    const Color(0xFFE8EEFF),
                    const Color(0xFFFFFFFF),
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
                          AppTheme.electricViolet.withOpacity(0.3 + _glowController.value * 0.2),
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
                          AppTheme.teal.withOpacity(0.3 + (1 - _glowController.value) * 0.2),
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
                            color: isDark ? Colors.white : AppTheme.electricViolet,
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
                            color: AppTheme.electricViolet,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Neural Focus',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppTheme.electricViolet,
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
                          AppTheme.electricViolet,
                          AppTheme.teal,
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
                            ? AppTheme.electricViolet.withOpacity(0.8)
                            : AppTheme.electricViolet,
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
                                    color: AppTheme.electricViolet.withOpacity(
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
                          color: AppTheme.electricViolet,
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
                                    ? AppTheme.electricViolet.withOpacity(0.8)
                                    : AppTheme.electricViolet,
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
                            color: isDark ? Colors.white : AppTheme.electricViolet,
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
                                AppTheme.electricViolet,
                                AppTheme.teal,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.electricViolet.withOpacity(0.5),
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
                            // Open stats or insights
                          },
                          padding: const EdgeInsets.all(14),
                          borderRadius: 16,
                          child: Icon(
                            Icons.bolt,
                            size: 24,
                            color: isDark ? Colors.white : AppTheme.electricViolet,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
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
                      itemCount: presets.length,
                      itemBuilder: (context, index) {
                        final preset = presets[index];
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
                                          AppTheme.electricViolet.withOpacity(0.3),
                                          AppTheme.teal.withOpacity(0.2),
                                        ]
                                      : [
                                          AppTheme.electricViolet.withOpacity(0.15),
                                          AppTheme.teal.withOpacity(0.1),
                                        ],
                                )
                              : null,
                          shadowColor: isSelected ? AppTheme.electricViolet : null,
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
                                      ? AppTheme.electricViolet.withOpacity(0.8)
                                      : AppTheme.electricViolet,
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
                                        ? Colors.white.withOpacity(0.7)
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
