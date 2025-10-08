import 'dart:io';

// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:life_app/main.dart';
import 'package:life_app/providers/auth_providers.dart';
import 'package:life_app/providers/sync_providers.dart';
import 'package:life_app/providers/sleep_analysis_providers.dart';
import 'package:life_app/services/audio/sleep_sound_analyzer.dart';
import 'package:life_app/services/audio/sleep_sound_store.dart';

void main() {
  testWidgets('App boots without throwing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_FakeAuthController.new),
          authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
          syncControllerProvider.overrideWith(_FakeSyncController.new),
          latestSleepSoundSummaryProvider.overrideWith(
            (ref) async => null,
          ),
          saveSleepSoundSummaryProvider.overrideWith(
            (ref, summary) async {},
          ),
          sleepSoundSummaryStoreProvider.overrideWith(
            (ref) => _FakeSleepSoundSummaryStore(),
          ),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(MyHomePage), findsOneWidget);
  });
}

class _FakeAuthController extends AuthController {
  @override
  Future<User?> build() async => null;

  @override
  Future<UserCredential> signInAnonymously() async {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}
}

class _FakeSyncController extends SyncController {
  @override
  Future<void> build() async {
    state = const AsyncData(null);
  }
}

class _FakeSleepSoundSummaryStore extends SleepSoundSummaryStore {
  _FakeSleepSoundSummaryStore() : super(documentsDirBuilder: () async => Directory.systemTemp);

  @override
  Future<SleepSoundSummary?> loadLatest() async => null;

  @override
  Future<void> saveLatest(SleepSoundSummary summary) async {}
}
