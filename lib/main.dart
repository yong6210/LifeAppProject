import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:life_app/core/firebase/firebase_initializer.dart';
import 'package:life_app/design/app_theme.dart';
import 'package:life_app/features/home/casual_home_dashboard.dart';
import 'package:life_app/features/journal/journal_page.dart';
import 'package:life_app/features/schedule/schedule_page.dart';
import 'package:life_app/features/account/account_page.dart';
import 'package:life_app/features/onboarding/onboarding_page.dart';
import 'package:life_app/features/timer/focus_session_page.dart';
import 'package:life_app/models/settings.dart';
import 'package:life_app/providers/session_providers.dart';
import 'package:life_app/providers/settings_providers.dart';
import 'package:life_app/providers/backup_providers.dart';
import 'package:life_app/services/analytics/analytics_service.dart';
import 'package:life_app/services/analytics/growth_kpi_events.dart';
import 'package:life_app/services/notification_service.dart';
import 'package:life_app/services/background/workmanager_scheduler.dart';
import 'package:life_app/services/subscription/revenuecat_service.dart';
import 'package:life_app/services/widget/widget_update_service.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/widgets/ios_tab_bar.dart';

Future<void> main() async {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      runApp(const ProviderScope(child: MyApp()));
      unawaited(_bootstrapServices());
    },
    (error, stack) {
      unawaited(
        AnalyticsService.recordError(
          error,
          stack,
          fatal: true,
          reason: 'uncaught_zone',
        ),
      );
    },
  );
}

Future<void> _bootstrapServices() async {
  try {
    await FirebaseInitializer.ensureInitialized();
  } catch (_) {
    // Continue boot; Firebase operations will throw descriptive errors later.
  }
  await AnalyticsService.init();
  unawaited(GrowthKpiEvents.applyDashboardContext());
  await NotificationService.init();
  await TimerWorkmanagerGuard.initialize();
  await WidgetUpdateService.init();
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Locale? locale = ref.watch(appLocaleControllerProvider);

    ref.listen<AsyncValue<TodaySummary>>(todaySummaryProvider,
        (previous, next) {
      next.whenData((summary) {
        WidgetUpdateService.updateWidget(summary);
      });
    });

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          onGenerateTitle: (context) => context.l10n.tr('app_title'),
          localizationsDelegates: const [
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

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key});

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  bool _isPresentingOnboarding = false;
  bool _hasPromptedOnboardingThisLaunch = false;
  ProviderSubscription<AsyncValue<Settings>>? _settingsSubscription;
  int _currentIndex = 0;
  final Map<int, Widget> _tabCache = {};

  @override
  void initState() {
    super.initState();
    _settingsSubscription = ref.listenManual<AsyncValue<Settings>>(
      settingsFutureProvider,
      (previous, next) {
        next.whenData((settings) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            await _maybeShowBackupReminder(settings);
            await _maybePresentOnboarding(settings);
          });
        });
      },
      fireImmediately: true,
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

    final l10n = context.l10n;

    // Stitch v2 tab IA: Home / Tasks / Focus / Record / My
    final tabItems = [
      IOSTabItem(
        icon: Icons.home_outlined,
        label: l10n.tr('tab_home'),
        color: AppTheme.teal,
      ),
      IOSTabItem(
        icon: Icons.checklist_rounded,
        label: l10n.tr('tab_tasks'),
        color: AppTheme.teal,
      ),
      IOSTabItem(
        icon: Icons.timer_outlined,
        label: l10n.tr('tab_focus'),
        color: AppTheme.teal,
      ),
      IOSTabItem(
        icon: Icons.edit_note_rounded,
        label: l10n.tr('tab_record'),
        color: AppTheme.teal,
      ),
      IOSTabItem(
        icon: Icons.person_outline,
        label: l10n.tr('tab_my'),
        color: AppTheme.teal,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List<Widget>.generate(5, (index) {
          if (index == _currentIndex || _tabCache.containsKey(index)) {
            return _tabFor(index);
          }
          return const SizedBox.shrink();
        }),
      ),
      bottomNavigationBar: IOSTabBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (_currentIndex == index) return;
          final from = _currentIndex;
          unawaited(
            AnalyticsService.logEvent('app_tab_switch', {
              'from': from,
              'to': index,
            }),
          );
          setState(() {
            _currentIndex = index;
            _tabFor(index);
          });
        },
        items: tabItems,
      ),
    );
  }

  Widget _tabFor(int index) {
    return _tabCache.putIfAbsent(
      index,
      () => KeyedSubtree(
        key: PageStorageKey<String>('app-shell-tab-$index'),
        child: _buildTab(index),
      ),
    );
  }

  Widget _buildTab(int index) {
    switch (index) {
      case 0:
        return const CasualHomeDashboard();
      case 1:
        return const SchedulePage();
      case 2:
        return const FocusSessionPage();
      case 3:
        return const JournalPage();
      case 4:
        return const AccountPage();
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _maybeShowBackupReminder(Settings settings) async {
    final reminderService =
        await ref.read(backupReminderServiceProvider.future);
    final shouldNotify = await reminderService.shouldNotify(settings);
    if (!shouldNotify || !mounted) {
      return;
    }

    final l10n = context.l10n;
    final lastBackup = settings.lastBackupAt;
    final now = DateTime.now().toUtc();
    final daysSince =
        lastBackup == null ? null : now.difference(lastBackup.toUtc()).inDays;
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

  Future<void> _maybePresentOnboarding(Settings settings) async {
    if (settings.hasCompletedOnboarding) {
      _isPresentingOnboarding = false;
      return;
    }

    if (_isPresentingOnboarding ||
        _hasPromptedOnboardingThisLaunch ||
        !mounted) {
      return;
    }

    _isPresentingOnboarding = true;
    _hasPromptedOnboardingThisLaunch = true;
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => const OnboardingPage()),
    );
    if (!mounted) {
      return;
    }
    _isPresentingOnboarding = false;
    if (completed == true) {
      await AnalyticsService.logEvent('onboarding_gate_completed', {
        'source': 'launch',
      });
      return;
    }

    await AnalyticsService.logEvent('onboarding_gate_dismissed', {
      'source': 'launch',
    });
  }
}

// Legacy home widgets removed during dashboard refactor
