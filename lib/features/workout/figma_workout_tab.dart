import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/design/app_theme.dart';
import 'package:life_app/features/timer/timer_controller.dart';
import 'package:life_app/features/workout/workout_light_presets.dart';
import 'package:life_app/features/workout/models/workout_navigator_models.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/providers/session_providers.dart';
import 'package:life_app/services/analytics/analytics_service.dart';
import 'package:life_app/widgets/glass_card.dart';

/// Helper to get emoji and estimated calories for workout presets
class WorkoutPresetUI {
  static String getEmoji(WorkoutLightPreset preset) {
    switch (preset.discipline) {
      case WorkoutDiscipline.running:
        switch (preset.intensity) {
          case WorkoutIntensity.light:
            return '🏃';
          case WorkoutIntensity.moderate:
            return '🏃‍♂️';
          case WorkoutIntensity.vigorous:
            return '⚡';
        }
      case WorkoutDiscipline.cycling:
        switch (preset.intensity) {
          case WorkoutIntensity.light:
            return '🚴';
          case WorkoutIntensity.moderate:
            return '🚴‍♂️';
          case WorkoutIntensity.vigorous:
            return '🔥';
        }
    }
  }

  static int getEstimatedCalories(WorkoutLightPreset preset) {
    // Rough estimates: light=5 cal/min, moderate=7 cal/min, vigorous=10 cal/min
    switch (preset.intensity) {
      case WorkoutIntensity.light:
        return preset.totalMinutes * 5;
      case WorkoutIntensity.moderate:
        return preset.totalMinutes * 7;
      case WorkoutIntensity.vigorous:
        return preset.totalMinutes * 10;
    }
  }

  static int getIntensityLevel(WorkoutIntensity intensity) {
    switch (intensity) {
      case WorkoutIntensity.light:
        return 2;
      case WorkoutIntensity.moderate:
        return 3;
      case WorkoutIntensity.vigorous:
        return 5;
    }
  }
}

/// Figma-styled workout tab with energy flow design
class FigmaWorkoutTab extends ConsumerStatefulWidget {
  const FigmaWorkoutTab({super.key});

  @override
  ConsumerState<FigmaWorkoutTab> createState() => _FigmaWorkoutTabState();
}

