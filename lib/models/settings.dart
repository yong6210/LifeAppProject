import 'package:isar/isar.dart';

part 'settings.g.dart';

@collection
class Settings {
  Id id = 0;

  String theme = 'system';

  String locale = 'system';

  String deviceId = '';

  List<String> soundIds = [];

  List<Preset> presets = [];

  NotificationPrefs notificationPrefs = NotificationPrefs();

  DateTime? lastBackupAt;

  int focusMinutes = 25;

  int restMinutes = 5;

  int workoutMinutes = 20;

  int sleepMinutes = 30;

  /// Smart alarm window length in minutes (0 = disabled smart window).
  int sleepSmartAlarmWindowMinutes = 10;

  /// Interval between gentle wake prompts inside the smart window.
  int sleepSmartAlarmIntervalMinutes = 2;

  /// Whether to schedule a final exact alarm at the target wake time.
  bool sleepSmartAlarmExactFallback = true;

  /// Sleep mixer levels for custom white/pink/brown noise (0.0 - 1.0 range).
  double sleepMixerWhiteLevel = 0.4;

  double sleepMixerPinkLevel = 0.2;

  double sleepMixerBrownLevel = 0.0;

  /// Selected ambience preset for sleep mode soundscape.
  ///
  /// `custom_mix` preserves manual slider values above.
  String sleepMixerPresetId = 'custom_mix';

  String backupPreferredProvider = '자동';

  List<BackupLogEntry> backupHistory = [];

  bool hasCompletedOnboarding = false;

  bool lastKnownPremium = false;

  String lastMode = 'focus';

  bool routinePersonalizationEnabled = true;

  bool routinePersonalizationSyncEnabled = false;

  String lifeBuddyTone = 'friend';

  int schemaVersion = 2;

  DateTime createdAt = DateTime.now().toUtc();

  DateTime updatedAt = DateTime.now().toUtc();
}

@embedded
class Preset {
  late String id;
  late String name;

  /// 'focus' | 'rest' | 'workout' | 'sleep'
  String mode = 'focus';

  int durationMinutes = 25;

  bool autoPlaySound = false;

  String? soundId;
}

@embedded
class NotificationPrefs {
  bool focusComplete = true;
  bool restComplete = true;
  bool workoutComplete = true;
  bool sleepAlarm = true;
}

@embedded
class BackupLogEntry {
  late DateTime timestamp;
  String action = 'backup';
  String status = 'success';
  String provider = '자동';
  int bytes = 0;
  String? errorMessage;
}
