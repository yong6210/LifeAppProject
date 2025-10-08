// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_summary_local.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDailySummaryLocalCollection on Isar {
  IsarCollection<DailySummaryLocal> get dailySummaryLocals => this.collection();
}

const DailySummaryLocalSchema = CollectionSchema(
  name: r'DailySummaryLocal',
  id: -1948533463331310724,
  properties: {
    r'date': PropertySchema(id: 0, name: r'date', type: IsarType.dateTime),
    r'deviceId': PropertySchema(
      id: 1,
      name: r'deviceId',
      type: IsarType.string,
    ),
    r'focusMinutes': PropertySchema(
      id: 2,
      name: r'focusMinutes',
      type: IsarType.long,
    ),
    r'restMinutes': PropertySchema(
      id: 3,
      name: r'restMinutes',
      type: IsarType.long,
    ),
    r'sleepMinutes': PropertySchema(
      id: 4,
      name: r'sleepMinutes',
      type: IsarType.long,
    ),
    r'updatedAt': PropertySchema(
      id: 5,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'workoutMinutes': PropertySchema(
      id: 6,
      name: r'workoutMinutes',
      type: IsarType.long,
    ),
  },

  estimateSize: _dailySummaryLocalEstimateSize,
  serialize: _dailySummaryLocalSerialize,
  deserialize: _dailySummaryLocalDeserialize,
  deserializeProp: _dailySummaryLocalDeserializeProp,
  idName: r'id',
  indexes: {
    r'date_deviceId': IndexSchema(
      id: -4192966864440415968,
      name: r'date_deviceId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'date',
          type: IndexType.value,
          caseSensitive: false,
        ),
        IndexPropertySchema(
          name: r'deviceId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _dailySummaryLocalGetId,
  getLinks: _dailySummaryLocalGetLinks,
  attach: _dailySummaryLocalAttach,
  version: '3.1.0+1',
);

int _dailySummaryLocalEstimateSize(
  DailySummaryLocal object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.deviceId.length * 3;
  return bytesCount;
}

void _dailySummaryLocalSerialize(
  DailySummaryLocal object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.date);
  writer.writeString(offsets[1], object.deviceId);
  writer.writeLong(offsets[2], object.focusMinutes);
  writer.writeLong(offsets[3], object.restMinutes);
  writer.writeLong(offsets[4], object.sleepMinutes);
  writer.writeDateTime(offsets[5], object.updatedAt);
  writer.writeLong(offsets[6], object.workoutMinutes);
}

DailySummaryLocal _dailySummaryLocalDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DailySummaryLocal();
  object.date = reader.readDateTime(offsets[0]);
  object.deviceId = reader.readString(offsets[1]);
  object.focusMinutes = reader.readLong(offsets[2]);
  object.id = id;
  object.restMinutes = reader.readLong(offsets[3]);
  object.sleepMinutes = reader.readLong(offsets[4]);
  object.updatedAt = reader.readDateTime(offsets[5]);
  object.workoutMinutes = reader.readLong(offsets[6]);
  return object;
}

P _dailySummaryLocalDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dailySummaryLocalGetId(DailySummaryLocal object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dailySummaryLocalGetLinks(
  DailySummaryLocal object,
) {
  return [];
}

void _dailySummaryLocalAttach(
  IsarCollection<dynamic> col,
  Id id,
  DailySummaryLocal object,
) {
  object.id = id;
}

extension DailySummaryLocalByIndex on IsarCollection<DailySummaryLocal> {
  Future<DailySummaryLocal?> getByDateDeviceId(DateTime date, String deviceId) {
    return getByIndex(r'date_deviceId', [date, deviceId]);
  }

  DailySummaryLocal? getByDateDeviceIdSync(DateTime date, String deviceId) {
    return getByIndexSync(r'date_deviceId', [date, deviceId]);
  }

  Future<bool> deleteByDateDeviceId(DateTime date, String deviceId) {
    return deleteByIndex(r'date_deviceId', [date, deviceId]);
  }

  bool deleteByDateDeviceIdSync(DateTime date, String deviceId) {
    return deleteByIndexSync(r'date_deviceId', [date, deviceId]);
  }

  Future<List<DailySummaryLocal?>> getAllByDateDeviceId(
    List<DateTime> dateValues,
    List<String> deviceIdValues,
  ) {
    final len = dateValues.length;
    assert(
      deviceIdValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([dateValues[i], deviceIdValues[i]]);
    }

    return getAllByIndex(r'date_deviceId', values);
  }

  List<DailySummaryLocal?> getAllByDateDeviceIdSync(
    List<DateTime> dateValues,
    List<String> deviceIdValues,
  ) {
    final len = dateValues.length;
    assert(
      deviceIdValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([dateValues[i], deviceIdValues[i]]);
    }

    return getAllByIndexSync(r'date_deviceId', values);
  }

  Future<int> deleteAllByDateDeviceId(
    List<DateTime> dateValues,
    List<String> deviceIdValues,
  ) {
    final len = dateValues.length;
    assert(
      deviceIdValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([dateValues[i], deviceIdValues[i]]);
    }

    return deleteAllByIndex(r'date_deviceId', values);
  }

  int deleteAllByDateDeviceIdSync(
    List<DateTime> dateValues,
    List<String> deviceIdValues,
  ) {
    final len = dateValues.length;
    assert(
      deviceIdValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([dateValues[i], deviceIdValues[i]]);
    }

    return deleteAllByIndexSync(r'date_deviceId', values);
  }

  Future<Id> putByDateDeviceId(DailySummaryLocal object) {
    return putByIndex(r'date_deviceId', object);
  }

  Id putByDateDeviceIdSync(DailySummaryLocal object, {bool saveLinks = true}) {
    return putByIndexSync(r'date_deviceId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDateDeviceId(List<DailySummaryLocal> objects) {
    return putAllByIndex(r'date_deviceId', objects);
  }

  List<Id> putAllByDateDeviceIdSync(
    List<DailySummaryLocal> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'date_deviceId', objects, saveLinks: saveLinks);
  }
}

extension DailySummaryLocalQueryWhereSort
    on QueryBuilder<DailySummaryLocal, DailySummaryLocal, QWhere> {
  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DailySummaryLocalQueryWhere
    on QueryBuilder<DailySummaryLocal, DailySummaryLocal, QWhereClause> {
  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterWhereClause>
  idNotEqualTo(Id id) {
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

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterWhereClause>
  idBetween(
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

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterWhereClause>
  dateEqualToAnyDeviceId(DateTime date) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'date_deviceId', value: [date]),
      );
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterWhereClause>
  dateNotEqualToAnyDeviceId(DateTime date) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'date_deviceId',
                lower: [],
                upper: [date],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'date_deviceId',
                lower: [date],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'date_deviceId',
                lower: [date],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'date_deviceId',
                lower: [],
                upper: [date],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterWhereClause>
  dateGreaterThanAnyDeviceId(DateTime date, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'date_deviceId',
          lower: [date],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterWhereClause>
  dateLessThanAnyDeviceId(DateTime date, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'date_deviceId',
          lower: [],
          upper: [date],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterWhereClause>
  dateBetweenAnyDeviceId(
    DateTime lowerDate,
    DateTime upperDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'date_deviceId',
          lower: [lowerDate],
          includeLower: includeLower,
          upper: [upperDate],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterWhereClause>
  dateDeviceIdEqualTo(DateTime date, String deviceId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'date_deviceId',
          value: [date, deviceId],
        ),
      );
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterWhereClause>
  dateEqualToDeviceIdNotEqualTo(DateTime date, String deviceId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'date_deviceId',
                lower: [date],
                upper: [date, deviceId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'date_deviceId',
                lower: [date, deviceId],
                includeLower: false,
                upper: [date],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'date_deviceId',
                lower: [date, deviceId],
                includeLower: false,
                upper: [date],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'date_deviceId',
                lower: [date],
                upper: [date, deviceId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension DailySummaryLocalQueryFilter
    on QueryBuilder<DailySummaryLocal, DailySummaryLocal, QFilterCondition> {
  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  dateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'date', value: value),
      );
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  dateGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'date',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  dateLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'date',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'date',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  deviceIdEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  deviceIdGreaterThan(
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

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  deviceIdLessThan(
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

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  deviceIdBetween(
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

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  deviceIdStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  deviceIdEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  deviceIdContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  deviceIdMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  deviceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'deviceId', value: ''),
      );
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  deviceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'deviceId', value: ''),
      );
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  focusMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'focusMinutes', value: value),
      );
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
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

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  focusMinutesLessThan(int value, {bool include = false}) {
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

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  focusMinutesBetween(
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

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
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

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
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

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  idBetween(
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

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  restMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'restMinutes', value: value),
      );
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
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

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  restMinutesLessThan(int value, {bool include = false}) {
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

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  restMinutesBetween(
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

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  sleepMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sleepMinutes', value: value),
      );
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
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

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  sleepMinutesLessThan(int value, {bool include = false}) {
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

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  sleepMinutesBetween(
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

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  updatedAtGreaterThan(DateTime value, {bool include = false}) {
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

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  updatedAtLessThan(DateTime value, {bool include = false}) {
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

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  updatedAtBetween(
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

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  workoutMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'workoutMinutes', value: value),
      );
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
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

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
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

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterFilterCondition>
  workoutMinutesBetween(
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

extension DailySummaryLocalQueryObject
    on QueryBuilder<DailySummaryLocal, DailySummaryLocal, QFilterCondition> {}

extension DailySummaryLocalQueryLinks
    on QueryBuilder<DailySummaryLocal, DailySummaryLocal, QFilterCondition> {}

extension DailySummaryLocalQuerySortBy
    on QueryBuilder<DailySummaryLocal, DailySummaryLocal, QSortBy> {
  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterSortBy>
  sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterSortBy>
  sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterSortBy>
  sortByDeviceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.asc);
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterSortBy>
  sortByDeviceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.desc);
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterSortBy>
  sortByFocusMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'focusMinutes', Sort.asc);
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterSortBy>
  sortByFocusMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'focusMinutes', Sort.desc);
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterSortBy>
  sortByRestMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restMinutes', Sort.asc);
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterSortBy>
  sortByRestMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restMinutes', Sort.desc);
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterSortBy>
  sortBySleepMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepMinutes', Sort.asc);
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterSortBy>
  sortBySleepMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepMinutes', Sort.desc);
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterSortBy>
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterSortBy>
  sortByWorkoutMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutMinutes', Sort.asc);
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterSortBy>
  sortByWorkoutMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutMinutes', Sort.desc);
    });
  }
}

extension DailySummaryLocalQuerySortThenBy
    on QueryBuilder<DailySummaryLocal, DailySummaryLocal, QSortThenBy> {
  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterSortBy>
  thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterSortBy>
  thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterSortBy>
  thenByDeviceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.asc);
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterSortBy>
  thenByDeviceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.desc);
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterSortBy>
  thenByFocusMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'focusMinutes', Sort.asc);
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterSortBy>
  thenByFocusMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'focusMinutes', Sort.desc);
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterSortBy>
  thenByRestMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restMinutes', Sort.asc);
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterSortBy>
  thenByRestMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restMinutes', Sort.desc);
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterSortBy>
  thenBySleepMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepMinutes', Sort.asc);
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterSortBy>
  thenBySleepMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepMinutes', Sort.desc);
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterSortBy>
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterSortBy>
  thenByWorkoutMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutMinutes', Sort.asc);
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QAfterSortBy>
  thenByWorkoutMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutMinutes', Sort.desc);
    });
  }
}

