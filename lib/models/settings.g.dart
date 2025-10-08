// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSettingsCollection on Isar {
  IsarCollection<Settings> get settings => this.collection();
}

const SettingsSchema = CollectionSchema(
  name: r'Settings',
  id: -8656046621518759136,
  properties: {
    r'backupHistory': PropertySchema(
      id: 0,
      name: r'backupHistory',
      type: IsarType.objectList,

      target: r'BackupLogEntry',
    ),
    r'backupPreferredProvider': PropertySchema(
      id: 1,
      name: r'backupPreferredProvider',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'deviceId': PropertySchema(
      id: 3,
      name: r'deviceId',
      type: IsarType.string,
    ),
    r'focusMinutes': PropertySchema(
      id: 4,
      name: r'focusMinutes',
      type: IsarType.long,
    ),
    r'hasCompletedOnboarding': PropertySchema(
      id: 5,
      name: r'hasCompletedOnboarding',
      type: IsarType.bool,
    ),
    r'lastBackupAt': PropertySchema(
      id: 6,
      name: r'lastBackupAt',
      type: IsarType.dateTime,
    ),
    r'lastKnownPremium': PropertySchema(
      id: 7,
      name: r'lastKnownPremium',
      type: IsarType.bool,
    ),
    r'lastMode': PropertySchema(
      id: 8,
      name: r'lastMode',
      type: IsarType.string,
    ),
    r'locale': PropertySchema(id: 9, name: r'locale', type: IsarType.string),
    r'notificationPrefs': PropertySchema(
      id: 10,
      name: r'notificationPrefs',
      type: IsarType.object,

      target: r'NotificationPrefs',
    ),
    r'presets': PropertySchema(
      id: 11,
      name: r'presets',
      type: IsarType.objectList,

      target: r'Preset',
    ),
    r'restMinutes': PropertySchema(
      id: 12,
      name: r'restMinutes',
      type: IsarType.long,
    ),
    r'schemaVersion': PropertySchema(
      id: 13,
      name: r'schemaVersion',
      type: IsarType.long,
    ),
    r'sleepMinutes': PropertySchema(
      id: 14,
      name: r'sleepMinutes',
      type: IsarType.long,
    ),
    r'sleepMixerBrownLevel': PropertySchema(
      id: 15,
      name: r'sleepMixerBrownLevel',
      type: IsarType.double,
    ),
    r'sleepMixerPinkLevel': PropertySchema(
      id: 16,
      name: r'sleepMixerPinkLevel',
      type: IsarType.double,
    ),
    r'sleepMixerPresetId': PropertySchema(
      id: 17,
      name: r'sleepMixerPresetId',
      type: IsarType.string,
    ),
    r'sleepMixerWhiteLevel': PropertySchema(
      id: 18,
      name: r'sleepMixerWhiteLevel',
      type: IsarType.double,
    ),
    r'sleepSmartAlarmExactFallback': PropertySchema(
      id: 19,
      name: r'sleepSmartAlarmExactFallback',
      type: IsarType.bool,
    ),
    r'sleepSmartAlarmIntervalMinutes': PropertySchema(
      id: 20,
      name: r'sleepSmartAlarmIntervalMinutes',
      type: IsarType.long,
    ),
    r'sleepSmartAlarmWindowMinutes': PropertySchema(
      id: 21,
      name: r'sleepSmartAlarmWindowMinutes',
      type: IsarType.long,
    ),
    r'soundIds': PropertySchema(
      id: 22,
      name: r'soundIds',
      type: IsarType.stringList,
    ),
    r'theme': PropertySchema(id: 23, name: r'theme', type: IsarType.string),
    r'updatedAt': PropertySchema(
      id: 24,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'workoutMinutes': PropertySchema(
      id: 25,
      name: r'workoutMinutes',
      type: IsarType.long,
    ),
  },

  estimateSize: _settingsEstimateSize,
  serialize: _settingsSerialize,
  deserialize: _settingsDeserialize,
  deserializeProp: _settingsDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {
    r'Preset': PresetSchema,
    r'NotificationPrefs': NotificationPrefsSchema,
    r'BackupLogEntry': BackupLogEntrySchema,
  },

  getId: _settingsGetId,
  getLinks: _settingsGetLinks,
  attach: _settingsAttach,
  version: '3.1.0+1',
);

int _settingsEstimateSize(
  Settings object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.backupHistory.length * 3;
  {
    final offsets = allOffsets[BackupLogEntry]!;
    for (var i = 0; i < object.backupHistory.length; i++) {
      final value = object.backupHistory[i];
      bytesCount += BackupLogEntrySchema.estimateSize(
        value,
        offsets,
        allOffsets,
      );
    }
  }
  bytesCount += 3 + object.backupPreferredProvider.length * 3;
  bytesCount += 3 + object.deviceId.length * 3;
  bytesCount += 3 + object.lastMode.length * 3;
  bytesCount += 3 + object.locale.length * 3;
  bytesCount +=
      3 +
      NotificationPrefsSchema.estimateSize(
        object.notificationPrefs,
        allOffsets[NotificationPrefs]!,
        allOffsets,
      );
  bytesCount += 3 + object.presets.length * 3;
  {
    final offsets = allOffsets[Preset]!;
    for (var i = 0; i < object.presets.length; i++) {
      final value = object.presets[i];
      bytesCount += PresetSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  bytesCount += 3 + object.sleepMixerPresetId.length * 3;
  bytesCount += 3 + object.soundIds.length * 3;
  {
    for (var i = 0; i < object.soundIds.length; i++) {
      final value = object.soundIds[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.theme.length * 3;
  return bytesCount;
}

void _settingsSerialize(
  Settings object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObjectList<BackupLogEntry>(
    offsets[0],
    allOffsets,
    BackupLogEntrySchema.serialize,
    object.backupHistory,
  );
  writer.writeString(offsets[1], object.backupPreferredProvider);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeString(offsets[3], object.deviceId);
  writer.writeLong(offsets[4], object.focusMinutes);
  writer.writeBool(offsets[5], object.hasCompletedOnboarding);
  writer.writeDateTime(offsets[6], object.lastBackupAt);
  writer.writeBool(offsets[7], object.lastKnownPremium);
  writer.writeString(offsets[8], object.lastMode);
  writer.writeString(offsets[9], object.locale);
  writer.writeObject<NotificationPrefs>(
    offsets[10],
    allOffsets,
    NotificationPrefsSchema.serialize,
    object.notificationPrefs,
  );
  writer.writeObjectList<Preset>(
    offsets[11],
    allOffsets,
    PresetSchema.serialize,
    object.presets,
  );
  writer.writeLong(offsets[12], object.restMinutes);
  writer.writeLong(offsets[13], object.schemaVersion);
  writer.writeLong(offsets[14], object.sleepMinutes);
  writer.writeDouble(offsets[15], object.sleepMixerBrownLevel);
  writer.writeDouble(offsets[16], object.sleepMixerPinkLevel);
  writer.writeString(offsets[17], object.sleepMixerPresetId);
  writer.writeDouble(offsets[18], object.sleepMixerWhiteLevel);
  writer.writeBool(offsets[19], object.sleepSmartAlarmExactFallback);
  writer.writeLong(offsets[20], object.sleepSmartAlarmIntervalMinutes);
  writer.writeLong(offsets[21], object.sleepSmartAlarmWindowMinutes);
  writer.writeStringList(offsets[22], object.soundIds);
  writer.writeString(offsets[23], object.theme);
  writer.writeDateTime(offsets[24], object.updatedAt);
  writer.writeLong(offsets[25], object.workoutMinutes);
}

Settings _settingsDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Settings();
  object.backupHistory =
      reader.readObjectList<BackupLogEntry>(
        offsets[0],
        BackupLogEntrySchema.deserialize,
        allOffsets,
        BackupLogEntry(),
      ) ??
      [];
  object.backupPreferredProvider = reader.readString(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.deviceId = reader.readString(offsets[3]);
  object.focusMinutes = reader.readLong(offsets[4]);
  object.hasCompletedOnboarding = reader.readBool(offsets[5]);
  object.id = id;
  object.lastBackupAt = reader.readDateTimeOrNull(offsets[6]);
  object.lastKnownPremium = reader.readBool(offsets[7]);
  object.lastMode = reader.readString(offsets[8]);
  object.locale = reader.readString(offsets[9]);
  object.notificationPrefs =
      reader.readObjectOrNull<NotificationPrefs>(
        offsets[10],
        NotificationPrefsSchema.deserialize,
        allOffsets,
      ) ??
      NotificationPrefs();
  object.presets =
      reader.readObjectList<Preset>(
        offsets[11],
        PresetSchema.deserialize,
        allOffsets,
        Preset(),
      ) ??
      [];
  object.restMinutes = reader.readLong(offsets[12]);
  object.schemaVersion = reader.readLong(offsets[13]);
  object.sleepMinutes = reader.readLong(offsets[14]);
  object.sleepMixerBrownLevel = reader.readDouble(offsets[15]);
  object.sleepMixerPinkLevel = reader.readDouble(offsets[16]);
  object.sleepMixerPresetId = reader.readString(offsets[17]);
  object.sleepMixerWhiteLevel = reader.readDouble(offsets[18]);
  object.sleepSmartAlarmExactFallback = reader.readBool(offsets[19]);
  object.sleepSmartAlarmIntervalMinutes = reader.readLong(offsets[20]);
  object.sleepSmartAlarmWindowMinutes = reader.readLong(offsets[21]);
  object.soundIds = reader.readStringList(offsets[22]) ?? [];
  object.theme = reader.readString(offsets[23]);
  object.updatedAt = reader.readDateTime(offsets[24]);
  object.workoutMinutes = reader.readLong(offsets[25]);
  return object;
}

P _settingsDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectList<BackupLogEntry>(
                offset,
                BackupLogEntrySchema.deserialize,
                allOffsets,
                BackupLogEntry(),
              ) ??
              [])
          as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readObjectOrNull<NotificationPrefs>(
                offset,
                NotificationPrefsSchema.deserialize,
                allOffsets,
              ) ??
              NotificationPrefs())
          as P;
    case 11:
      return (reader.readObjectList<Preset>(
                offset,
                PresetSchema.deserialize,
                allOffsets,
                Preset(),
              ) ??
              [])
          as P;
    case 12:
      return (reader.readLong(offset)) as P;
    case 13:
      return (reader.readLong(offset)) as P;
    case 14:
      return (reader.readLong(offset)) as P;
    case 15:
      return (reader.readDouble(offset)) as P;
    case 16:
      return (reader.readDouble(offset)) as P;
    case 17:
      return (reader.readString(offset)) as P;
    case 18:
      return (reader.readDouble(offset)) as P;
    case 19:
      return (reader.readBool(offset)) as P;
    case 20:
      return (reader.readLong(offset)) as P;
    case 21:
      return (reader.readLong(offset)) as P;
    case 22:
      return (reader.readStringList(offset) ?? []) as P;
    case 23:
      return (reader.readString(offset)) as P;
    case 24:
      return (reader.readDateTime(offset)) as P;
    case 25:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _settingsGetId(Settings object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _settingsGetLinks(Settings object) {
  return [];
}

void _settingsAttach(IsarCollection<dynamic> col, Id id, Settings object) {
  object.id = id;
}

extension SettingsQueryWhereSort on QueryBuilder<Settings, Settings, QWhere> {
  QueryBuilder<Settings, Settings, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SettingsQueryWhere on QueryBuilder<Settings, Settings, QWhereClause> {
  QueryBuilder<Settings, Settings, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<Settings, Settings, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Settings, Settings, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension SettingsQueryFilter
    on QueryBuilder<Settings, Settings, QFilterCondition> {
  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  backupHistoryLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'backupHistory', length, true, length, true);
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  backupHistoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'backupHistory', 0, true, 0, true);
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  backupHistoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'backupHistory', 0, false, 999999, true);
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  backupHistoryLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'backupHistory', 0, true, length, include);
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  backupHistoryLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'backupHistory', length, include, 999999, true);
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  backupHistoryLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'backupHistory',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  backupPreferredProviderEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'backupPreferredProvider',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  backupPreferredProviderGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'backupPreferredProvider',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  backupPreferredProviderLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'backupPreferredProvider',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  backupPreferredProviderBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'backupPreferredProvider',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  backupPreferredProviderStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'backupPreferredProvider',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  backupPreferredProviderEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'backupPreferredProvider',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  backupPreferredProviderContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'backupPreferredProvider',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  backupPreferredProviderMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'backupPreferredProvider',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  backupPreferredProviderIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'backupPreferredProvider',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  backupPreferredProviderIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'backupPreferredProvider',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> createdAtEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> deviceIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'deviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> deviceIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'deviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> deviceIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'deviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> deviceIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'deviceId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> deviceIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'deviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> deviceIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'deviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> deviceIdContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'deviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> deviceIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'deviceId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> deviceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'deviceId', value: ''),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> deviceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'deviceId', value: ''),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> focusMinutesEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'focusMinutes', value: value),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  focusMinutesGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'focusMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> focusMinutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'focusMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> focusMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'focusMinutes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  hasCompletedOnboardingEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'hasCompletedOnboarding',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> lastBackupAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastBackupAt'),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  lastBackupAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastBackupAt'),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> lastBackupAtEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastBackupAt', value: value),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  lastBackupAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastBackupAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> lastBackupAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastBackupAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> lastBackupAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastBackupAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  lastKnownPremiumEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastKnownPremium', value: value),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> lastModeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'lastMode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> lastModeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastMode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> lastModeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastMode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> lastModeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastMode',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> lastModeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'lastMode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> lastModeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'lastMode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> lastModeContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'lastMode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> lastModeMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'lastMode',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> lastModeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastMode', value: ''),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> lastModeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'lastMode', value: ''),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> localeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'locale',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> localeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'locale',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> localeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'locale',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> localeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'locale',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> localeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'locale',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> localeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'locale',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> localeContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'locale',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> localeMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'locale',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> localeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'locale', value: ''),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> localeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'locale', value: ''),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> presetsLengthEqualTo(
    int length,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'presets', length, true, length, true);
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> presetsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'presets', 0, true, 0, true);
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> presetsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'presets', 0, false, 999999, true);
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> presetsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'presets', 0, true, length, include);
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  presetsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'presets', length, include, 999999, true);
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> presetsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'presets',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> restMinutesEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'restMinutes', value: value),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  restMinutesGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'restMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> restMinutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'restMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> restMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'restMinutes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> schemaVersionEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'schemaVersion', value: value),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  schemaVersionGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'schemaVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> schemaVersionLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'schemaVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> schemaVersionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'schemaVersion',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> sleepMinutesEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sleepMinutes', value: value),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepMinutesGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sleepMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> sleepMinutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sleepMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> sleepMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sleepMinutes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepMixerBrownLevelEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sleepMixerBrownLevel',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepMixerBrownLevelGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sleepMixerBrownLevel',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepMixerBrownLevelLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sleepMixerBrownLevel',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepMixerBrownLevelBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sleepMixerBrownLevel',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepMixerPinkLevelEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sleepMixerPinkLevel',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepMixerPinkLevelGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sleepMixerPinkLevel',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepMixerPinkLevelLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sleepMixerPinkLevel',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepMixerPinkLevelBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sleepMixerPinkLevel',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepMixerPresetIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sleepMixerPresetId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepMixerPresetIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sleepMixerPresetId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepMixerPresetIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sleepMixerPresetId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepMixerPresetIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sleepMixerPresetId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepMixerPresetIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sleepMixerPresetId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepMixerPresetIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sleepMixerPresetId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepMixerPresetIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sleepMixerPresetId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepMixerPresetIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sleepMixerPresetId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepMixerPresetIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sleepMixerPresetId', value: ''),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepMixerPresetIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sleepMixerPresetId', value: ''),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepMixerWhiteLevelEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sleepMixerWhiteLevel',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepMixerWhiteLevelGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sleepMixerWhiteLevel',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepMixerWhiteLevelLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sleepMixerWhiteLevel',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepMixerWhiteLevelBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sleepMixerWhiteLevel',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepSmartAlarmExactFallbackEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sleepSmartAlarmExactFallback',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepSmartAlarmIntervalMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sleepSmartAlarmIntervalMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepSmartAlarmIntervalMinutesGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sleepSmartAlarmIntervalMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepSmartAlarmIntervalMinutesLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sleepSmartAlarmIntervalMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepSmartAlarmIntervalMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sleepSmartAlarmIntervalMinutes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepSmartAlarmWindowMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sleepSmartAlarmWindowMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepSmartAlarmWindowMinutesGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sleepSmartAlarmWindowMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepSmartAlarmWindowMinutesLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sleepSmartAlarmWindowMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  sleepSmartAlarmWindowMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sleepSmartAlarmWindowMinutes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  soundIdsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'soundIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  soundIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'soundIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  soundIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'soundIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  soundIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'soundIds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  soundIdsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'soundIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  soundIdsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'soundIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  soundIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'soundIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  soundIdsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'soundIds',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  soundIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'soundIds', value: ''),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  soundIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'soundIds', value: ''),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> soundIdsLengthEqualTo(
    int length,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'soundIds', length, true, length, true);
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> soundIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'soundIds', 0, true, 0, true);
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> soundIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'soundIds', 0, false, 999999, true);
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  soundIdsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'soundIds', 0, true, length, include);
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  soundIdsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'soundIds', length, include, 999999, true);
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> soundIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'soundIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> themeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'theme',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> themeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'theme',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> themeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'theme',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> themeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'theme',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> themeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'theme',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> themeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'theme',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> themeContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'theme',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> themeMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'theme',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> themeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'theme', value: ''),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> themeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'theme', value: ''),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> updatedAtEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> workoutMinutesEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'workoutMinutes', value: value),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  workoutMinutesGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'workoutMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
  workoutMinutesLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'workoutMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> workoutMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'workoutMinutes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension SettingsQueryObject
    on QueryBuilder<Settings, Settings, QFilterCondition> {
  QueryBuilder<Settings, Settings, QAfterFilterCondition> backupHistoryElement(
    FilterQuery<BackupLogEntry> q,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'backupHistory');
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> notificationPrefs(
    FilterQuery<NotificationPrefs> q,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'notificationPrefs');
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> presetsElement(
    FilterQuery<Preset> q,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'presets');
    });
  }
}

