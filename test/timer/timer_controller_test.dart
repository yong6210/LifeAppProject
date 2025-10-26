import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/features/timer/timer_controller.dart';
import 'package:life_app/features/timer/timer_dependencies.dart';
import 'package:life_app/models/session.dart';
import 'package:life_app/models/settings.dart';
import 'package:life_app/providers/session_providers.dart';
import 'package:life_app/providers/settings_providers.dart';
import 'package:life_app/services/audio/sleep_sound_catalog.dart';
import 'package:life_app/services/audio/timer_audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeTimerAudio implements TimerAudioEngine {
  bool initCalled = false;
  bool enabled = false;
  String? lastProfile;
  double white = 0;
  double pink = 0;
  double brown = 0;
  String presetId = 'custom_mix';
  bool disposed = false;
  int configureCalls = 0;

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  @override
  Future<void> init() async {
    initCalled = true;
  }

  @override
  Future<void> setEnabled(bool value, {String? profile}) async {
    enabled = value;
    lastProfile = profile;
  }

  @override
  Future<void> configureSleepAmbience({
    required double white,
    required double pink,
    required double brown,
    required String presetId,
  }) async {
    configureCalls++;
    this.white = white;
    this.pink = pink;
    this.brown = brown;
    this.presetId = presetId;
  }

  @override
  Future<void> updateProfile(String? profile) async {
    lastProfile = profile;
  }
}

class FakeNotificationBridge implements TimerNotificationBridge {
  bool showDoneCalled = false;
  final List<Map<String, Object?>> timerEndCalls = [];
  final List<Map<String, Object?>> smartWindowCalls = [];
  int cancelRangeCount = 0;
  int cancelTimersCount = 0;

  @override
  Future<void> cancelNotificationRange(int baseId, int count) async {
    cancelRangeCount++;
  }

  @override
  Future<void> cancelTimerNotifications() async {
    cancelTimersCount++;
  }

  @override
  Future<void> scheduleSmartSleepAlarmWindow({
    required int baseId,
    required String label,
    required DateTime windowStart,
    required DateTime targetTime,
    required Duration interval,
    bool includeFallbackExact = true,
  }) async {
    smartWindowCalls.add({
      'baseId': baseId,
      'label': label,
      'windowStart': windowStart,
      'targetTime': targetTime,
      'interval': interval,
      'fallback': includeFallbackExact,
    });
  }

  @override
  Future<void> scheduleTimerEnd({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    timerEndCalls.add({
      'id': id,
      'title': title,
      'body': body,
      'scheduledAt': scheduledAt,
    });
  }

  @override
  Future<void> showDone({required String mode}) async {
    showDoneCalled = true;
  }
}

class FakeForegroundBridge implements TimerForegroundBridge {
  static int ensureCalls = 0;
  bool initialized = false;
  final List<Map<String, Object?>> startCalls = [];
  final List<Map<String, Object?>> updateCalls = [];
  final List<Map<String, Object?>> sleepSoundCalls = [];
  int stopCount = 0;

  @override
  Future<void> ensureInitialized() async {
    ensureCalls++;
    initialized = true;
  }

  @override
  Future<void> start({
    required String title,
    required String text,
    required String mode,
    required String segmentLabel,
    required DateTime segmentEndAt,
    DateTime? smartWindowStart,
    Duration? smartInterval,
  }) async {
    startCalls.add({
      'title': title,
      'text': text,
      'mode': mode,
      'segment': segmentLabel,
      'endAt': segmentEndAt,
      'smartStart': smartWindowStart,
      'smartInterval': smartInterval,
    });
  }

  @override
  Future<void> setSleepSoundActive({
    required bool active,
    DateTime? startedAt,
  }) async {
    sleepSoundCalls.add({
      'active': active,
      'startedAt': startedAt,
    });
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  Future<void> update({
    required String title,
    required String text,
    required String mode,
    required String segmentLabel,
    required DateTime segmentEndAt,
    DateTime? smartWindowStart,
    Duration? smartInterval,
  }) async {
    updateCalls.add({
      'title': title,
      'text': text,
      'mode': mode,
      'segment': segmentLabel,
      'endAt': segmentEndAt,
      'smartStart': smartWindowStart,
      'smartInterval': smartInterval,
    });
  }
}

class FakeBackgroundBridge implements TimerBackgroundBridge {
  int scheduleCount = 0;
  int cancelCount = 0;

  @override
  Future<void> cancelGuard() async {
    cancelCount++;
  }

