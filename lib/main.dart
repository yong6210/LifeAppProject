import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:life_app/core/firebase/firebase_initializer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:life_app/design/app_theme.dart';
import 'package:life_app/features/timer/timer_page.dart';
import 'package:life_app/features/backup/backup_page.dart';
import 'package:life_app/features/stats/stats_page.dart';
import 'package:life_app/features/subscription/paywall_page.dart';
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
import 'package:life_app/services/audio/sleep_sound_analyzer.dart';
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
      theme: AppTheme.lightTheme(),
      home: const MyHomePage(),
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

class _QuickStartPreset {
  const _QuickStartPreset({
    required this.label,
    required this.mode,
    this.minutes,
  });

  final String label;
  final String mode;
  final int? minutes;
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

String _formatBackupLabel(DateTime? lastBackupAt) {
  if (lastBackupAt == null) {
    return '백업 기록 없음';
  }
  final now = DateTime.now();
  final diff = now.difference(lastBackupAt);
  if (diff.inDays >= 1) {
    return '${diff.inDays}일 전';
  }
  if (diff.inHours >= 1) {
    return '${diff.inHours}시간 전';
  }
  return '방금';
}

class _HomeSummaryCard extends StatelessWidget {
  const _HomeSummaryCard({
    required this.dateLabel,
    required this.focusMinutes,
    required this.focusGoalMinutes,
    required this.sleepMinutes,
    required this.lastBackupAt,
    required this.l10n,
  });

  final String dateLabel;
  final int focusMinutes;
  final int focusGoalMinutes;
  final int sleepMinutes;
  final DateTime? lastBackupAt;
  final AppLocalizations l10n;

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
                    icon: Icons.auto_graph_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const StatsPage(),
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
                    subtitle: '수면 모드 보기',
                    color: const Color(0xFF4D9EFF),
                    icon: Icons.nights_stay_rounded,
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
                    title: '백업',
                    value: _formatBackupLabel(lastBackupAt),
                    subtitle: '지금 백업',
                    color: const Color(0xFF4FE3C1),
                    icon: Icons.cloud_upload_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const BackupPage(),
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

class _MyHomePageState extends ConsumerState<MyHomePage> {
  bool _onboardingShown = false;
  ProviderSubscription<AsyncValue<Settings>>? _settingsSubscription;

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
    final authState = ref.watch(authControllerProvider);
    final premiumStatus = ref.watch(premiumStatusProvider);
    ref.watch(revenueCatControllerProvider);
    final settingsAsync = ref.watch(settingsFutureProvider);
    final settings = settingsAsync.asData?.value;
    final todaySummary = ref
        .watch(todaySummaryProvider)
        .maybeWhen(data: (value) => value, orElse: () => const TodaySummary());
    final sleepSummaryAsync = ref.watch(latestSleepSoundSummaryProvider);
    final sleepSummary = sleepSummaryAsync.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final syncState = ref.watch(syncControllerProvider);
    final l10n = context.l10n;
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
    final isPremium = premiumStatus.isPremium;
    final locale = Localizations.localeOf(context);
    final dateLabel = DateFormat.yMMMMd(
      locale.toLanguageTag(),
    ).format(DateTime.now());

    final focusMinutesToday = todaySummary.focus;
    final sleepMinutes = todaySummary.sleep;
    final focusGoalBaseMinutes = settings?.focusMinutes ?? 25;
    final focusGoalMinutes =
        ((focusGoalBaseMinutes * 4).clamp(0, 600)).toInt();
    double focusProgress = 0;
    if (focusGoalMinutes > 0) {
      focusProgress = focusMinutesToday / focusGoalMinutes;
    }
    focusProgress = focusProgress.clamp(0.0, 1.0).toDouble();

    final focusPresets = <_QuickStartPreset>[
      for (final preset in settings?.presets ?? const <Preset>[])
        if (preset.mode == 'focus')
          _QuickStartPreset(
            label: preset.name,
            mode: preset.mode,
            minutes: preset.durationMinutes,
          ),
    ];
    if (focusPresets.isEmpty) {
      focusPresets.addAll(const [
        _QuickStartPreset(label: '25분 포모도로', mode: 'focus', minutes: 25),
        _QuickStartPreset(label: '45분 몰입', mode: 'focus', minutes: 45),
        _QuickStartPreset(label: '90분 플로우', mode: 'focus', minutes: 90),
      ]);
    }