extension SettingsQueryLinks
    on QueryBuilder<Settings, Settings, QFilterCondition> {}

extension SettingsQuerySortBy on QueryBuilder<Settings, Settings, QSortBy> {
  QueryBuilder<Settings, Settings, QAfterSortBy>
  sortByBackupPreferredProvider() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backupPreferredProvider', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
  sortByBackupPreferredProviderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backupPreferredProvider', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByDeviceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByDeviceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByFocusMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'focusMinutes', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByFocusMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'focusMinutes', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
  sortByHasCompletedOnboarding() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasCompletedOnboarding', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
  sortByHasCompletedOnboardingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasCompletedOnboarding', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByLastBackupAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastBackupAt', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByLastBackupAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastBackupAt', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByLastKnownPremium() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastKnownPremium', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByLastKnownPremiumDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastKnownPremium', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByLastMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMode', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByLastModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMode', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByLocale() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locale', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByLocaleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locale', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByRestMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restMinutes', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByRestMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restMinutes', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortBySleepMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepMinutes', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortBySleepMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepMinutes', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortBySleepMixerBrownLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepMixerBrownLevel', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
  sortBySleepMixerBrownLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepMixerBrownLevel', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortBySleepMixerPinkLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepMixerPinkLevel', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
  sortBySleepMixerPinkLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepMixerPinkLevel', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortBySleepMixerPresetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepMixerPresetId', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
  sortBySleepMixerPresetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepMixerPresetId', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortBySleepMixerWhiteLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepMixerWhiteLevel', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
  sortBySleepMixerWhiteLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepMixerWhiteLevel', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
  sortBySleepSmartAlarmExactFallback() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepSmartAlarmExactFallback', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
  sortBySleepSmartAlarmExactFallbackDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepSmartAlarmExactFallback', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
  sortBySleepSmartAlarmIntervalMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepSmartAlarmIntervalMinutes', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
  sortBySleepSmartAlarmIntervalMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepSmartAlarmIntervalMinutes', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
  sortBySleepSmartAlarmWindowMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepSmartAlarmWindowMinutes', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
  sortBySleepSmartAlarmWindowMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepSmartAlarmWindowMinutes', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByTheme() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'theme', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByThemeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'theme', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByWorkoutMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutMinutes', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByWorkoutMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutMinutes', Sort.desc);
    });
  }
}

