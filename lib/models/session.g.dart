// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSessionCollection on Isar {
  IsarCollection<Session> get sessions => this.collection();
}

const SessionSchema = CollectionSchema(
  name: r'Session',
  id: 4817823809690647594,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'deviceId': PropertySchema(
      id: 1,
      name: r'deviceId',
      type: IsarType.string,
    ),
    r'endedAt': PropertySchema(
      id: 2,
      name: r'endedAt',
      type: IsarType.dateTime,
    ),
    r'localDate': PropertySchema(
      id: 3,
      name: r'localDate',
      type: IsarType.dateTime,
    ),
    r'navigatorRouteId': PropertySchema(
      id: 4,
      name: r'navigatorRouteId',
      type: IsarType.string,
    ),
    r'navigatorTargetType': PropertySchema(
      id: 5,
      name: r'navigatorTargetType',
      type: IsarType.string,
    ),
    r'navigatorTargetValue': PropertySchema(
      id: 6,
      name: r'navigatorTargetValue',
      type: IsarType.double,
    ),
    r'navigatorVoiceEnabled': PropertySchema(
      id: 7,
      name: r'navigatorVoiceEnabled',
      type: IsarType.bool,
    ),
    r'note': PropertySchema(id: 8, name: r'note', type: IsarType.string),
    r'startedAt': PropertySchema(
      id: 9,
      name: r'startedAt',
      type: IsarType.dateTime,
    ),
    r'tags': PropertySchema(id: 10, name: r'tags', type: IsarType.stringList),
    r'type': PropertySchema(id: 11, name: r'type', type: IsarType.string),
    r'updatedAt': PropertySchema(
      id: 12,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _sessionEstimateSize,
  serialize: _sessionSerialize,
  deserialize: _sessionDeserialize,
  deserializeProp: _sessionDeserializeProp,
  idName: r'id',
  indexes: {
    r'type': IndexSchema(
      id: 5117122708147080838,
      name: r'type',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'type',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'startedAt': IndexSchema(
      id: 8114395319341636597,
      name: r'startedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'startedAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'localDate': IndexSchema(
      id: 2744483300516138583,
      name: r'localDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'localDate',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'deviceId': IndexSchema(
      id: 4442814072367132509,
      name: r'deviceId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'deviceId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'navigatorRouteId': IndexSchema(
      id: -6308522512525611428,
      name: r'navigatorRouteId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'navigatorRouteId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _sessionGetId,
  getLinks: _sessionGetLinks,
  attach: _sessionAttach,
  version: '3.1.0+1',
);

int _sessionEstimateSize(
  Session object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.deviceId.length * 3;
  {
    final value = object.navigatorRouteId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.navigatorTargetType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.note;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.tags.length * 3;
  {
    for (var i = 0; i < object.tags.length; i++) {
      final value = object.tags[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.type.length * 3;
  return bytesCount;
}

void _sessionSerialize(
  Session object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.deviceId);
  writer.writeDateTime(offsets[2], object.endedAt);
  writer.writeDateTime(offsets[3], object.localDate);
  writer.writeString(offsets[4], object.navigatorRouteId);
  writer.writeString(offsets[5], object.navigatorTargetType);
  writer.writeDouble(offsets[6], object.navigatorTargetValue);
  writer.writeBool(offsets[7], object.navigatorVoiceEnabled);
  writer.writeString(offsets[8], object.note);
  writer.writeDateTime(offsets[9], object.startedAt);
  writer.writeStringList(offsets[10], object.tags);
  writer.writeString(offsets[11], object.type);
  writer.writeDateTime(offsets[12], object.updatedAt);
}

Session _sessionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Session();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.deviceId = reader.readString(offsets[1]);
  object.endedAt = reader.readDateTimeOrNull(offsets[2]);
  object.id = id;
  object.localDate = reader.readDateTime(offsets[3]);
  object.navigatorRouteId = reader.readStringOrNull(offsets[4]);
  object.navigatorTargetType = reader.readStringOrNull(offsets[5]);
  object.navigatorTargetValue = reader.readDoubleOrNull(offsets[6]);
  object.navigatorVoiceEnabled = reader.readBoolOrNull(offsets[7]);
  object.note = reader.readStringOrNull(offsets[8]);
  object.startedAt = reader.readDateTime(offsets[9]);
  object.tags = reader.readStringList(offsets[10]) ?? [];
  object.type = reader.readString(offsets[11]);
  object.updatedAt = reader.readDateTime(offsets[12]);
  return object;
}

P _sessionDeserializeProp<P>(
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
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readBoolOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readDateTime(offset)) as P;
    case 10:
      return (reader.readStringList(offset) ?? []) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _sessionGetId(Session object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _sessionGetLinks(Session object) {
  return [];
}

void _sessionAttach(IsarCollection<dynamic> col, Id id, Session object) {
  object.id = id;
}

extension SessionQueryWhereSort on QueryBuilder<Session, Session, QWhere> {
  QueryBuilder<Session, Session, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Session, Session, QAfterWhere> anyStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'startedAt'),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterWhere> anyLocalDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'localDate'),
      );
    });
  }
}

extension SessionQueryWhere on QueryBuilder<Session, Session, QWhereClause> {
  QueryBuilder<Session, Session, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<Session, Session, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Session, Session, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterWhereClause> idBetween(
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

  QueryBuilder<Session, Session, QAfterWhereClause> typeEqualTo(String type) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'type', value: [type]),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterWhereClause> typeNotEqualTo(
    String type,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'type',
                lower: [],
                upper: [type],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'type',
                lower: [type],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'type',
                lower: [type],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'type',
                lower: [],
                upper: [type],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<Session, Session, QAfterWhereClause> startedAtEqualTo(
    DateTime startedAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'startedAt', value: [startedAt]),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterWhereClause> startedAtNotEqualTo(
    DateTime startedAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'startedAt',
                lower: [],
                upper: [startedAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'startedAt',
                lower: [startedAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'startedAt',
                lower: [startedAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'startedAt',
                lower: [],
                upper: [startedAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<Session, Session, QAfterWhereClause> startedAtGreaterThan(
    DateTime startedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'startedAt',
          lower: [startedAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterWhereClause> startedAtLessThan(
    DateTime startedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'startedAt',
          lower: [],
          upper: [startedAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterWhereClause> startedAtBetween(
    DateTime lowerStartedAt,
    DateTime upperStartedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'startedAt',
          lower: [lowerStartedAt],
          includeLower: includeLower,
          upper: [upperStartedAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterWhereClause> localDateEqualTo(
    DateTime localDate,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'localDate', value: [localDate]),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterWhereClause> localDateNotEqualTo(
    DateTime localDate,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'localDate',
                lower: [],
                upper: [localDate],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'localDate',
                lower: [localDate],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'localDate',
                lower: [localDate],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'localDate',
                lower: [],
                upper: [localDate],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<Session, Session, QAfterWhereClause> localDateGreaterThan(
    DateTime localDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'localDate',
          lower: [localDate],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterWhereClause> localDateLessThan(
    DateTime localDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'localDate',
          lower: [],
          upper: [localDate],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterWhereClause> localDateBetween(
    DateTime lowerLocalDate,
    DateTime upperLocalDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'localDate',
          lower: [lowerLocalDate],
          includeLower: includeLower,
          upper: [upperLocalDate],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterWhereClause> deviceIdEqualTo(
    String deviceId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'deviceId', value: [deviceId]),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterWhereClause> deviceIdNotEqualTo(
    String deviceId,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deviceId',
                lower: [],
                upper: [deviceId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deviceId',
                lower: [deviceId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deviceId',
                lower: [deviceId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deviceId',
                lower: [],
                upper: [deviceId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<Session, Session, QAfterWhereClause> navigatorRouteIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'navigatorRouteId', value: [null]),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterWhereClause>
  navigatorRouteIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'navigatorRouteId',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterWhereClause> navigatorRouteIdEqualTo(
    String? navigatorRouteId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'navigatorRouteId',
          value: [navigatorRouteId],
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterWhereClause> navigatorRouteIdNotEqualTo(
    String? navigatorRouteId,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'navigatorRouteId',
                lower: [],
                upper: [navigatorRouteId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'navigatorRouteId',
                lower: [navigatorRouteId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'navigatorRouteId',
                lower: [navigatorRouteId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'navigatorRouteId',
                lower: [],
                upper: [navigatorRouteId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension SessionQueryFilter
    on QueryBuilder<Session, Session, QFilterCondition> {
  QueryBuilder<Session, Session, QAfterFilterCondition> createdAtEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> createdAtGreaterThan(
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

  QueryBuilder<Session, Session, QAfterFilterCondition> createdAtLessThan(
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

  QueryBuilder<Session, Session, QAfterFilterCondition> createdAtBetween(
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

  QueryBuilder<Session, Session, QAfterFilterCondition> deviceIdEqualTo(
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

  QueryBuilder<Session, Session, QAfterFilterCondition> deviceIdGreaterThan(
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

  QueryBuilder<Session, Session, QAfterFilterCondition> deviceIdLessThan(
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

  QueryBuilder<Session, Session, QAfterFilterCondition> deviceIdBetween(
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

  QueryBuilder<Session, Session, QAfterFilterCondition> deviceIdStartsWith(
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

  QueryBuilder<Session, Session, QAfterFilterCondition> deviceIdEndsWith(
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

  QueryBuilder<Session, Session, QAfterFilterCondition> deviceIdContains(
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

  QueryBuilder<Session, Session, QAfterFilterCondition> deviceIdMatches(
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

  QueryBuilder<Session, Session, QAfterFilterCondition> deviceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'deviceId', value: ''),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> deviceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'deviceId', value: ''),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> endedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'endedAt'),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> endedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'endedAt'),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> endedAtEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'endedAt', value: value),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> endedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'endedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> endedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'endedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> endedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'endedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Session, Session, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Session, Session, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Session, Session, QAfterFilterCondition> localDateEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'localDate', value: value),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> localDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'localDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> localDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'localDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> localDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'localDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  navigatorRouteIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'navigatorRouteId'),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  navigatorRouteIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'navigatorRouteId'),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> navigatorRouteIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'navigatorRouteId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  navigatorRouteIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'navigatorRouteId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  navigatorRouteIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'navigatorRouteId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> navigatorRouteIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'navigatorRouteId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  navigatorRouteIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'navigatorRouteId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  navigatorRouteIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'navigatorRouteId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  navigatorRouteIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'navigatorRouteId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> navigatorRouteIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'navigatorRouteId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  navigatorRouteIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'navigatorRouteId', value: ''),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  navigatorRouteIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'navigatorRouteId', value: ''),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  navigatorTargetTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'navigatorTargetType'),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  navigatorTargetTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'navigatorTargetType'),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  navigatorTargetTypeEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'navigatorTargetType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  navigatorTargetTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'navigatorTargetType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  navigatorTargetTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'navigatorTargetType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  navigatorTargetTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'navigatorTargetType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  navigatorTargetTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'navigatorTargetType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  navigatorTargetTypeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'navigatorTargetType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  navigatorTargetTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'navigatorTargetType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  navigatorTargetTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'navigatorTargetType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  navigatorTargetTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'navigatorTargetType', value: ''),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  navigatorTargetTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'navigatorTargetType',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  navigatorTargetValueIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'navigatorTargetValue'),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  navigatorTargetValueIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'navigatorTargetValue'),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  navigatorTargetValueEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'navigatorTargetValue',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  navigatorTargetValueGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'navigatorTargetValue',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  navigatorTargetValueLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'navigatorTargetValue',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  navigatorTargetValueBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'navigatorTargetValue',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  navigatorVoiceEnabledIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'navigatorVoiceEnabled'),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  navigatorVoiceEnabledIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'navigatorVoiceEnabled'),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  navigatorVoiceEnabledEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'navigatorVoiceEnabled',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'note'),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> noteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'note'),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> noteEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> noteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> noteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> noteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'note',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> noteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> noteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> noteContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> noteMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'note',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'note', value: ''),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'note', value: ''),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> startedAtEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'startedAt', value: value),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> startedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'startedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> startedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'startedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> startedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'startedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> tagsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> tagsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> tagsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> tagsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'tags',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> tagsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> tagsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> tagsElementContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> tagsElementMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'tags',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> tagsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'tags', value: ''),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition>
  tagsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'tags', value: ''),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> tagsLengthEqualTo(
    int length,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tags', length, true, length, true);
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> tagsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tags', 0, true, 0, true);
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> tagsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tags', 0, false, 999999, true);
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> tagsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tags', 0, true, length, include);
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> tagsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tags', length, include, 999999, true);
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> tagsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> typeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> typeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> typeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> typeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'type',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> typeContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> typeMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'type',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'type', value: ''),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'type', value: ''),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> updatedAtEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<Session, Session, QAfterFilterCondition> updatedAtGreaterThan(
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

  QueryBuilder<Session, Session, QAfterFilterCondition> updatedAtLessThan(
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

  QueryBuilder<Session, Session, QAfterFilterCondition> updatedAtBetween(
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
}

extension SessionQueryObject
    on QueryBuilder<Session, Session, QFilterCondition> {}

extension SessionQueryLinks
    on QueryBuilder<Session, Session, QFilterCondition> {}

extension SessionQuerySortBy on QueryBuilder<Session, Session, QSortBy> {
  QueryBuilder<Session, Session, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> sortByDeviceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> sortByDeviceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> sortByEndedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endedAt', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> sortByEndedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endedAt', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> sortByLocalDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localDate', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> sortByLocalDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localDate', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> sortByNavigatorRouteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'navigatorRouteId', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> sortByNavigatorRouteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'navigatorRouteId', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> sortByNavigatorTargetType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'navigatorTargetType', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> sortByNavigatorTargetTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'navigatorTargetType', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> sortByNavigatorTargetValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'navigatorTargetValue', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy>
  sortByNavigatorTargetValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'navigatorTargetValue', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> sortByNavigatorVoiceEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'navigatorVoiceEnabled', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy>
  sortByNavigatorVoiceEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'navigatorVoiceEnabled', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> sortByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> sortByStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension SessionQuerySortThenBy
    on QueryBuilder<Session, Session, QSortThenBy> {
  QueryBuilder<Session, Session, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenByDeviceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenByDeviceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenByEndedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endedAt', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenByEndedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endedAt', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenByLocalDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localDate', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenByLocalDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localDate', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenByNavigatorRouteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'navigatorRouteId', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenByNavigatorRouteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'navigatorRouteId', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenByNavigatorTargetType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'navigatorTargetType', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenByNavigatorTargetTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'navigatorTargetType', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenByNavigatorTargetValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'navigatorTargetValue', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy>
  thenByNavigatorTargetValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'navigatorTargetValue', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenByNavigatorVoiceEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'navigatorVoiceEnabled', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy>
  thenByNavigatorVoiceEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'navigatorVoiceEnabled', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenByStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<Session, Session, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension SessionQueryWhereDistinct
    on QueryBuilder<Session, Session, QDistinct> {
  QueryBuilder<Session, Session, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<Session, Session, QDistinct> distinctByDeviceId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deviceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Session, Session, QDistinct> distinctByEndedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endedAt');
    });
  }

  QueryBuilder<Session, Session, QDistinct> distinctByLocalDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localDate');
    });
  }

  QueryBuilder<Session, Session, QDistinct> distinctByNavigatorRouteId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'navigatorRouteId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Session, Session, QDistinct> distinctByNavigatorTargetType({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'navigatorTargetType',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Session, Session, QDistinct> distinctByNavigatorTargetValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'navigatorTargetValue');
    });
  }

  QueryBuilder<Session, Session, QDistinct> distinctByNavigatorVoiceEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'navigatorVoiceEnabled');
    });
  }

  QueryBuilder<Session, Session, QDistinct> distinctByNote({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Session, Session, QDistinct> distinctByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startedAt');
    });
  }

  QueryBuilder<Session, Session, QDistinct> distinctByTags() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tags');
    });
  }

  QueryBuilder<Session, Session, QDistinct> distinctByType({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Session, Session, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension SessionQueryProperty
    on QueryBuilder<Session, Session, QQueryProperty> {
  QueryBuilder<Session, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Session, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<Session, String, QQueryOperations> deviceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deviceId');
    });
  }

  QueryBuilder<Session, DateTime?, QQueryOperations> endedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endedAt');
    });
  }

  QueryBuilder<Session, DateTime, QQueryOperations> localDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localDate');
    });
  }

  QueryBuilder<Session, String?, QQueryOperations> navigatorRouteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'navigatorRouteId');
    });
  }

  QueryBuilder<Session, String?, QQueryOperations>
  navigatorTargetTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'navigatorTargetType');
    });
  }

  QueryBuilder<Session, double?, QQueryOperations>
  navigatorTargetValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'navigatorTargetValue');
    });
  }

  QueryBuilder<Session, bool?, QQueryOperations>
  navigatorVoiceEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'navigatorVoiceEnabled');
    });
  }

  QueryBuilder<Session, String?, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<Session, DateTime, QQueryOperations> startedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startedAt');
    });
  }

  QueryBuilder<Session, List<String>, QQueryOperations> tagsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tags');
    });
  }

  QueryBuilder<Session, String, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<Session, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
