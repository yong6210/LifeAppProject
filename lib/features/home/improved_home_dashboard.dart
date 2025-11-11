import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:life_app/design/app_theme.dart';
import 'package:life_app/features/timer/figma_timer_tab.dart';
import 'package:life_app/features/workout/figma_workout_tab.dart';
import 'package:life_app/features/sleep/figma_sleep_tab.dart';
import 'package:life_app/features/journal/journal_page.dart';
import 'package:life_app/providers/settings_providers.dart';
import 'package:life_app/providers/session_providers.dart';

/// 개선된 홈 화면 - Life Buddy 중심
class ImprovedHomeDashboard extends ConsumerWidget {
  const ImprovedHomeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? '좋은 아침!'
        : hour < 18
            ? '좋은 오후!'
            : '좋은 저녁!';

    final settingsAsync = ref.watch(settingsFutureProvider);
    final settings = settingsAsync.asData?.value;
    final todaySummary = ref
        .watch(todaySummaryProvider)
        .maybeWhen(data: (value) => value, orElse: () => const TodaySummary());

    // 목표 설정
    final focusGoal = (settings?.focusMinutes ?? 25);
    final workoutGoal = 30;
    final sleepGoalHours = 8;

    // 진행률
    final focusProgress =
        ((todaySummary.focus / focusGoal) * 100).clamp(0.0, 100.0);
    final workoutProgress =
        ((todaySummary.workout / workoutGoal) * 100).clamp(0.0, 100.0);
    final sleepProgress =
        ((todaySummary.sleep / (sleepGoalHours * 60)) * 100).clamp(0.0, 100.0);

    final totalProgress = ((focusProgress + workoutProgress + sleepProgress) / 3)
        .round()
        .clamp(0, 100);

    // Life Buddy 메시지
    String buddyMessage;
    IconData buddyIcon;
    Color buddyColor;

    if (totalProgress == 0) {
      buddyMessage = '오늘 하루를 시작해볼까요?';
      buddyIcon = Icons.wb_sunny_outlined;
      buddyColor = AppTheme.lime;
    } else if (totalProgress < 30) {
      buddyMessage = '좋은 시작이에요!';
      buddyIcon = Icons.favorite_border;
      buddyColor = AppTheme.teal;
    } else if (totalProgress < 70) {
      buddyMessage = '멋져요! 계속 해봐요!';
      buddyIcon = Icons.stars_outlined;
      buddyColor = AppTheme.eucalyptus;
    } else {
      buddyMessage = '와! 오늘 정말 최고예요!';
      buddyIcon = Icons.celebration_outlined;
      buddyColor = AppTheme.coral;
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF0F4E8),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.eucalyptus,
          onRefresh: () async {
            ref.invalidate(settingsFutureProvider);
            ref.invalidate(todaySummaryProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 인사말
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 20),

                // Life Buddy 카드 (컴팩트)
                _LifeBuddyCard(
                  message: buddyMessage,
                  icon: buddyIcon,
                  color: buddyColor,
                  progress: totalProgress,
                ),
                const SizedBox(height: 16),

                // 빠른 시작
                Text(
                  '빠른 시작',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),

                // 4x1 그리드 (카카오페이 스타일)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.8,
                  children: [
                    _QuickActionCard(
                      title: '집중',
                      icon: Icons.psychology_outlined,
                      color: AppTheme.teal,
                      isDark: isDark,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const FigmaTimerTab(),
                          ),
                        );
                      },
                    ),
                    _QuickActionCard(
                      title: '운동',
                      icon: Icons.fitness_center_outlined,
                      color: AppTheme.coral,
                      isDark: isDark,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const FigmaWorkoutTab(),
                          ),
                        );
                      },
                    ),
                    _QuickActionCard(
                      title: '수면',
                      icon: Icons.bedtime_outlined,
                      color: AppTheme.electricViolet,
                      isDark: isDark,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const FigmaSleepTab(),
                          ),
                        );
                      },
                    ),
                    _QuickActionCard(
                      title: '저널',
                      icon: Icons.book_outlined,
                      color: AppTheme.lime,
                      isDark: isDark,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const JournalPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 오늘의 기록
                Text(
                  '오늘의 기록',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),

                _TodayProgressCard(
                  focusMinutes: todaySummary.focus,
                  focusGoal: focusGoal,
                  focusProgress: focusProgress,
                  workoutMinutes: todaySummary.workout,
                  workoutGoal: workoutGoal,
                  workoutProgress: workoutProgress,
                  sleepMinutes: todaySummary.sleep,
                  sleepGoal: sleepGoalHours * 60,
                  sleepProgress: sleepProgress,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 빠른 액션 카드 (카카오페이 스타일)
class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Life Buddy 카드 - 캐릭터와 메시지 (애니메이션 추가)
class _LifeBuddyCard extends StatefulWidget {
  const _LifeBuddyCard({
    required this.message,
    required this.icon,
    required this.color,
    required this.progress,
  });

  final String message;
  final IconData icon;
  final Color color;
  final int progress;

  @override
  State<_LifeBuddyCard> createState() => _LifeBuddyCardState();
}

class _LifeBuddyCardState extends State<_LifeBuddyCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Life Buddy 아바타 (애니메이션, 컴팩트)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _bounceAnimation.value),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      size: 28,
                      color: widget.color,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),

          // 메시지와 진행률 (컴팩트)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.message,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: widget.progress / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              color: widget.color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.progress}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: widget.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 오늘의 진행상황 카드
class _TodayProgressCard extends StatelessWidget {
  const _TodayProgressCard({
    required this.focusMinutes,
    required this.focusGoal,
    required this.focusProgress,
    required this.workoutMinutes,
    required this.workoutGoal,
    required this.workoutProgress,
    required this.sleepMinutes,
    required this.sleepGoal,
    required this.sleepProgress,
  });

  final int focusMinutes;
  final int focusGoal;
  final double focusProgress;
  final int workoutMinutes;
  final int workoutGoal;
  final double workoutProgress;
  final int sleepMinutes;
  final int sleepGoal;
  final double sleepProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProgressRow(
            icon: Icons.psychology_outlined,
            label: '집중',
            value: focusMinutes,
            goal: focusGoal,
            unit: '분',
            progress: focusProgress,
            color: AppTheme.teal,
          ),
          const SizedBox(height: 12),

          _ProgressRow(
            icon: Icons.fitness_center_outlined,
            label: '운동',
            value: workoutMinutes,
            goal: workoutGoal,
            unit: '분',
            progress: workoutProgress,
            color: AppTheme.coral,
          ),
          const SizedBox(height: 12),

          _ProgressRow(
            icon: Icons.bedtime_outlined,
            label: '수면',
            value: (sleepMinutes / 60).toStringAsFixed(1),
            goal: (sleepGoal / 60).toStringAsFixed(0),
            unit: '시간',
            progress: sleepProgress,
            color: AppTheme.electricViolet,
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.goal,
    required this.unit,
    required this.progress,
    required this.color,
  });

  final IconData icon;
  final String label;
  final dynamic value;
  final dynamic goal;
  final String unit;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    '$value / $goal $unit',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.black45,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