extension SettingsQuerySortThenBy
    on QueryBuilder<Settings, Settings, QSortThenBy> {
  QueryBuilder<Settings, Settings, QAfterSortBy>
  thenByBackupPreferredProvider() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backupPreferredProvider', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
  thenByBackupPreferredProviderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backupPreferredProvider', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByDeviceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByDeviceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByFocusMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'focusMinutes', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByFocusMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'focusMinutes', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
  thenByHasCompletedOnboarding() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasCompletedOnboarding', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
  thenByHasCompletedOnboardingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasCompletedOnboarding', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByLastBackupAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastBackupAt', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByLastBackupAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastBackupAt', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByLastKnownPremium() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastKnownPremium', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByLastKnownPremiumDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastKnownPremium', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByLastMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMode', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByLastModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMode', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByLocale() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locale', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByLocaleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locale', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByRestMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restMinutes', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByRestMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restMinutes', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenBySleepMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepMinutes', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenBySleepMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepMinutes', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenBySleepMixerBrownLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepMixerBrownLevel', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
  thenBySleepMixerBrownLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepMixerBrownLevel', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenBySleepMixerPinkLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepMixerPinkLevel', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
  thenBySleepMixerPinkLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepMixerPinkLevel', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenBySleepMixerPresetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepMixerPresetId', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
  thenBySleepMixerPresetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepMixerPresetId', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenBySleepMixerWhiteLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepMixerWhiteLevel', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
  thenBySleepMixerWhiteLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepMixerWhiteLevel', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
  thenBySleepSmartAlarmExactFallback() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepSmartAlarmExactFallback', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
  thenBySleepSmartAlarmExactFallbackDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepSmartAlarmExactFallback', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
  thenBySleepSmartAlarmIntervalMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepSmartAlarmIntervalMinutes', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
  thenBySleepSmartAlarmIntervalMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepSmartAlarmIntervalMinutes', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
  thenBySleepSmartAlarmWindowMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepSmartAlarmWindowMinutes', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
  thenBySleepSmartAlarmWindowMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepSmartAlarmWindowMinutes', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByTheme() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'theme', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByThemeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'theme', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByWorkoutMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutMinutes', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByWorkoutMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutMinutes', Sort.desc);
    });
  }
}

