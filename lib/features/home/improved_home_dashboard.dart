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
    final focusProgress = ((todaySummary.focus / focusGoal) * 100).clamp(
      0.0,
      100.0,
    );
    final workoutProgress = ((todaySummary.workout / workoutGoal) * 100).clamp(
      0.0,
      100.0,
    );
    final sleepProgress = ((todaySummary.sleep / (sleepGoalHours * 60)) * 100)
        .clamp(0.0, 100.0);

    final totalProgress =
        ((focusProgress + workoutProgress + sleepProgress) / 3).round().clamp(
          0,
          100,
        );

    // Life Buddy 메시지
    String buddyMessage;
    Color buddyColor;

    if (totalProgress == 0) {
      buddyMessage = '오늘 하루를 시작해볼까요?';
      buddyColor = AppTheme.lime;
    } else if (totalProgress < 30) {
      buddyMessage = '좋은 시작이에요!';
      buddyColor = AppTheme.teal;
    } else if (totalProgress < 70) {
      buddyMessage = '멋져요! 계속 해봐요!';
      buddyColor = AppTheme.eucalyptus;
    } else {
      buddyMessage = '와! 오늘 정말 최고예요!';
      buddyColor = AppTheme.coral;
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF8F0), // Warm cream
              Color(0xFFFFF0F5), // Light pink
              Color(0xFFF0F8FF), // Light blue
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
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
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 큰 Life Buddy 캐릭터 카드
                  _BigCharacterCard(
                    message: buddyMessage,
                    color: buddyColor,
                    progress: totalProgress,
                    totalMinutes:
                        todaySummary.focus +
                        todaySummary.workout +
                        todaySummary.sleep,
                  ),
                  const SizedBox(height: 18),

                  // 활동 카드 그리드 (2x2)
                  Row(
                    children: [
                      Expanded(
                        child: _CharacterActivityCard(
                          emoji: '🧠',
                          title: '집중',
                          minutes: todaySummary.focus,
                          goal: focusGoal,
                          progress: focusProgress,
                          color: AppTheme.teal,
                          height: 190,
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
                      const SizedBox(width: 14),
                      Expanded(
                        child: _CharacterActivityCard(
                          emoji: '💪',
                          title: '운동',
                          minutes: todaySummary.workout,
                          goal: workoutGoal,
                          progress: workoutProgress,
                          color: AppTheme.coral,
                          height: 190,
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
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _CharacterActivityCard(
                          emoji: '😴',
                          title: '수면',
                          minutes: (todaySummary.sleep / 60).round(),
                          goal: sleepGoalHours,
                          progress: sleepProgress,
                          color: AppTheme.electricViolet,
                          unit: 'h',
                          height: 190,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const FigmaSleepTab(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _CharacterActivityCard(
                          emoji: '📝',
                          title: '저널',
                          minutes: 0,
                          goal: 1,
                          progress: 0,
                          color: AppTheme.lime,
                          unit: '개',
                          height: 190,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const JournalPage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 큰 Life Buddy 캐릭터 카드
class _BigCharacterCard extends StatelessWidget {
  const _BigCharacterCard({
    required this.message,
    required this.color,
    required this.progress,
    required this.totalMinutes,
  });

  final String message;
  final Color color;
  final int progress;
  final int totalMinutes;

  @override
  Widget build(BuildContext context) {
    String emoji;
    if (progress == 0) {
      emoji = '😴';
    } else if (progress < 30) {
      emoji = '🌱';
    } else if (progress < 70) {
      emoji = '✨';
    } else {
      emoji = '🎉';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          // 큰 이모지
          Text(emoji, style: const TextStyle(fontSize: 80)),
          const SizedBox(width: 20),
          // 메시지와 진행률
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '오늘 $totalMinutes분 활동했어요',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                // 진행률 바
                Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress / 100,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withValues(alpha: 0.8)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$progress% 완료',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 캐릭터 중심 활동 카드
class _CharacterActivityCard extends StatelessWidget {
  const _CharacterActivityCard({
    required this.emoji,
    required this.title,
    required this.minutes,
    required this.goal,
    required this.progress,
    required this.color,
    required this.height,
    required this.onTap,
    this.unit = '분',
  });

  final String emoji;
  final String title;
  final int minutes;
  final int goal;
  final double progress;
  final Color color;
  final double height;
  final VoidCallback onTap;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, color.withValues(alpha: 0.08)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이모지
            Text(emoji, style: const TextStyle(fontSize: 48)),
            // 진행률과 정보
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$minutes',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: color,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '/$goal$unit',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // 진행률 바
                Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: (progress / 100).clamp(0.0, 1.0),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
