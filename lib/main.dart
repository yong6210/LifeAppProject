import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:life_app/core/firebase/firebase_initializer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:life_app/design/app_theme.dart';
import 'package:life_app/features/timer/timer_page.dart';
import 'package:life_app/features/stats/stats_page.dart';
import 'package:life_app/features/account/account_page.dart';
import 'package:life_app/features/onboarding/onboarding_page.dart';
import 'package:life_app/features/journal/journal_page.dart';
import 'package:life_app/models/settings.dart';
import 'package:life_app/providers/auth_providers.dart';
import 'package:life_app/providers/session_providers.dart';
import 'package:life_app/providers/sync_providers.dart';
import 'package:life_app/providers/settings_providers.dart';
import 'package:life_app/providers/backup_providers.dart';
import 'package:life_app/services/analytics/analytics_service.dart';
import 'package:life_app/services/notification_service.dart';
import 'package:life_app/services/background/workmanager_scheduler.dart';
import 'package:life_app/services/subscription/revenuecat_service.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:life_app/providers/sleep_analysis_providers.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await FirebaseInitializer.ensureInitialized();
    } catch (_) {
      // Continue boot; Firebase operations will throw descriptive errors later.
    }
    await AnalyticsService.init();
    await NotificationService.init();
    await TimerWorkmanagerGuard.initialize();
    runApp(const ProviderScope(child: MyApp()));
  }, (error, stack) {
    unawaited(
      AnalyticsService.recordError(
        error,
        stack,
        fatal: true,
        reason: 'uncaught_zone',
      ),
    );
  });
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Locale? locale = ref.watch(appLocaleControllerProvider);
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          onGenerateTitle: (context) => context.l10n.tr('app_title'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          theme: AppTheme.lightTheme(dynamicColor: lightDynamic),
          darkTheme: AppTheme.darkTheme(dynamicColor: darkDynamic),
          themeMode: ThemeMode.system,
          home: const MyHomePage(),
        );
      },
    );
  }
}

Widget? _buildSyncBanner({
  required BuildContext context,
  required AsyncValue<void> syncState,
  required AsyncValue<User?> authState,
  required AppLocalizations l10n,
}) {
  final theme = Theme.of(context);
  IconData icon;
  String message;
  List<Color> gradient;

  if (authState.value == null) {
    icon = Icons.cloud_off_rounded;
    message = l10n.tr('home_sync_signed_out');
    gradient = [
      theme.colorScheme.error.withValues(alpha: 0.85),
      theme.colorScheme.error.withValues(alpha: 0.65),
    ];
  } else if (syncState.isLoading) {
    icon = Icons.sync_rounded;
    message = l10n.tr('home_sync_in_progress');
    gradient = [
      theme.colorScheme.primary,
      theme.colorScheme.primary.withValues(alpha: 0.75),
    ];
  } else if (syncState.hasError) {
    icon = Icons.sync_problem;
    message = l10n.tr('home_sync_error');
    gradient = [
      theme.colorScheme.error,
      theme.colorScheme.error.withValues(alpha: 0.7),
    ];
  } else {
    return null;
  }

  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: gradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: gradient.last.withValues(alpha: 0.2),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key});

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

String _formatMinutesLabel(int minutes) {
  if (minutes <= 0) {
    return '0분';
  }
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (hours > 0 && mins > 0) {
    return '$hours시간 $mins분';
  } else if (hours > 0) {
    return '$hours시간';
  }
  return '$mins분';
}

class _HomeSummaryCard extends StatelessWidget {
  const _HomeSummaryCard({
    required this.dateLabel,
    required this.focusMinutes,
    required this.focusGoalMinutes,
    required this.sleepMinutes,
    required this.workoutMinutes,
  });