extension SettingsQueryWhereDistinct
    on QueryBuilder<Settings, Settings, QDistinct> {
  QueryBuilder<Settings, Settings, QDistinct>
  distinctByBackupPreferredProvider({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'backupPreferredProvider',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctByDeviceId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deviceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctByFocusMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'focusMinutes');
    });
  }

  QueryBuilder<Settings, Settings, QDistinct>
  distinctByHasCompletedOnboarding() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasCompletedOnboarding');
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctByLastBackupAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastBackupAt');
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctByLastKnownPremium() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastKnownPremium');
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctByLastMode({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastMode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctByLocale({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'locale', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctByRestMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'restMinutes');
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schemaVersion');
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctBySleepMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sleepMinutes');
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctBySleepMixerBrownLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sleepMixerBrownLevel');
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctBySleepMixerPinkLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sleepMixerPinkLevel');
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctBySleepMixerPresetId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'sleepMixerPresetId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctBySleepMixerWhiteLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sleepMixerWhiteLevel');
    });
  }

  QueryBuilder<Settings, Settings, QDistinct>
  distinctBySleepSmartAlarmExactFallback() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sleepSmartAlarmExactFallback');
    });
  }

  QueryBuilder<Settings, Settings, QDistinct>
  distinctBySleepSmartAlarmIntervalMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sleepSmartAlarmIntervalMinutes');
    });
  }

  QueryBuilder<Settings, Settings, QDistinct>
  distinctBySleepSmartAlarmWindowMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sleepSmartAlarmWindowMinutes');
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctBySoundIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'soundIds');
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctByTheme({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'theme', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctByWorkoutMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'workoutMinutes');
    });
  }
}

