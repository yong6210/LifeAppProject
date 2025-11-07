import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:life_app/models/settings.dart';

class SettingsRemoteDto {
  SettingsRemoteDto({
    required this.theme,
    required this.locale,
    required this.soundIds,
    required this.presets,
    required this.notificationPrefs,
    required this.lastBackupAt,
    required this.focusMinutes,
    required this.restMinutes,
    required this.workoutMinutes,
    required this.sleepMinutes,
    required this.sleepSmartAlarmWindowMinutes,
    required this.sleepSmartAlarmIntervalMinutes,
    required this.sleepSmartAlarmExactFallback,
    required this.sleepMixerWhiteLevel,
    required this.sleepMixerPinkLevel,
    required this.sleepMixerBrownLevel,
    required this.sleepMixerPresetId,
    required this.lastMode,
    required this.routinePersonalizationEnabled,
    required this.routinePersonalizationSyncEnabled,
    required this.lifeBuddyTone,
    required this.schemaVersion,
    required this.updatedAt,
  });

  factory SettingsRemoteDto.fromSettings(Settings settings) {
    return SettingsRemoteDto(
      theme: settings.theme,
      locale: settings.locale,
      soundIds: settings.soundIds,
      presets: settings.presets
          .map(
            (preset) => {
              'id': preset.id,
              'name': preset.name,
              'mode': preset.mode,
              'durationMinutes': preset.durationMinutes,
              'autoPlaySound': preset.autoPlaySound,
              if (preset.soundId != null) 'soundId': preset.soundId,
            },
          )
          .toList(),
      notificationPrefs: {
        'focusComplete': settings.notificationPrefs.focusComplete,
        'restComplete': settings.notificationPrefs.restComplete,
        'workoutComplete': settings.notificationPrefs.workoutComplete,
        'sleepAlarm': settings.notificationPrefs.sleepAlarm,
      },
      lastBackupAt: settings.lastBackupAt,
      focusMinutes: settings.focusMinutes,
      restMinutes: settings.restMinutes,
      workoutMinutes: settings.workoutMinutes,
      sleepMinutes: settings.sleepMinutes,
      sleepSmartAlarmWindowMinutes: settings.sleepSmartAlarmWindowMinutes,
      sleepSmartAlarmIntervalMinutes: settings.sleepSmartAlarmIntervalMinutes,
      sleepSmartAlarmExactFallback: settings.sleepSmartAlarmExactFallback,
      sleepMixerWhiteLevel: settings.sleepMixerWhiteLevel,
      sleepMixerPinkLevel: settings.sleepMixerPinkLevel,
      sleepMixerBrownLevel: settings.sleepMixerBrownLevel,
      sleepMixerPresetId: settings.sleepMixerPresetId,
      lastMode: settings.lastMode,
      routinePersonalizationEnabled: settings.routinePersonalizationEnabled,
      routinePersonalizationSyncEnabled:
          settings.routinePersonalizationSyncEnabled,
      lifeBuddyTone: settings.lifeBuddyTone,
      schemaVersion: settings.schemaVersion,
      updatedAt: settings.updatedAt,
    );
  }