  @override
  Future<void> scheduleGuard() async {
    scheduleCount++;
  }
}

Future<void> _pumpEventQueue() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

Future<void> _waitForCondition(
  bool Function() condition, {
  Duration timeout = const Duration(milliseconds: 200),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition() && DateTime.now().isBefore(deadline)) {
    await _pumpEventQueue();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final defaultMessenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    defaultMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall _) async => null,
    );
    FakeForegroundBridge.ensureCalls = 0;
  });

  tearDown(() {
    defaultMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('TimerController', () {
    ProviderContainer createContainer({
      required FakeTimerAudio audio,
      required FakeNotificationBridge notifications,
      required FakeForegroundBridge foreground,
      required FakeBackgroundBridge background,
      required List<Session> recordedSessions,
      Settings? settings,
    }) {
      final deps = TimerDependencies(
        audio: audio,
        notifications: notifications,
        foreground: foreground,
        background: background,
      );
      final baseSettings =
          settings ??
          (Settings()
            ..focusMinutes = 1
            ..restMinutes = 1
            ..workoutMinutes = 1
            ..sleepMinutes = 1
            ..sleepSmartAlarmWindowMinutes = 0
            ..sleepSmartAlarmIntervalMinutes = 5);

      return ProviderContainer(
        overrides: [
          timerDependenciesProvider.overrideWithValue(deps),
          settingsFutureProvider.overrideWith((ref) async => baseSettings),
          addSessionProvider.overrideWith((ref, session) async {
            recordedSessions.add(session);
          }),
        ],
      );
    }

    test(
      'start then pause timer touches audio, notifications, and foreground bridges',
      () async {
        final audio = FakeTimerAudio();
        final notifications = FakeNotificationBridge();
        final foreground = FakeForegroundBridge();
        final sessions = <Session>[];
        final background = FakeBackgroundBridge();
        final container = createContainer(
          audio: audio,
          notifications: notifications,
          foreground: foreground,
          background: background,
          recordedSessions: sessions,
        );

        final controller = container.read(timerControllerProvider.notifier);
        container.read(timerControllerProvider);
        await _waitForCondition(() => audio.initCalled);
        expect(audio.initCalled, isTrue);

        await controller.toggleStartStop();
        await _pumpEventQueue();
        expect(FakeForegroundBridge.ensureCalls, greaterThan(0));
        expect(
          foreground.initialized,
          isTrue,
          reason: 'ensureCalls=${FakeForegroundBridge.ensureCalls}',
        );

        expect(controller.state.isRunning, isTrue);
        expect(audio.enabled, isTrue);
        expect(foreground.startCalls.length, 1);
        expect(notifications.timerEndCalls, isNotEmpty);
        expect(background.scheduleCount, greaterThanOrEqualTo(1));

        await controller.toggleStartStop();
        await _pumpEventQueue();

        expect(controller.state.isRunning, isFalse);
        expect(audio.enabled, isFalse);
        expect(foreground.stopCount, greaterThan(0));
        expect(notifications.cancelRangeCount, 1);
        expect(notifications.cancelTimersCount, 1);
        expect(background.cancelCount, greaterThanOrEqualTo(1));

        container.dispose();
      },
    );

    test('configures sleep ambience from settings on init', () async {
      final audio = FakeTimerAudio();
      final notifications = FakeNotificationBridge();
      final foreground = FakeForegroundBridge();
      final sessions = <Session>[];
      final background = FakeBackgroundBridge();
      final settings = Settings()
        ..focusMinutes = 1
        ..restMinutes = 1
        ..workoutMinutes = 1
        ..sleepMinutes = 1
        ..sleepSmartAlarmWindowMinutes = 15
        ..sleepSmartAlarmIntervalMinutes = 5
        ..sleepMixerWhiteLevel = 0.4
        ..sleepMixerPinkLevel = 0.3
        ..sleepMixerBrownLevel = 0.2
        ..sleepMixerPresetId = 'rain_light';

      final container = createContainer(
        audio: audio,
        notifications: notifications,
        foreground: foreground,
        background: background,
        recordedSessions: sessions,
        settings: settings,
      );

      container.read(timerControllerProvider);
      await _waitForCondition(() => audio.initCalled);
      await _waitForCondition(() => audio.configureCalls > 0);

      expect(audio.white, closeTo(0.4, 0.0001));
      expect(audio.pink, closeTo(0.3, 0.0001));
      expect(audio.brown, closeTo(0.2, 0.0001));
      expect(audio.presetId, 'rain_light');

      container.dispose();
    });

    test('defaults to custom mix when preset id missing (migration)', () async {
      final audio = FakeTimerAudio();
      final notifications = FakeNotificationBridge();
      final foreground = FakeForegroundBridge();
      final sessions = <Session>[];
      final background = FakeBackgroundBridge();
      final settings = Settings()
        ..focusMinutes = 1
        ..restMinutes = 1
        ..workoutMinutes = 1
        ..sleepMinutes = 1
        ..sleepSmartAlarmWindowMinutes = 5
        ..sleepSmartAlarmIntervalMinutes = 2
        ..sleepMixerWhiteLevel = 0.3
        ..sleepMixerPinkLevel = 0.2
        ..sleepMixerBrownLevel = 0.1
        ..sleepMixerPresetId = '';

      final container = createContainer(
        audio: audio,
        notifications: notifications,
        foreground: foreground,
        background: background,
        recordedSessions: sessions,
        settings: settings,
      );

      container.read(timerControllerProvider);
      await _waitForCondition(() => audio.configureCalls > 0);

      expect(audio.presetId, SleepSoundCatalog.defaultPresetId);
      container.dispose();
    });

    test('refreshCurrentPlan keeps configured sleep preset', () async {
      final audio = FakeTimerAudio();
      final notifications = FakeNotificationBridge();
      final foreground = FakeForegroundBridge();
      final sessions = <Session>[];
      final background = FakeBackgroundBridge();
      final settings = Settings()
        ..focusMinutes = 1
        ..restMinutes = 1
        ..workoutMinutes = 1
        ..sleepMinutes = 1
        ..sleepSmartAlarmWindowMinutes = 10
        ..sleepSmartAlarmIntervalMinutes = 5
        ..sleepMixerWhiteLevel = 0.5
        ..sleepMixerPinkLevel = 0.25
        ..sleepMixerBrownLevel = 0.15
        ..sleepMixerPresetId = 'ocean_waves';

      final container = createContainer(
        audio: audio,
        notifications: notifications,
        foreground: foreground,
        background: background,
        recordedSessions: sessions,
        settings: settings,
      );

      final controller = container.read(timerControllerProvider.notifier);
      await _waitForCondition(() => audio.configureCalls > 0);

      final initialConfigureCount = audio.configureCalls;
      audio.white = 0;
      audio.pink = 0;
      audio.brown = 0;
      audio.presetId = 'custom_mix';

      await controller.refreshCurrentPlan();
      await _waitForCondition(
        () => audio.configureCalls > initialConfigureCount,
      );

      expect(audio.white, closeTo(0.5, 0.0001));
      expect(audio.pink, closeTo(0.25, 0.0001));
      expect(audio.brown, closeTo(0.15, 0.0001));
      expect(audio.presetId, 'ocean_waves');

      container.dispose();
    });

    test('reset clears running state and cancels scheduled work', () async {
      final audio = FakeTimerAudio();
      final notifications = FakeNotificationBridge();
      final foreground = FakeForegroundBridge();
      final sessions = <Session>[];
      final background = FakeBackgroundBridge();
      final container = createContainer(
        audio: audio,
        notifications: notifications,
        foreground: foreground,
        background: background,
        recordedSessions: sessions,
      );

      final controller = container.read(timerControllerProvider.notifier);
      container.read(timerControllerProvider);
      await _waitForCondition(() => foreground.initialized);

      await controller.toggleStartStop();
      await _pumpEventQueue();
      await controller.reset();
      await _pumpEventQueue();

      expect(controller.state.isRunning, isFalse);
      expect(controller.state.currentSegmentIndex, 0);
      expect(foreground.stopCount, greaterThanOrEqualTo(1));
      expect(audio.enabled, isFalse);
      expect(notifications.cancelTimersCount, greaterThanOrEqualTo(1));
      expect(background.cancelCount, greaterThanOrEqualTo(1));

      container.dispose();
    });

    test('persists state to shared preferences for restoration', () async {
      final audio = FakeTimerAudio();
      final notifications = FakeNotificationBridge();
      final foreground = FakeForegroundBridge();
      final sessions = <Session>[];
      final background = FakeBackgroundBridge();
      final container = createContainer(
        audio: audio,
        notifications: notifications,
        foreground: foreground,
        background: background,
        recordedSessions: sessions,
      );

      final controller = container.read(timerControllerProvider.notifier);
      await _pumpEventQueue();

      await controller.toggleStartStop();
      await _pumpEventQueue();
      await controller.toggleStartStop();
      await _pumpEventQueue();

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('timer_state_v2');
      expect(stored, isNotNull);

      final savedIndex = controller.state.currentSegmentIndex;
      container.dispose();

      final audio2 = FakeTimerAudio();
      final notifications2 = FakeNotificationBridge();
      final foreground2 = FakeForegroundBridge();
      final sessions2 = <Session>[];
      final background2 = FakeBackgroundBridge();
      final container2 = createContainer(
        audio: audio2,
        notifications: notifications2,
        foreground: foreground2,
        background: background2,
        recordedSessions: sessions2,
      );

      final restoredState = container2.read(timerControllerProvider);
      await _pumpEventQueue();

      expect(restoredState.isRunning, isFalse);
      expect(restoredState.currentSegmentIndex, savedIndex);
      expect(audio2.initCalled, isTrue);

      container2.dispose();
    });
  });
}