extension SettingsQueryProperty
    on QueryBuilder<Settings, Settings, QQueryProperty> {
  QueryBuilder<Settings, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Settings, List<BackupLogEntry>, QQueryOperations>
  backupHistoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'backupHistory');
    });
  }

  QueryBuilder<Settings, String, QQueryOperations>
  backupPreferredProviderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'backupPreferredProvider');
    });
  }

  QueryBuilder<Settings, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<Settings, String, QQueryOperations> deviceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deviceId');
    });
  }

  QueryBuilder<Settings, int, QQueryOperations> focusMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'focusMinutes');
    });
  }

  QueryBuilder<Settings, bool, QQueryOperations>
  hasCompletedOnboardingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasCompletedOnboarding');
    });
  }

  QueryBuilder<Settings, DateTime?, QQueryOperations> lastBackupAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastBackupAt');
    });
  }

  QueryBuilder<Settings, bool, QQueryOperations> lastKnownPremiumProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastKnownPremium');
    });
  }

  QueryBuilder<Settings, String, QQueryOperations> lastModeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastMode');
    });
  }

  QueryBuilder<Settings, String, QQueryOperations> localeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'locale');
    });
  }

  QueryBuilder<Settings, NotificationPrefs, QQueryOperations>
  notificationPrefsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notificationPrefs');
    });
  }

  QueryBuilder<Settings, List<Preset>, QQueryOperations> presetsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'presets');
    });
  }

  QueryBuilder<Settings, int, QQueryOperations> restMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'restMinutes');
    });
  }

  QueryBuilder<Settings, int, QQueryOperations> schemaVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schemaVersion');
    });
  }

  QueryBuilder<Settings, int, QQueryOperations> sleepMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sleepMinutes');
    });
  }

  QueryBuilder<Settings, double, QQueryOperations>
  sleepMixerBrownLevelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sleepMixerBrownLevel');
    });
  }

  QueryBuilder<Settings, double, QQueryOperations>
  sleepMixerPinkLevelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sleepMixerPinkLevel');
    });
  }

  QueryBuilder<Settings, String, QQueryOperations>
  sleepMixerPresetIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sleepMixerPresetId');
    });
  }

  QueryBuilder<Settings, double, QQueryOperations>
  sleepMixerWhiteLevelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sleepMixerWhiteLevel');
    });
  }

  QueryBuilder<Settings, bool, QQueryOperations>
  sleepSmartAlarmExactFallbackProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sleepSmartAlarmExactFallback');
    });
  }

  QueryBuilder<Settings, int, QQueryOperations>
  sleepSmartAlarmIntervalMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sleepSmartAlarmIntervalMinutes');
    });
  }

  QueryBuilder<Settings, int, QQueryOperations>
  sleepSmartAlarmWindowMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sleepSmartAlarmWindowMinutes');
    });
  }

  QueryBuilder<Settings, List<String>, QQueryOperations> soundIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'soundIds');
    });
  }

  QueryBuilder<Settings, String, QQueryOperations> themeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'theme');
    });
  }

  QueryBuilder<Settings, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<Settings, int, QQueryOperations> workoutMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'workoutMinutes');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const PresetSchema = Schema(
  name: r'Preset',
  id: -7604157809264403462,
  properties: {
    r'autoPlaySound': PropertySchema(
      id: 0,
      name: r'autoPlaySound',
      type: IsarType.bool,
    ),
    r'durationMinutes': PropertySchema(
      id: 1,
      name: r'durationMinutes',
      type: IsarType.long,
    ),
    r'id': PropertySchema(id: 2, name: r'id', type: IsarType.string),
    r'mode': PropertySchema(id: 3, name: r'mode', type: IsarType.string),
    r'name': PropertySchema(id: 4, name: r'name', type: IsarType.string),
    r'soundId': PropertySchema(id: 5, name: r'soundId', type: IsarType.string),
  },

  estimateSize: _presetEstimateSize,
  serialize: _presetSerialize,
  deserialize: _presetDeserialize,
  deserializeProp: _presetDeserializeProp,
);