    final banner = _buildSyncBanner(
      context: context,
      syncState: syncState,
      authState: authState,
      l10n: l10n,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          color: Theme.of(context).colorScheme.primary,
          onRefresh: () async {
            ref.invalidate(settingsFutureProvider);
            ref.invalidate(todaySummaryProvider);
            ref.invalidate(latestSleepSoundSummaryProvider);
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _HomeSummaryCard(
                    dateLabel: dateLabel,
                    focusMinutes: focusMinutesToday,
                    focusGoalMinutes: focusGoalMinutes,
                    sleepMinutes: sleepMinutes,
                    lastBackupAt: settings?.lastBackupAt,
                    l10n: l10n,
                  ),
                ),
              ),
              if (banner != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: banner,
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _FocusSection(
                    l10n: l10n,
                    focusMinutes: focusMinutesToday,
                    focusGoalMinutes: focusGoalMinutes,
                    focusProgress: focusProgress,
                    presets: focusPresets,
                    onStartPreset: (preset) {
                      AnalyticsService.logEvent('home_quick_start', {
                        'mode': preset.mode,
                        'minutes': preset.minutes,
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => TimerPage(
                            initialMode: preset.mode,
                            autoStart: true,
                          ),
                        ),
                      );
                    },
                    onViewStats: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const StatsPage(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _SleepSection(
                    l10n: l10n,
                    sleepMinutes: sleepMinutes,
                    sleepSummary: sleepSummary,
                    onStartSleepMode: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              TimerPage(initialMode: 'sleep', autoStart: true),
                        ),
                      );
                    },
                    onOpenBackup: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const BackupPage(),
                        ),
                      );
                    },
                    onSyncWearable: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('웨어러블 연동 기능이 준비 중입니다.')),
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _JournalSection(
                    l10n: l10n,
                    onOpenJournal: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const JournalPage(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (!isPremium)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: _PremiumUpsellHint(l10n: l10n),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: _CommunityBanner(
                    l10n: l10n,
                    onJoinChallenge: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('커뮤니티 기능이 곧 제공될 예정입니다.')),
                      );
                    },
                    onInviteFriend: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('친구 초대 기능이 준비 중입니다.')),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusSection extends StatelessWidget {
  const _FocusSection({
    required this.l10n,
    required this.focusMinutes,
    required this.focusGoalMinutes,
    required this.focusProgress,
    required this.presets,
    required this.onStartPreset,
    required this.onViewStats,
  });

  final AppLocalizations l10n;
  final int focusMinutes;
  final int focusGoalMinutes;
  final double focusProgress;
  final List<_QuickStartPreset> presets;
  final ValueChanged<_QuickStartPreset> onStartPreset;
  final VoidCallback onViewStats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressPercent = (focusProgress * 100).clamp(0, 100).toInt();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '집중 현황',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onViewStats,
                  child: const Text('상세 보기'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '오늘 ${_formatMinutesLabel(focusMinutes)} 집중했습니다.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: focusProgress.clamp(0, 1),
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '목표의 $progressPercent% 달성',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: presets.map((preset) {
                return FilledButton.tonal(
                  onPressed: () => onStartPreset(preset),
                  child: Text(preset.label),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepSection extends StatelessWidget {
  const _SleepSection({
    required this.l10n,
    required this.sleepMinutes,
    required this.sleepSummary,
    required this.onStartSleepMode,
    required this.onOpenBackup,
    required this.onSyncWearable,
  });

  final AppLocalizations l10n;
  final int sleepMinutes;
  final SleepSoundSummary? sleepSummary;
  final VoidCallback onStartSleepMode;
  final VoidCallback onOpenBackup;
  final VoidCallback onSyncWearable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final restfulRatio = sleepSummary?.restfulSampleRatio;
    final loudEvents = sleepSummary?.loudEventCount;
    final noiseEvents = sleepSummary?.noiseEvents ?? const <SleepNoiseEvent>[];
    final restfulLabel = restfulRatio != null
        ? '${(restfulRatio * 100).clamp(0, 100).toStringAsFixed(1)}% 조용한 구간'
        : '수면 사운드 분석 데이터를 수집해보세요.';
    final loudLabel = loudEvents != null
        ? '소음 이벤트 $loudEvents회 추정'
        : '코골이/소음 이벤트를 분석하려면 수면 모드를 실행하세요.';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '수면 요약',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '어제 ${_formatMinutesLabel(sleepMinutes)} 잠들었어요.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4D9EFF).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restfulLabel,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loudLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: onStartSleepMode,
                  child: const Text('수면 모드 시작'),
                ),
                FilledButton.tonal(
                  onPressed: onOpenBackup,
                  child: const Text('수면 기록 백업'),
                ),
                OutlinedButton(
                  onPressed: onSyncWearable,
                  child: const Text('웨어러블 연동'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SleepNoiseTimeline(events: noiseEvents),
          ],
        ),
      ),
    );
  }
}

class _SleepNoiseTimeline extends StatelessWidget {
  const _SleepNoiseTimeline({required this.events});

  final List<SleepNoiseEvent> events;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (events.isEmpty) {
      return Text(
        '코골이/소음 이벤트가 감지되지 않았어요.',
        style: theme.textTheme.bodySmall,
      );
    }

    final limited = events.length > 3 ? events.take(3).toList() : events;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '소음 이벤트 타임라인',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...limited.map((event) => _NoiseEventTile(event: event)),
        if (events.length > limited.length)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '그 외 ${events.length - limited.length}개의 이벤트',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
          ),
      ],
    );
  }
}