  final String dateLabel;
  final int focusMinutes;
  final int focusGoalMinutes;
  final int sleepMinutes;
  final int workoutMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final focusPercent = focusGoalMinutes == 0
        ? 0
        : ((focusMinutes / focusGoalMinutes) * 100).clamp(0, 999).toInt();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SummaryTile(
                    title: '집중',
                    value: _formatMinutesLabel(focusMinutes),
                    subtitle: '목표 대비 $focusPercent%',
                    color: const Color(0xFFFFA94D),
                    icon: Icons.center_focus_strong_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const TimerPage(
                            initialMode: 'focus',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryTile(
                    title: '수면',
                    value: _formatMinutesLabel(sleepMinutes),
                    subtitle: '수면 모드 열기',
                    color: const Color(0xFF4D9EFF),
                    icon: Icons.nightlight_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              TimerPage(initialMode: 'sleep', autoStart: false),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryTile(
                    title: '운동',
                    value: _formatMinutesLabel(workoutMinutes),
                    subtitle: '운동 모드 열기',
                    color: const Color(0xFF6BCB77),
                    icon: Icons.fitness_center_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const TimerPage(
                            initialMode: 'workout',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeDashboardTab extends ConsumerWidget {
  const _HomeDashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final settingsAsync = ref.watch(settingsFutureProvider);
    final settings = settingsAsync.asData?.value;
    final todaySummary = ref
        .watch(todaySummaryProvider)
        .maybeWhen(data: (value) => value, orElse: () => const TodaySummary());
    final syncState = ref.watch(syncControllerProvider);
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final dateLabel = DateFormat.yMMMMd(
      locale.toLanguageTag(),
    ).format(DateTime.now());
    final focusGoalBaseMinutes = settings?.focusMinutes ?? 25;
    final focusGoalMinutes =
        ((focusGoalBaseMinutes * 4).clamp(0, 600)).toInt();

    final banner = _buildSyncBanner(
      context: context,
      syncState: syncState,
      authState: authState,
      l10n: l10n,
    );

    Future<void> openTimer(
      String mode, {
      bool autoStart = false,
    }) async {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => TimerPage(initialMode: mode, autoStart: autoStart),
        ),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        onRefresh: () async {
          ref.invalidate(settingsFutureProvider);
          ref.invalidate(todaySummaryProvider);
          ref.invalidate(latestSleepSoundSummaryProvider);
        },
        child: ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            _HomeSummaryCard(
              dateLabel: dateLabel,
              focusMinutes: todaySummary.focus,
              focusGoalMinutes: focusGoalMinutes,
              sleepMinutes: todaySummary.sleep,
              workoutMinutes: todaySummary.workout,
            ),
            if (banner != null) ...[
              const SizedBox(height: 20),
              banner,
            ],
            const SizedBox(height: 24),
            _QuickAccessCard(onOpenTimer: openTimer),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({required this.onOpenTimer});

  final Future<void> Function(String mode, {bool autoStart}) onOpenTimer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '빠른 실행',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => onOpenTimer('focus', autoStart: true),
                  icon: const Icon(Icons.center_focus_strong_rounded),
                  label: const Text('집중 바로 시작'),
                ),
                FilledButton.icon(
                  onPressed: () => onOpenTimer('sleep'),
                  icon: const Icon(Icons.nightlight_round),
                  label: const Text('수면 준비'),
                ),
                FilledButton.icon(
                  onPressed: () => onOpenTimer('workout'),
                  icon: const Icon(Icons.fitness_center_rounded),
                  label: const Text('운동 탐색'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const StatsPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.insights_outlined),
                  label: const Text('분석 살펴보기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  bool _onboardingShown = false;
  ProviderSubscription<AsyncValue<Settings>>? _settingsSubscription;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _settingsSubscription = ref.listenManual<AsyncValue<Settings>>(
      settingsFutureProvider,
      (previous, next) {
        next.whenData((settings) async {
          final reminderService = await ref.read(
            backupReminderServiceProvider.future,
          );
          final shouldNotify = await reminderService.shouldNotify(settings);
          if (shouldNotify && mounted) {
            final l10n = context.l10n;
            final lastBackup = settings.lastBackupAt;
            final now = DateTime.now().toUtc();
            final daysSince = lastBackup == null
                ? null
                : now.difference(lastBackup.toUtc()).inDays;
            await NotificationService.showBackupReminder(
              title: l10n.tr('backup_reminder_title'),
              body: l10n.tr('backup_reminder_body'),
            );
            await reminderService.markNotified();
            await AnalyticsService.logEvent('backup_reminder_shown', {
              if (daysSince != null) 'days_since_last_backup': daysSince,
              'has_backup': lastBackup != null,
            });
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _settingsSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(revenueCatControllerProvider);
    final settingsAsync = ref.watch(settingsFutureProvider);
    settingsAsync.whenData((settings) {
      if (!_onboardingShown && !settings.hasCompletedOnboarding) {
        _onboardingShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const OnboardingPage()),
          );
        });
      }
    });
    final tabs = const [
      _HomeDashboardTab(),
      StatsPage(),
      JournalPage(),
      AccountPage(),
    ];
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (_currentIndex == index) return;
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: '메인',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_graph_outlined),
            selectedIcon: Icon(Icons.auto_graph_rounded),
            label: '분석',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book_rounded),
            label: '저널',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '프로필',
          ),
        ],
      ),
    );
  }
}







// Legacy home widgets removed during dashboard refactor.