int _presetEstimateSize(
  Preset object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.id.length * 3;
  bytesCount += 3 + object.mode.length * 3;
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.soundId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _presetSerialize(
  Preset object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.autoPlaySound);
  writer.writeLong(offsets[1], object.durationMinutes);
  writer.writeString(offsets[2], object.id);
  writer.writeString(offsets[3], object.mode);
  writer.writeString(offsets[4], object.name);
  writer.writeString(offsets[5], object.soundId);
}

Preset _presetDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Preset();
  object.autoPlaySound = reader.readBool(offsets[0]);
  object.durationMinutes = reader.readLong(offsets[1]);
  object.id = reader.readString(offsets[2]);
  object.mode = reader.readString(offsets[3]);
  object.name = reader.readString(offsets[4]);
  object.soundId = reader.readStringOrNull(offsets[5]);
  return object;
}

P _presetDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension PresetQueryFilter on QueryBuilder<Preset, Preset, QFilterCondition> {
  QueryBuilder<Preset, Preset, QAfterFilterCondition> autoPlaySoundEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'autoPlaySound', value: value),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> durationMinutesEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'durationMinutes', value: value),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition>
  durationMinutesGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'durationMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> durationMinutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'durationMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> durationMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'durationMinutes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> idContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> idMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'id',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: ''),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'id', value: ''),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> modeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'mode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> modeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'mode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> modeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'mode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> modeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'mode',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> modeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'mode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> modeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'mode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> modeContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'mode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> modeMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'mode',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> modeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'mode', value: ''),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> modeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'mode', value: ''),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'name',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> nameContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> nameMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'name',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> soundIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'soundId'),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> soundIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'soundId'),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> soundIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'soundId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> soundIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'soundId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> soundIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'soundId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> soundIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'soundId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> soundIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'soundId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> soundIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'soundId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> soundIdContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'soundId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> soundIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'soundId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> soundIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'soundId', value: ''),
      );
    });
  }

  QueryBuilder<Preset, Preset, QAfterFilterCondition> soundIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'soundId', value: ''),
      );
    });
  }
}

