import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:life_app/design/app_theme.dart';
import 'package:life_app/features/backup/backup_page.dart';
import 'package:life_app/features/journal/journal_page.dart';
import 'package:life_app/features/stats/stats_page.dart';
import 'package:life_app/features/timer/figma_timer_tab.dart';
import 'package:life_app/features/workout/figma_workout_tab.dart';
import 'package:life_app/features/sleep/figma_sleep_tab.dart';
import 'package:life_app/l10n/app_localizations.dart';

/// 더보기 페이지 - 모든 기능을 체계적으로 정리
class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final sections = [
      _MoreSection(
        titleKey: 'more_section_focus_rest',
        items: [
          _MoreItem(
            titleKey: 'more_item_focus',
            icon: Icons.psychology_outlined,
            color: AppTheme.teal,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const FigmaTimerTab(initialMode: 'focus'),
                ),
              );
            },
          ),
        ],
      ),
      _MoreSection(
        titleKey: 'more_section_health',
        items: [
          _MoreItem(
            titleKey: 'more_item_workout',
            icon: Icons.fitness_center_outlined,
            color: AppTheme.coral,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const FigmaWorkoutTab(),
                ),
              );
            },
          ),
          _MoreItem(
            titleKey: 'more_item_sleep',
            icon: Icons.bedtime_outlined,
            color: AppTheme.electricViolet,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const FigmaSleepTab(),
                ),
              );
            },
          ),
        ],
      ),
      _MoreSection(
        titleKey: 'more_section_records',
        items: [
          _MoreItem(
            titleKey: 'more_item_journal',
            icon: Icons.book_outlined,
            color: AppTheme.lime,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const JournalPage(),
                ),
              );
            },
          ),
          _MoreItem(
            titleKey: 'more_item_stats',
            icon: Icons.bar_chart_rounded,
            color: AppTheme.eucalyptus,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const StatsPage(),
                ),
              );
            },
          ),
          _MoreItem(
            titleKey: 'more_item_backup',
            icon: Icons.cloud_upload_outlined,
            color: AppTheme.teal,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const BackupPage(),
                ),
              );
            },
          ),
        ],
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    theme.colorScheme.surfaceContainerLowest,
                    theme.colorScheme.surfaceContainerHighest,
                  ]
                : [
                    theme.colorScheme.surfaceContainerLowest,
                    AppTheme.eucalyptus.withValues(alpha: 0.08),
                    AppTheme.teal.withValues(alpha: 0.08),
                  ],
            stops: isDark ? const [0.0, 1.0] : const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // 헤더
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Text(
                    l10n.tr('more_title'),
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
              for (var i = 0; i < sections.length; i++) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Text(
                      l10n.tr(sections[i].titleKey),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
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
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = sections[i].items[index];
                        return _GridMenuCard(
                          title: l10n.tr(item.titleKey),
                          icon: item.icon,
                          color: item.color,
                          onTap: item.onTap,
                        );
                      },
                      childCount: sections[i].items.length,
                    ),
                  ),
                ),
                if (i < sections.length - 1)
                  const SliverToBoxAdapter(child: SizedBox(height: 24))
                else
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreSection {
  const _MoreSection({
    required this.titleKey,
    required this.items,
  });

  final String titleKey;
  final List<_MoreItem> items;
}

class _MoreItem {
  const _MoreItem({
    required this.titleKey,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String titleKey;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

/// 카카오페이 스타일 그리드 카드
class _GridMenuCard extends StatelessWidget {
  const _GridMenuCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    const borderRadius = BorderRadius.all(Radius.circular(12));
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(
                  alpha: isDark ? 0.2 : 0.06,
                ),
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
                  color: color.withValues(alpha: isDark ? 0.2 : 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
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