class _NoiseEventTile extends StatelessWidget {
  const _NoiseEventTile({required this.event});

  final SleepNoiseEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final offsetLabel = _formatDuration(event.offset);
    final durationLabel = _formatDuration(event.duration);
    final peakPercent = (event.peakAmplitude * 100).clamp(0, 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.volume_up_rounded, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$offsetLabel 이후 · $durationLabel 지속 · 피크 $peakPercent%',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDuration(Duration duration) {
    if (duration.inHours >= 1) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
      return '$hours시간 $minutes분';
    }
    if (duration.inMinutes >= 1) {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$minutes분 $seconds초';
    }
    if (duration.inSeconds >= 1) {
      return '${duration.inSeconds}초';
    }
    return '${duration.inMilliseconds}ms';
  }
}

class _JournalSection extends StatelessWidget {
  const _JournalSection({
    required this.l10n,
    required this.onOpenJournal,
  });

  final AppLocalizations l10n;
  final VoidCallback onOpenJournal;

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
              '저널 & 루틴 메모',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '감정과 메모를 남기면 집중·수면 리포트가 더 똑똑해집니다.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onOpenJournal,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('저널 쓰기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumUpsellHint extends StatelessWidget {
  const _PremiumUpsellHint({required this.l10n});

  final AppLocalizations l10n;

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
              '프리미엄으로 확장하기',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '맞춤 사운드, 무제한 백업, 장기 통계를 이용해 보세요.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const PaywallPage(),
                  ),
                );
              },
              child: const Text('프리미엄 알아보기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityBanner extends StatelessWidget {
  const _CommunityBanner({
    required this.l10n,
    required this.onJoinChallenge,
    required this.onInviteFriend,
  });

  final AppLocalizations l10n;
  final VoidCallback onJoinChallenge;
  final VoidCallback onInviteFriend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB48CF8), Color(0xFF6F6CF3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '오늘의 챌린지',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '“오늘 1시간 집중을 완료하면 포인트 +1 🎯”',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6F6CF3),
                ),
                onPressed: onJoinChallenge,
                child: const Text('챌린지 참여'),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
                onPressed: onInviteFriend,
                child: const Text('친구 초대'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Legacy home widgets removed during dashboard refactor.