extension PresetQueryObject on QueryBuilder<Preset, Preset, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const NotificationPrefsSchema = Schema(
  name: r'NotificationPrefs',
  id: 3460341432136532071,
  properties: {
    r'focusComplete': PropertySchema(
      id: 0,
      name: r'focusComplete',
      type: IsarType.bool,
    ),
    r'restComplete': PropertySchema(
      id: 1,
      name: r'restComplete',
      type: IsarType.bool,
    ),
    r'sleepAlarm': PropertySchema(
      id: 2,
      name: r'sleepAlarm',
      type: IsarType.bool,
    ),
    r'workoutComplete': PropertySchema(
      id: 3,
      name: r'workoutComplete',
      type: IsarType.bool,
    ),
  },

  estimateSize: _notificationPrefsEstimateSize,
  serialize: _notificationPrefsSerialize,
  deserialize: _notificationPrefsDeserialize,
  deserializeProp: _notificationPrefsDeserializeProp,
);

int _notificationPrefsEstimateSize(
  NotificationPrefs object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _notificationPrefsSerialize(
  NotificationPrefs object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.focusComplete);
  writer.writeBool(offsets[1], object.restComplete);
  writer.writeBool(offsets[2], object.sleepAlarm);
  writer.writeBool(offsets[3], object.workoutComplete);
}

NotificationPrefs _notificationPrefsDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = NotificationPrefs();
  object.focusComplete = reader.readBool(offsets[0]);
  object.restComplete = reader.readBool(offsets[1]);
  object.sleepAlarm = reader.readBool(offsets[2]);
  object.workoutComplete = reader.readBool(offsets[3]);
  return object;
}