class _FigmaWorkoutTabState extends ConsumerState<FigmaWorkoutTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _energyController;
  WorkoutIntensity? _selectedIntensity; // null = All

  @override
  void initState() {
    super.initState();
    _energyController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _energyController.dispose();
    super.dispose();
  }

  Future<void> _handleStartWorkout(WorkoutLightPreset preset) async {
    final controller = ref.read(timerControllerProvider.notifier);
    await controller.startWorkoutLightPreset(preset.id);

    AnalyticsService.logEvent('figma_workout_start', {
      'preset_id': preset.id,
      'discipline': preset.discipline.name,
      'intensity': preset.intensity.name,
      'duration': preset.totalMinutes,
    });

    // Show confirmation
    if (!mounted) return;
    final emoji = WorkoutPresetUI.getEmoji(preset);
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.tr('figma_workout_start_toast', {'emoji': emoji}),
        ),
        backgroundColor: AppTheme.coral,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handlePlayPause() async {
    final controller = ref.read(timerControllerProvider.notifier);
    await controller.toggleStartStop();
  }

  Future<void> _handleReset() async {
    final controller = ref.read(timerControllerProvider.notifier);
    await controller.reset();
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      borderRadius: 20,
      gradient: isSelected
          ? LinearGradient(
              colors: [
                AppTheme.coral,
                const Color(0xFFFFA726),
              ],
            )
          : null,
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: isSelected
              ? Colors.white
              : (isDark ? AppTheme.coral.withValues(alpha: 0.9) : AppTheme.coral),
        ),
      ),
    );
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

    // Watch timer state for real-time workout progress
    final timerState = ref.watch(timerControllerProvider);
    final isWorkoutRunning =
        timerState.mode == 'workout' && timerState.isRunning;
    final currentSegmentLabel =
        isWorkoutRunning ? timerState.currentSegment.labelFor(l10n) : null;
    final workoutProgress =
        isWorkoutRunning && timerState.segmentTotalSeconds > 0
        ? ((timerState.segmentTotalSeconds -
                      timerState.segmentRemainingSeconds) /
                  timerState.segmentTotalSeconds *
                  100)
              .clamp(0, 100)
        : 0.0;

    // Get today's workout minutes from actual database
    final todaySummaryAsync = ref.watch(todaySummaryProvider);
    final todayWorkoutMinutes = todaySummaryAsync.maybeWhen(
      data: (summary) => summary.workout,
      orElse: () => 0,
    );

    // TODO(settings-sync): Replace 30-minute baseline with the user's configured workout goal.
    // 운동 목표 시간이 하드코딩되어 있어 DB/설정 값과 일치하지 않습니다.
    final progressPercent = (todayWorkoutMinutes / 30 * 100).clamp(0, 100);

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
              top: MediaQuery.of(context).size.height * 0.25,
              left: 0,
              child: AnimatedBuilder(
                animation: _energyController,
                builder: (context, child) {
                  return Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.coral.withValues(
                            alpha: 0.12 + _energyController.value * 0.08,
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
              bottom: MediaQuery.of(context).size.height * 0.25,
              right: 0,
              child: AnimatedBuilder(
                animation: _energyController,
                builder: (context, child) {
                  return Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFFA726).withValues(
                            alpha: 0.12 + (1 - _energyController.value) * 0.08,
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
                            color: isDark ? Colors.white : AppTheme.coral,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Header badge
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      borderRadius: 20,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 18,
                            color: AppTheme.coral,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.tr('figma_workout_badge_label'),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppTheme.coral,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.bolt,
                            size: 14,
                            color: const Color(0xFFFFA726),
                          ),
                        ],
                      ),
                    ),
                    // Title
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [AppTheme.coral, const Color(0xFFFFA726)],
                      ).createShader(bounds),
                      child: Text(
                        l10n.tr('figma_workout_title'),
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.tr('figma_workout_subtitle'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isDark
                            ? AppTheme.coral.withValues(alpha: 0.8)
                            : AppTheme.coral,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Energy Bank card
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      borderRadius: 24,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                AppTheme.coral.withValues(alpha: 0.2),
                                const Color(0xFFFFA726).withValues(alpha: 0.15),
                              ]
                            : [
                                AppTheme.coral.withValues(alpha: 0.12),
                                const Color(0xFFFFA726).withValues(alpha: 0.08),
                              ],
                      ),
                      shadowColor: AppTheme.coral,
                      shadowOpacity: 0.25,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                progressPercent >= 100 ? '🎉' : '🔥',
                                style: const TextStyle(fontSize: 40),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.tr('figma_workout_energy_bank_title'),
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white
                                                : theme.colorScheme.onSurface,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.tr(
                                        'figma_workout_energy_bank_progress',
                                        {
                                          'minutes': '$todayWorkoutMinutes',
                                          'target': '30',
                                        },
                                      ),
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: isDark
                                                ? AppTheme.coral.withValues(
                                                  alpha: 0.8,
                                                )
                                                : AppTheme.coral,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                l10n.tr('figma_workout_energy_bank_percent', {
                                  'percent': '${progressPercent.round()}',
                                }),
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.coral,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                Container(
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : AppTheme.coral.withValues(
                                            alpha: 0.15,
                                          ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: progressPercent / 100,
                                  child: Container(
                                    height: 16,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.coral,
                                          const Color(0xFFFFA726),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: AnimatedBuilder(
                                      animation: _energyController,
                                      builder: (context, child) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha:
                                                  0.2 +
                                                  _energyController.value * 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Active workout display
                    if (isWorkoutRunning) ...[
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        borderRadius: 24,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.coral.withValues(alpha: 0.3),
                            const Color(0xFFFFA726).withValues(alpha: 0.2),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.coral,
                                        const Color(0xFFFFA726),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.fitness_center_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    l10n.tr('figma_workout_in_progress'),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white
                                              : theme.colorScheme.onSurface,
                                        ),
                                  ),
                                ),
                                Text(
                                  '${(timerState.segmentRemainingSeconds / 60).floor()}:${(timerState.segmentRemainingSeconds % 60).toString().padLeft(2, '0')}',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.coral,
                                      ),
                                ),
                              ],
                            ),
                            if (currentSegmentLabel != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.coral.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.flag_rounded,
                                      color: AppTheme.coral,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      l10n.tr(
                                        'figma_workout_current_step',
                                        {'step': currentSegmentLabel},
                                      ),
                                      style:
                                          theme.textTheme.labelLarge?.copyWith(
                                            color: AppTheme.coral,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: workoutProgress / 100,
                                minHeight: 8,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.2,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.coral,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: GlassCard(
                                    onTap: _handlePlayPause,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    borderRadius: 12,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.pause_rounded,
                                          size: 20,
                                          color: isDark
                                              ? Colors.white
                                              : AppTheme.coral,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          l10n.tr('timer_button_pause'),
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white
                                                    : AppTheme.coral,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GlassCard(
                                    onTap: _handleReset,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    borderRadius: 12,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.stop_rounded,
                                          size: 20,
                                          color: isDark
                                              ? Colors.white
                                              : AppTheme.coral,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          l10n.tr('figma_workout_stop_button'),
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white
                                                    : AppTheme.coral,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Intensity filter
                    Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip(
                                  label: l10n.tr('figma_workout_filter_all'),
                                  isSelected: _selectedIntensity == null,
                                  onTap: () => setState(() => _selectedIntensity = null),
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  label: l10n.tr('figma_workout_filter_light'),
                                  isSelected: _selectedIntensity == WorkoutIntensity.light,
                                  onTap: () => setState(() => _selectedIntensity = WorkoutIntensity.light),
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  label: l10n.tr('figma_workout_filter_moderate'),
                                  isSelected: _selectedIntensity == WorkoutIntensity.moderate,
                                  onTap: () => setState(() => _selectedIntensity = WorkoutIntensity.moderate),
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  label: l10n.tr('figma_workout_filter_vigorous'),
                                  isSelected: _selectedIntensity == WorkoutIntensity.vigorous,
                                  onTap: () => setState(() => _selectedIntensity = WorkoutIntensity.vigorous),
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Workout cards
                    ...workoutLightPresets.where((preset) {
                      // Filter by intensity if selected
                      if (_selectedIntensity == null) return true;
                      return preset.intensity == _selectedIntensity;
                    }).map((preset) {
                      final l10n = context.l10n;
                      final emoji = WorkoutPresetUI.getEmoji(preset);
                      final calories = WorkoutPresetUI.getEstimatedCalories(
                        preset,
                      );
                      final intensityLevel = WorkoutPresetUI.getIntensityLevel(
                        preset.intensity,
                      );
                      final intensityDots = List.generate(
                        intensityLevel,
                        (_) => '🔥',
                      ).join();
                      final name = l10n.tr(preset.labelKey);
                      final description = l10n.tr(preset.descriptionKey);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GlassCard(
                          padding: const EdgeInsets.all(20),
                          borderRadius: 24,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    AppTheme.coral.withValues(alpha: 0.15),
                                    const Color(
                                      0xFFFFA726,
                                    ).withValues(alpha: 0.1),
                                  ]
                                : [
                                    Colors.white.withValues(alpha: 0.95),
                                    Colors.white.withValues(alpha: 0.85),
                                  ],
                          ),
                          shadowColor: AppTheme.coral,
                          shadowOpacity: 0.2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 48),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: isDark
                                                    ? Colors.white
                                                    : theme
                                                          .colorScheme
                                                          .onSurface,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          description,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: isDark
                                                    ? AppTheme.coral.withValues(
                                                        alpha: 0.8,
                                                      )
                                                    : AppTheme.coral,
                                              ),
                                        ),
                                        const SizedBox(height: 12),
                                        // Stats badges
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.coral
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.favorite_rounded,
                                                    size: 14,
                                                    color: AppTheme.coral,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    l10n.tr(
                                                      'figma_workout_calories',
                                                      {'calories': '$calories'},
                                                    ),
                                                    style: theme
                                                        .textTheme
                                                        .labelSmall
                                                        ?.copyWith(
                                                          color: AppTheme.coral,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.coral
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                l10n.tr(
                                                  'figma_workout_duration',
                                                  {
                                                    'minutes':
                                                        '${preset.totalMinutes}',
                                                  },
                                                ),
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: AppTheme.coral,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ),
                                            Text(
                                              intensityDots,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        // Intensity bar
                                        Row(
                                          children: List.generate(5, (index) {
                                            return Expanded(
                                              child: Container(
                                                height: 6,
                                                margin: EdgeInsets.only(
                                                  right: index < 4 ? 4 : 0,
                                                ),
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      index < intensityLevel
                                                      ? LinearGradient(
                                                          colors: [
                                                            AppTheme.coral,
                                                            const Color(
                                                              0xFFFFA726,
                                                            ),
                                                          ],
                                                        )
                                                      : null,
                                                  color: index >= intensityLevel
                                                      ? isDark
                                                            ? Colors.white
                                                                  .withValues(
                                                                    alpha: 0.1,
                                                                  )
                                                            : AppTheme.coral
                                                                  .withValues(
                                                                    alpha: 0.2,
                                                                  )
                                                      : null,
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Start button
                              Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.coral,
                                      const Color(0xFFFFA726),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.coral.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _handleStartWorkout(preset),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.play_arrow_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            l10n.tr('figma_workout_start_button'),
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
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
                            ],
                          ),
                        ),
                      );
                    }),
                    // Energy tip
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      borderRadius: 20,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('⚡', style: TextStyle(fontSize: 32)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.tr('figma_workout_tip_title'),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.tr('figma_workout_tip_body'),
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
