import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:life_app/design/app_theme.dart';
import 'package:life_app/features/account/account_page.dart';
import 'package:life_app/features/stats/stats_page.dart';
import 'package:life_app/features/timer/figma_timer_tab.dart';
import 'package:life_app/features/workout/figma_workout_tab.dart';
import 'package:life_app/features/sleep/figma_sleep_tab.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/models/routine.dart';
import 'package:life_app/providers/routine_providers.dart';
import 'package:life_app/providers/session_providers.dart';
import 'package:life_app/providers/settings_providers.dart';
import 'package:life_app/providers/stats_providers.dart';
import 'package:life_app/widgets/glass_card.dart';

/// Home Dashboard with Figma design
/// Features dark gradient background, glassmorphism cards, and Life Buddy aesthetics
class FigmaHomeDashboard extends ConsumerWidget {
  const FigmaHomeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? l10n.tr('home_dashboard_greeting_morning')
        : hour < 18
            ? l10n.tr('home_dashboard_greeting_afternoon')
            : l10n.tr('home_dashboard_greeting_evening');

    final settingsAsync = ref.watch(settingsFutureProvider);
    final settings = settingsAsync.asData?.value;
    final todaySummary = ref
        .watch(todaySummaryProvider)
        .maybeWhen(data: (value) => value, orElse: () => const TodaySummary());
    final streakDays = ref
        .watch(streakCountProvider)
        .maybeWhen(data: (value) => value, orElse: () => 0);
    final routines = ref
        .watch(routinesStreamProvider)
        .maybeWhen(data: (value) => value, orElse: () => <Routine>[]);

    // Calculate progress
    final focusGoal = (settings?.focusMinutes ?? 25);
    const workoutGoal = 30;
    const sleepGoalHours = 8;
    const sleepGoalMinutes = sleepGoalHours * 60;

    final focusProgress =
        ((todaySummary.focus / focusGoal) * 100).clamp(0.0, 100.0);
    final workoutProgress =
        ((todaySummary.workout / workoutGoal) * 100).clamp(0.0, 100.0);
    final sleepProgress =
        ((todaySummary.sleep / sleepGoalMinutes) * 100).clamp(0.0, 100.0);

    final completedGoals = [
      focusProgress >= 100,
      workoutProgress >= 100,
      sleepProgress >= 100
    ].where((e) => e).length;

