import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:life_app/core/firebase/firebase_initializer.dart';
import 'package:life_app/design/app_theme.dart';
import 'package:life_app/features/home/home_dashboard.dart';
import 'package:life_app/features/more/more_page.dart';
import 'package:life_app/features/account/account_page.dart';
import 'package:life_app/features/onboarding/onboarding_page.dart';
import 'package:life_app/models/settings.dart';
import 'package:life_app/providers/settings_providers.dart';
import 'package:life_app/providers/backup_providers.dart';
import 'package:life_app/services/analytics/analytics_service.dart';
import 'package:life_app/services/notification_service.dart';
import 'package:life_app/services/background/workmanager_scheduler.dart';
import 'package:life_app/services/subscription/revenuecat_service.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/widgets/ios_tab_bar.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
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

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key});

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  bool _isPresentingOnboarding = false;
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
      final needsOnboarding = !settings.hasCompletedOnboarding;
      if (!needsOnboarding) {
        _isPresentingOnboarding = false;
        return;
      }
      if (!_isPresentingOnboarding) {
        _isPresentingOnboarding = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final completed = await Navigator.push<bool>(
            context,
            MaterialPageRoute<bool>(builder: (_) => const OnboardingPage()),
          );
          if (!mounted) return;
          if (completed != true) {
            setState(() {
              _isPresentingOnboarding = false;
            });
          }
        });
      }
    });
    final l10n = context.l10n;
    final tabs = const [HomeDashboardTab(), MorePage(), AccountPage()];

    // iOS-style tab bar items with Life Buddy colors
    final tabItems = [
      IOSTabItem(
        icon: Icons.home_outlined,
        label: l10n.tr('tab_home'),
        color: AppTheme.teal,
      ),
      IOSTabItem(
        icon: Icons.grid_view_rounded,
        label: l10n.tr('tab_more'),
        color: AppTheme.eucalyptus,
      ),
      IOSTabItem(
        icon: Icons.person_outline,
        label: l10n.tr('tab_profile'),
        color: AppTheme.coral,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: IOSTabBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (_currentIndex == index) return;
          setState(() => _currentIndex = index);
        },
        items: tabItems,
      ),
    );
  }
}

// Legacy home widgets removed during dashboard refactor
