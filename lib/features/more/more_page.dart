import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:life_app/design/app_theme.dart';
import 'package:life_app/features/journal/journal_page.dart';
import 'package:life_app/features/stats/stats_page.dart';
import 'package:life_app/features/timer/figma_timer_tab.dart';
import 'package:life_app/features/workout/figma_workout_tab.dart';
import 'package:life_app/features/sleep/figma_sleep_tab.dart';

/// 더보기 페이지 - 모든 기능을 체계적으로 정리
class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF0F4E8),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 헤더
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Text(
                  '더보기',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                    height: 1.2,
                  ),
                ),
              ),
            ),

            // 집중 & 휴식
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  '집중 & 휴식',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildListDelegate([
                  _GridMenuCard(
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
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // 건강 활동
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  '건강 활동',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildListDelegate([
                  _GridMenuCard(
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
                  _GridMenuCard(
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
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // 기록 & 분석
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  '기록 & 분석',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildListDelegate([
                  _GridMenuCard(
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
                  _GridMenuCard(
                    title: '통계',
                    icon: Icons.bar_chart_rounded,
                    color: AppTheme.eucalyptus,
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const StatsPage(),
                        ),
                      );
                    },
                  ),
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

/// 카카오페이 스타일 그리드 카드
class _GridMenuCard extends StatelessWidget {
  const _GridMenuCard({
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