P _notificationPrefsDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension NotificationPrefsQueryFilter
    on QueryBuilder<NotificationPrefs, NotificationPrefs, QFilterCondition> {
  QueryBuilder<NotificationPrefs, NotificationPrefs, QAfterFilterCondition>
  focusCompleteEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'focusComplete', value: value),
      );
    });
  }

  QueryBuilder<NotificationPrefs, NotificationPrefs, QAfterFilterCondition>
  restCompleteEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'restComplete', value: value),
      );
    });
  }

  QueryBuilder<NotificationPrefs, NotificationPrefs, QAfterFilterCondition>
  sleepAlarmEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sleepAlarm', value: value),
      );
    });
  }

  QueryBuilder<NotificationPrefs, NotificationPrefs, QAfterFilterCondition>
  workoutCompleteEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'workoutComplete', value: value),
      );
    });
  }
}

extension NotificationPrefsQueryObject
    on QueryBuilder<NotificationPrefs, NotificationPrefs, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const BackupLogEntrySchema = Schema(
  name: r'BackupLogEntry',
  id: 4399719813158117640,
  properties: {
    r'action': PropertySchema(id: 0, name: r'action', type: IsarType.string),
    r'bytes': PropertySchema(id: 1, name: r'bytes', type: IsarType.long),
    r'errorMessage': PropertySchema(
      id: 2,
      name: r'errorMessage',
      type: IsarType.string,
    ),
    r'provider': PropertySchema(
      id: 3,
      name: r'provider',
      type: IsarType.string,
    ),
    r'status': PropertySchema(id: 4, name: r'status', type: IsarType.string),
    r'timestamp': PropertySchema(
      id: 5,
      name: r'timestamp',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _backupLogEntryEstimateSize,
  serialize: _backupLogEntrySerialize,
  deserialize: _backupLogEntryDeserialize,
  deserializeProp: _backupLogEntryDeserializeProp,
);

int _backupLogEntryEstimateSize(
  BackupLogEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.action.length * 3;
  {
    final value = object.errorMessage;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.provider.length * 3;
  bytesCount += 3 + object.status.length * 3;
  return bytesCount;
}

void _backupLogEntrySerialize(
  BackupLogEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.action);
  writer.writeLong(offsets[1], object.bytes);
  writer.writeString(offsets[2], object.errorMessage);
  writer.writeString(offsets[3], object.provider);
  writer.writeString(offsets[4], object.status);
  writer.writeDateTime(offsets[5], object.timestamp);
}

BackupLogEntry _backupLogEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BackupLogEntry();
  object.action = reader.readString(offsets[0]);
  object.bytes = reader.readLong(offsets[1]);
  object.errorMessage = reader.readStringOrNull(offsets[2]);
  object.provider = reader.readString(offsets[3]);
  object.status = reader.readString(offsets[4]);
  object.timestamp = reader.readDateTime(offsets[5]);
  return object;
}

P _backupLogEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension BackupLogEntryQueryFilter
    on QueryBuilder<BackupLogEntry, BackupLogEntry, QFilterCondition> {
  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  actionEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'action',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  actionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'action',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  actionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'action',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  actionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'action',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  actionStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'action',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  actionEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'action',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  actionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'action',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  actionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'action',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  actionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'action', value: ''),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  actionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'action', value: ''),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  bytesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'bytes', value: value),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  bytesGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'bytes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  bytesLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'bytes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  bytesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'bytes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  errorMessageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'errorMessage'),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  errorMessageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'errorMessage'),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  errorMessageEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'errorMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  errorMessageGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'errorMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  errorMessageLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'errorMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  errorMessageBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'errorMessage',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  errorMessageStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'errorMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  errorMessageEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'errorMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  errorMessageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'errorMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  errorMessageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'errorMessage',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  errorMessageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'errorMessage', value: ''),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  errorMessageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'errorMessage', value: ''),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  providerEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'provider',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  providerGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'provider',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  providerLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'provider',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  providerBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'provider',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  providerStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'provider',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  providerEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'provider',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  providerContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'provider',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  providerMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'provider',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  providerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'provider', value: ''),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  providerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'provider', value: ''),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  statusEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'status',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  statusStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  statusEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'status',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'timestamp', value: value),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  timestampGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'timestamp',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  timestampLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'timestamp',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BackupLogEntry, BackupLogEntry, QAfterFilterCondition>
  timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'timestamp',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension BackupLogEntryQueryObject
    on QueryBuilder<BackupLogEntry, BackupLogEntry, QFilterCondition> {}
