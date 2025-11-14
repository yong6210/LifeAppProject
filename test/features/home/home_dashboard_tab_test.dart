import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:life_app/features/home/home_dashboard.dart';
import 'package:life_app/l10n/app_localizations.dart';
import 'package:life_app/models/settings.dart';
import 'package:life_app/providers/auth_providers.dart';
import 'package:life_app/providers/session_providers.dart';
import 'package:life_app/providers/settings_providers.dart';
import 'package:life_app/providers/stats_providers.dart';
import 'package:life_app/providers/sync_providers.dart';
import 'package:life_app/widgets/modern_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeDashboardTab', () {
    testWidgets('shows loading skeleton while settings are loading', (
      tester,
    ) async {
      final pendingSettings = Completer<Settings>();

      await _pumpDashboard(
        tester,
        settingsFuture: pendingSettings.future,
      );

      expect(find.text("Today's progress"), findsNothing);
      expect(find.byType(ModernSkeleton), findsWidgets);
    });

    testWidgets('shows retry banner when today summary fails', (tester) async {
      await _pumpDashboard(
        tester,
        todaySummaryStream: Stream<TodaySummary>.error('failed'),
      );

      expect(find.text("Can't load dashboard"), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders progress and premium sections when data is ready', (
      tester,
    ) async {
      await _pumpDashboard(tester);

      expect(find.text("Today's progress"), findsWidgets);
      expect(find.text('Quick start'), findsOneWidget);
      expect(find.text('Go premium'), findsOneWidget);
      expect(find.text('Integrations'), findsOneWidget);
    });
  });
}

Future<void> _pumpDashboard(
  WidgetTester tester, {
  Future<Settings>? settingsFuture,
  Stream<TodaySummary>? todaySummaryStream,
  Future<int>? streakFuture,
}) async {
  final l10n = AppLocalizations.testing(translations: _testTranslations);
  final settings = Settings()
    ..focusMinutes = 30
    ..restMinutes = 5
    ..workoutMinutes = 20
    ..sleepMinutes = 60;
  final summaryStream = todaySummaryStream ??
      Stream<TodaySummary>.value(
        const TodaySummary(focus: 30, workout: 20, sleep: 420),
      );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsFutureProvider.overrideWith(
          (ref) async => settingsFuture ?? Future.value(settings),
        ),
        todaySummaryProvider.overrideWith((ref) => summaryStream),
        streakCountProvider.overrideWith(
          (ref) async => streakFuture == null ? 3 : await streakFuture,
        ),
        authControllerProvider.overrideWith(() => _FakeAuthController()),
        syncControllerProvider.overrideWith(() => _FakeSyncController()),
      ],
      child: MaterialApp(
        localizationsDelegates: [
          _TestLocalizationsDelegate(l10n),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: const HomeDashboardTab(),
      ),
    ),
  );

  await tester.pump();
}

class _FakeAuthController extends AuthController {
  @override
  Future<User?> build() async => null;
}

class _FakeSyncController extends SyncController {
  @override
  Future<void> build() async {
    state = const AsyncData(null);
  }
}

class _TestLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _TestLocalizationsDelegate(this._l10n);

  final AppLocalizations _l10n;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(_l10n);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

const Map<String, String> _testTranslations = <String, String>{
  'app_title': 'Life App',
  'home_dashboard_greeting_morning': 'Good morning',
  'home_dashboard_greeting_afternoon': 'Good afternoon',
  'home_dashboard_greeting_evening': 'Good evening',
  'home_dashboard_greeting_subtitle': "Let's build better habits today",
  'home_dashboard_quick_start_title': 'Quick start',
  'timer_mode_focus': 'Focus',
  'timer_mode_workout': 'Workout',
  'timer_mode_sleep': 'Sleep',
  'home_dashboard_card_focus_description': 'Focus description',
  'home_dashboard_card_workout_description': 'Workout description',
  'home_dashboard_card_sleep_description': 'Sleep description',
  'home_dashboard_action_start': 'Start now',
  'home_dashboard_action_customize': 'Adjust routine',
  'home_dashboard_action_explore': 'Explore',
  'home_dashboard_progress_title': "Today's progress",
  'home_dashboard_routines_title': 'Your routines',
  'home_dashboard_integrations_title': 'Integrations',
  'home_dashboard_integrations_wearables_title': 'Wearables',
  'home_dashboard_integrations_wearables_subtitle': 'Connect devices',
  'home_dashboard_integrations_backup_title': 'Backup',
  'home_dashboard_integrations_backup_subtitle': 'Automatic sync enabled',
  'home_dashboard_premium_title': 'Go premium',
  'home_dashboard_premium_subtitle': 'Unlock advanced features',
  'home_dashboard_premium_cta': 'Start trial',
  'home_dashboard_state_error_title': "Can't load dashboard",
  'home_dashboard_state_error_message':
      'Check your connection and try again.',
  'home_dashboard_state_retry': 'Retry',
  'home_dashboard_routine_stat_today': 'Today {value}',
  'home_dashboard_routine_stat_streak': '{days}-day streak',
  'home_sync_error': 'Sync error',
  'home_sync_signed_out': 'Signed out',
  'home_sync_in_progress': 'Syncing',
  'duration_minutes_only': '{minutes} min',
};