    final totalProgress = ((focusProgress + workoutProgress + sleepProgress) / 3)
        .round()
        .clamp(0, 100);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0E14),
              Color(0xFF0F1419),
              Color(0xFF141B2D),
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Ambient glow
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 384,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.5,
                    colors: [
                      AppTheme.teal.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6],
                  ),
                ),
              ),
            ),
            // Content
            SafeArea(
              child: RefreshIndicator(
                color: AppTheme.eucalyptus,
                backgroundColor: const Color(0xFF111318),
                onRefresh: () async {
                  ref.invalidate(settingsFutureProvider);
                  ref.invalidate(todaySummaryProvider);
                  ref.invalidate(streakCountProvider);
                },
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const SizedBox(height: 48),
                    // Header
                    _buildHeader(
                      context: context,
                      greeting: greeting,
                      onSettingsTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const AccountPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    // Progress Hero Card
                    _buildProgressHero(
                      context: context,
                      totalProgress: totalProgress,
                      completedGoals: completedGoals,
                      focusProgress: focusProgress,
                      workoutProgress: workoutProgress,
                      sleepProgress: sleepProgress,
                      streakDays: streakDays,
                      level: 1, // TODO: Get from user stats
                    ),
                    const SizedBox(height: 20),
                    // Routines Section
                    if (routines.isNotEmpty) ...[
                      _buildRoutinesSection(
                        context: context,
                        routines: routines,
                      ),
                      const SizedBox(height: 20),
                    ],
                    // Activity Cards Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildFocusCard(
                            context: context,
                            minutes: todaySummary.focus,
                            goal: focusGoal,
                            progress: focusProgress,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const FigmaTimerTab(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMoveCard(
                            context: context,
                            minutes: todaySummary.workout,
                            goal: workoutGoal,
                            progress: workoutProgress,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const FigmaWorkoutTab(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Rest card (full width)
                    _buildRestCard(
                      context: context,
                      minutes: todaySummary.sleep,
                      goalHours: sleepGoalHours,
                      progress: sleepProgress,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const FigmaSleepTab(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    // View Stats CTA
                    _buildStatsCTA(
                      context: context,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const StatsPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 96), // Bottom spacing for tab bar
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required BuildContext context,
    required String greeting,
    required VoidCallback onSettingsTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppTheme.eucalyptus, AppTheme.teal],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.eucalyptus.withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 9,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Life Buddy',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
        GestureDetector(
          onTap: onSettingsTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.settings_outlined,
              size: 18,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressHero({
    required BuildContext context,
    required int totalProgress,
    required int completedGoals,
    required double focusProgress,
    required double workoutProgress,
    required double sleepProgress,
    required int streakDays,
    required int level,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.bolt,
                      size: 14,
                      color: AppTheme.eucalyptus,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'TODAY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.5),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Colors.white, Colors.white.withValues(alpha: 0.88)],
                      ).createShader(bounds),
                      child: Text(
                        totalProgress.toString(),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1,
                          letterSpacing: -2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildProgressDot(focusProgress >= 100, AppTheme.teal),
                    const SizedBox(width: 8),
                    _buildProgressDot(workoutProgress >= 100, AppTheme.coral),
                    const SizedBox(width: 8),
                    _buildProgressDot(
                        sleepProgress >= 100, AppTheme.electricViolet),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              _buildMiniStat(
                icon: Icons.local_fire_department,
                value: streakDays.toString(),
                label: 'STREAK',
                color: AppTheme.coral,
              ),
              const SizedBox(height: 12),
              _buildMiniStat(
                icon: Icons.emoji_events,
                value: level.toString(),
                label: 'LEVEL',
                color: AppTheme.lime,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDot(bool isCompleted, Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted ? color : color.withValues(alpha: 0.3),
        boxShadow: isCompleted
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.4),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 20, color: color),
      ],
    );
  }

  Widget _buildFocusCard({
    required BuildContext context,
    required int minutes,
    required int goal,
    required double progress,
    required VoidCallback onTap,
  }) {
    final isCompleted = progress >= 100;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.teal.withValues(alpha: 0.18),
            AppTheme.teal.withValues(alpha: 0.06),
          ],
        ),
        shadowColor: isCompleted ? AppTheme.teal : null,
        shadowOpacity: isCompleted ? 0.25 : 0.2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.teal, AppTheme.tealLight],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.teal.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle : Icons.psychology,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                Icon(
                  Icons.arrow_outward,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Focus',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  minutes.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '/ $goal',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress / 100,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.teal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoveCard({
    required BuildContext context,
    required int minutes,
    required int goal,
    required double progress,
    required VoidCallback onTap,
  }) {
    final isCompleted = progress >= 100;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.coral.withValues(alpha: 0.18),
            AppTheme.coral.withValues(alpha: 0.06),
          ],
        ),
        shadowColor: isCompleted ? AppTheme.coral : null,
        shadowOpacity: isCompleted ? 0.25 : 0.2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.coral, AppTheme.coralLight],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.coral.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle : Icons.fitness_center,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                Icon(
                  Icons.arrow_outward,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Move',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  minutes.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '/ $goal',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress / 100,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.coral),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestCard({
    required BuildContext context,
    required int minutes,
    required int goalHours,
    required double progress,
    required VoidCallback onTap,
  }) {
    final isCompleted = progress >= 100;
    final hours = (minutes / 60).floor();

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.electricViolet.withValues(alpha: 0.18),
            AppTheme.electricViolet.withValues(alpha: 0.06),
          ],
        ),
        shadowColor: isCompleted ? AppTheme.electricViolet : null,
        shadowOpacity: isCompleted ? 0.25 : 0.2,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppTheme.electricViolet,
                    AppTheme.electricVioletLight
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.electricViolet.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                isCompleted ? Icons.check_circle : Icons.nightlight_round,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rest & Recovery',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        hours.toString(),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/ $goalHours hours',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.electricViolet),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  '${progress.round()}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                Icon(
                  Icons.arrow_outward,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCTA({
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.eucalyptus.withValues(alpha: 0.12),
            AppTheme.eucalyptus.withValues(alpha: 0.06),
          ],
        ),
        shadowColor: AppTheme.eucalyptus,
        shadowOpacity: 0.12,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.eucalyptus, AppTheme.teal],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.eucalyptus.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.trending_up,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'View Statistics',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Insights & trends',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutinesSection({
    required BuildContext context,
    required List<Routine> routines,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '오늘의 루틴',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                '${routines.length}개',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.eucalyptus,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Routine cards - horizontal scrollable
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: routines.length,
            itemBuilder: (context, index) {
              final routine = routines[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < routines.length - 1 ? 12 : 0,
                ),
                child: _buildRoutineCard(
                  context: context,
                  routine: routine,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRoutineCard({
    required BuildContext context,
    required Routine routine,
  }) {
    final theme = Theme.of(context);

    // Calculate total duration
    final totalMinutes = routine.steps.fold<int>(
      0,
      (sum, step) => sum + step.durationMinutes,
    );

    // Get color based on theme
    final color = _getRoutineColor(routine.colorTheme);

    // Count steps by mode
    final focusSteps = routine.steps.where((s) => s.mode == 'focus').length;
    final workoutSteps = routine.steps.where((s) => s.mode == 'workout').length;
    final sleepSteps = routine.steps.where((s) => s.mode == 'sleep').length;
    final restSteps = routine.steps.where((s) => s.mode == 'rest').length;

    return GlassCard(
      onTap: () {
        // TODO: Start routine
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${routine.name} 루틴 시작!'),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: 0.2),
          color.withValues(alpha: 0.1),
        ],
      ),
      shadowColor: color,
      shadowOpacity: 0.25,
      child: SizedBox(
        width: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and steps count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_circle_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${routine.steps.length} steps',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Routine name
            Text(
              routine.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            // Duration and step icons
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  '$totalMinutes분',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Mode icons
                if (focusSteps > 0)
                  Icon(
                    Icons.psychology,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                if (workoutSteps > 0) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.fitness_center,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ],
                if (restSteps > 0 || sleepSteps > 0) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.nightlight_round,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoutineColor(String theme) {
    switch (theme) {
      case 'focus':
        return AppTheme.electricViolet;
      case 'energy':
        return AppTheme.coral;
      case 'calm':
        return AppTheme.teal;
      case 'balance':
        return AppTheme.lime;
      default:
        return AppTheme.eucalyptus;
    }
  }
}