extension DailySummaryLocalQueryWhereDistinct
    on QueryBuilder<DailySummaryLocal, DailySummaryLocal, QDistinct> {
  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QDistinct>
  distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QDistinct>
  distinctByDeviceId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deviceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QDistinct>
  distinctByFocusMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'focusMinutes');
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QDistinct>
  distinctByRestMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'restMinutes');
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QDistinct>
  distinctBySleepMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sleepMinutes');
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<DailySummaryLocal, DailySummaryLocal, QDistinct>
  distinctByWorkoutMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'workoutMinutes');
    });
  }
}

extension DailySummaryLocalQueryProperty
    on QueryBuilder<DailySummaryLocal, DailySummaryLocal, QQueryProperty> {
  QueryBuilder<DailySummaryLocal, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DailySummaryLocal, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<DailySummaryLocal, String, QQueryOperations> deviceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deviceId');
    });
  }

  QueryBuilder<DailySummaryLocal, int, QQueryOperations>
  focusMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'focusMinutes');
    });
  }

  QueryBuilder<DailySummaryLocal, int, QQueryOperations> restMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'restMinutes');
    });
  }

  QueryBuilder<DailySummaryLocal, int, QQueryOperations>
  sleepMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sleepMinutes');
    });
  }

  QueryBuilder<DailySummaryLocal, DateTime, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<DailySummaryLocal, int, QQueryOperations>
  workoutMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'workoutMinutes');
    });
  }
}