  factory SettingsRemoteDto.fromMap(
    Map<String, dynamic> data,
    Settings fallback,
  ) {
    return SettingsRemoteDto(
      theme: data['theme'] as String? ?? fallback.theme,
      locale: data['locale'] as String? ?? fallback.locale,
      soundIds: List<String>.from(data['soundIds'] as List<dynamic>? ?? []),
      presets: (data['presets'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(
            (preset) =>
                preset.map((key, value) => MapEntry(key, value as Object?)),
          )
          .toList(),
      notificationPrefs: Map<String, Object?>.from(
        data['notificationPrefs'] as Map? ?? {},
      ),
      lastBackupAt: (data['lastBackupAt'] as firestore.Timestamp?)?.toDate(),
      focusMinutes:
          (data['focusMinutes'] as num?)?.toInt() ?? fallback.focusMinutes,
      restMinutes:
          (data['restMinutes'] as num?)?.toInt() ?? fallback.restMinutes,
      workoutMinutes:
          (data['workoutMinutes'] as num?)?.toInt() ?? fallback.workoutMinutes,
      sleepMinutes:
          (data['sleepMinutes'] as num?)?.toInt() ?? fallback.sleepMinutes,
      sleepSmartAlarmWindowMinutes:
          (data['sleepSmartAlarmWindowMinutes'] as num?)?.toInt() ??
          fallback.sleepSmartAlarmWindowMinutes,
      sleepSmartAlarmIntervalMinutes:
          (data['sleepSmartAlarmIntervalMinutes'] as num?)?.toInt() ??
          fallback.sleepSmartAlarmIntervalMinutes,
      sleepSmartAlarmExactFallback:
          data['sleepSmartAlarmExactFallback'] as bool? ??
          fallback.sleepSmartAlarmExactFallback,
      sleepMixerWhiteLevel:
          (data['sleepMixerWhiteLevel'] as num?)?.toDouble() ??
          fallback.sleepMixerWhiteLevel,
      sleepMixerPinkLevel:
          (data['sleepMixerPinkLevel'] as num?)?.toDouble() ??
          fallback.sleepMixerPinkLevel,
      sleepMixerBrownLevel:
          (data['sleepMixerBrownLevel'] as num?)?.toDouble() ??
          fallback.sleepMixerBrownLevel,
      sleepMixerPresetId:
          data['sleepMixerPresetId'] as String? ?? fallback.sleepMixerPresetId,
      lastMode: data['lastMode'] as String? ?? fallback.lastMode,
      routinePersonalizationEnabled:
          data['routinePersonalizationEnabled'] as bool? ??
          fallback.routinePersonalizationEnabled,
      routinePersonalizationSyncEnabled:
          data['routinePersonalizationSyncEnabled'] as bool? ??
          fallback.routinePersonalizationSyncEnabled,
      lifeBuddyTone: data['lifeBuddyTone'] as String? ?? fallback.lifeBuddyTone,
      schemaVersion: (data['schemaVersion'] as num?)?.toInt() ?? 1,
      updatedAt:
          (data['updatedAt'] as firestore.Timestamp?)?.toDate() ??
          fallback.updatedAt,
    );
  }

  final String theme;
  final String locale;
  final List<String> soundIds;
  final List<Map<String, Object?>> presets;
  final Map<String, Object?> notificationPrefs;
  final DateTime? lastBackupAt;
  final int focusMinutes;
  final int restMinutes;
  final int workoutMinutes;
  final int sleepMinutes;
  final int sleepSmartAlarmWindowMinutes;
  final int sleepSmartAlarmIntervalMinutes;
  final bool sleepSmartAlarmExactFallback;
  final double sleepMixerWhiteLevel;
  final double sleepMixerPinkLevel;
  final double sleepMixerBrownLevel;
  final String sleepMixerPresetId;
  final String lastMode;
  final bool routinePersonalizationEnabled;
  final bool routinePersonalizationSyncEnabled;
  final String lifeBuddyTone;
  final int schemaVersion;
  final DateTime updatedAt;

  Map<String, Object?> toJson() {
    return {
      'theme': theme,
      'locale': locale,
      'soundIds': soundIds,
      'presets': presets,
      'notificationPrefs': notificationPrefs,
      'lastBackupAt': lastBackupAt,
      'focusMinutes': focusMinutes,
      'restMinutes': restMinutes,
      'workoutMinutes': workoutMinutes,
      'sleepMinutes': sleepMinutes,
      'sleepSmartAlarmWindowMinutes': sleepSmartAlarmWindowMinutes,
      'sleepSmartAlarmIntervalMinutes': sleepSmartAlarmIntervalMinutes,
      'sleepSmartAlarmExactFallback': sleepSmartAlarmExactFallback,
      'sleepMixerWhiteLevel': sleepMixerWhiteLevel,
      'sleepMixerPinkLevel': sleepMixerPinkLevel,
      'sleepMixerBrownLevel': sleepMixerBrownLevel,
      'sleepMixerPresetId': sleepMixerPresetId,
      'lastMode': lastMode,
      'routinePersonalizationEnabled': routinePersonalizationEnabled,
      'routinePersonalizationSyncEnabled': routinePersonalizationSyncEnabled,
      'lifeBuddyTone': lifeBuddyTone,
      'schemaVersion': schemaVersion,
      'updatedAt': firestore.FieldValue.serverTimestamp(),
    };
  }

  Settings applyTo(Settings settings) {
    settings
      ..theme = theme
      ..locale = locale
      ..soundIds = List<String>.from(soundIds)
      ..presets = presets.map((preset) {
        final p = Preset()
          ..id = preset['id']! as String
          ..name = preset['name']! as String
          ..mode = preset['mode']! as String
          ..durationMinutes = preset['durationMinutes']! as int
          ..autoPlaySound = preset['autoPlaySound']! as bool
          ..soundId = preset['soundId'] as String?;
        return p;
      }).toList()
      ..notificationPrefs = (NotificationPrefs()
        ..focusComplete = notificationPrefs['focusComplete'] as bool? ?? true
        ..restComplete = notificationPrefs['restComplete'] as bool? ?? true
        ..workoutComplete =
            notificationPrefs['workoutComplete'] as bool? ?? true
        ..sleepAlarm = notificationPrefs['sleepAlarm'] as bool? ?? true)
      ..lastBackupAt = lastBackupAt
      ..focusMinutes = focusMinutes
      ..restMinutes = restMinutes
      ..workoutMinutes = workoutMinutes
      ..sleepMinutes = sleepMinutes
      ..sleepSmartAlarmWindowMinutes = sleepSmartAlarmWindowMinutes
      ..sleepSmartAlarmIntervalMinutes = sleepSmartAlarmIntervalMinutes
      ..sleepSmartAlarmExactFallback = sleepSmartAlarmExactFallback
      ..sleepMixerWhiteLevel = sleepMixerWhiteLevel
      ..sleepMixerPinkLevel = sleepMixerPinkLevel
      ..sleepMixerBrownLevel = sleepMixerBrownLevel
      ..sleepMixerPresetId = sleepMixerPresetId
      ..lastMode = lastMode
      ..routinePersonalizationEnabled = routinePersonalizationEnabled
      ..routinePersonalizationSyncEnabled = routinePersonalizationSyncEnabled
      ..lifeBuddyTone = lifeBuddyTone
      ..schemaVersion = schemaVersion
      ..updatedAt = updatedAt;
    return settings;
  }
}
