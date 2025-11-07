// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'life_buddy_state_local.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLifeBuddyStateLocalCollection on Isar {
  IsarCollection<LifeBuddyStateLocal> get lifeBuddyStateLocals =>
      this.collection();
}

const LifeBuddyStateLocalSchema = CollectionSchema(
  name: r'LifeBuddyStateLocal',
  id: 5436243265645747406,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'equippedSlots': PropertySchema(
      id: 1,
      name: r'equippedSlots',
      type: IsarType.objectList,

      target: r'EquippedSlot',
    ),
    r'experience': PropertySchema(
      id: 2,
      name: r'experience',
      type: IsarType.double,
    ),
    r'level': PropertySchema(id: 3, name: r'level', type: IsarType.long),
    r'mood': PropertySchema(id: 4, name: r'mood', type: IsarType.string),
    r'updatedAt': PropertySchema(
      id: 5,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _lifeBuddyStateLocalEstimateSize,
  serialize: _lifeBuddyStateLocalSerialize,
  deserialize: _lifeBuddyStateLocalDeserialize,
  deserializeProp: _lifeBuddyStateLocalDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {r'EquippedSlot': EquippedSlotSchema},

  getId: _lifeBuddyStateLocalGetId,
  getLinks: _lifeBuddyStateLocalGetLinks,
  attach: _lifeBuddyStateLocalAttach,
  version: '3.1.0+1',
);

int _lifeBuddyStateLocalEstimateSize(
  LifeBuddyStateLocal object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.equippedSlots.length * 3;
  {
    final offsets = allOffsets[EquippedSlot]!;
    for (var i = 0; i < object.equippedSlots.length; i++) {
      final value = object.equippedSlots[i];
      bytesCount += EquippedSlotSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  bytesCount += 3 + object.mood.length * 3;
  return bytesCount;
}

void _lifeBuddyStateLocalSerialize(
  LifeBuddyStateLocal object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeObjectList<EquippedSlot>(
    offsets[1],
    allOffsets,
    EquippedSlotSchema.serialize,
    object.equippedSlots,
  );
  writer.writeDouble(offsets[2], object.experience);
  writer.writeLong(offsets[3], object.level);
  writer.writeString(offsets[4], object.mood);
  writer.writeDateTime(offsets[5], object.updatedAt);
}

LifeBuddyStateLocal _lifeBuddyStateLocalDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LifeBuddyStateLocal();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.equippedSlots =
      reader.readObjectList<EquippedSlot>(
        offsets[1],
        EquippedSlotSchema.deserialize,
        allOffsets,
        EquippedSlot(),
      ) ??
      [];
  object.experience = reader.readDouble(offsets[2]);
  object.id = id;
  object.level = reader.readLong(offsets[3]);
  object.mood = reader.readString(offsets[4]);
  object.updatedAt = reader.readDateTime(offsets[5]);
  return object;
}

P _lifeBuddyStateLocalDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readObjectList<EquippedSlot>(
                offset,
                EquippedSlotSchema.deserialize,
                allOffsets,
                EquippedSlot(),
              ) ??
              [])
          as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _lifeBuddyStateLocalGetId(LifeBuddyStateLocal object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _lifeBuddyStateLocalGetLinks(
  LifeBuddyStateLocal object,
) {
  return [];
}

void _lifeBuddyStateLocalAttach(
  IsarCollection<dynamic> col,
  Id id,
  LifeBuddyStateLocal object,
) {
  object.id = id;
}

extension LifeBuddyStateLocalQueryWhereSort
    on QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QWhere> {
  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LifeBuddyStateLocalQueryWhere
    on QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QWhereClause> {
  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterWhereClause>
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

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterWhereClause>
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
}

extension LifeBuddyStateLocalQueryFilter
    on
        QueryBuilder<
          LifeBuddyStateLocal,
          LifeBuddyStateLocal,
          QFilterCondition
        > {
  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  createdAtGreaterThan(DateTime value, {bool include = false}) {
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

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  createdAtLessThan(DateTime value, {bool include = false}) {
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

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  createdAtBetween(
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

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  equippedSlotsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'equippedSlots', length, true, length, true);
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  equippedSlotsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'equippedSlots', 0, true, 0, true);
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  equippedSlotsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'equippedSlots', 0, false, 999999, true);
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  equippedSlotsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'equippedSlots', 0, true, length, include);
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  equippedSlotsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'equippedSlots', length, include, 999999, true);
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  equippedSlotsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'equippedSlots',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  experienceEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'experience',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  experienceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'experience',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  experienceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'experience',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  experienceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'experience',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
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

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
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

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
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

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  levelEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'level', value: value),
      );
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  levelGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'level',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  levelLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'level',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  levelBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'level',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  moodEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'mood',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  moodGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'mood',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  moodLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'mood',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  moodBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'mood',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  moodStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'mood',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  moodEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'mood',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  moodContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'mood',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  moodMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'mood',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  moodIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'mood', value: ''),
      );
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  moodIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'mood', value: ''),
      );
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
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

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
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

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
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
}

extension LifeBuddyStateLocalQueryObject
    on
        QueryBuilder<
          LifeBuddyStateLocal,
          LifeBuddyStateLocal,
          QFilterCondition
        > {
  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterFilterCondition>
  equippedSlotsElement(FilterQuery<EquippedSlot> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'equippedSlots');
    });
  }
}

extension LifeBuddyStateLocalQueryLinks
    on
        QueryBuilder<
          LifeBuddyStateLocal,
          LifeBuddyStateLocal,
          QFilterCondition
        > {}

extension LifeBuddyStateLocalQuerySortBy
    on QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QSortBy> {
  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterSortBy>
  sortByExperience() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'experience', Sort.asc);
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterSortBy>
  sortByExperienceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'experience', Sort.desc);
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterSortBy>
  sortByLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'level', Sort.asc);
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterSortBy>
  sortByLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'level', Sort.desc);
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterSortBy>
  sortByMood() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mood', Sort.asc);
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterSortBy>
  sortByMoodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mood', Sort.desc);
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterSortBy>
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension LifeBuddyStateLocalQuerySortThenBy
    on QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QSortThenBy> {
  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterSortBy>
  thenByExperience() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'experience', Sort.asc);
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterSortBy>
  thenByExperienceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'experience', Sort.desc);
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterSortBy>
  thenByLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'level', Sort.asc);
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterSortBy>
  thenByLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'level', Sort.desc);
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterSortBy>
  thenByMood() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mood', Sort.asc);
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterSortBy>
  thenByMoodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mood', Sort.desc);
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterSortBy>
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension LifeBuddyStateLocalQueryWhereDistinct
    on QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QDistinct> {
  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QDistinct>
  distinctByExperience() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'experience');
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QDistinct>
  distinctByLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'level');
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QDistinct>
  distinctByMood({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mood', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension LifeBuddyStateLocalQueryProperty
    on QueryBuilder<LifeBuddyStateLocal, LifeBuddyStateLocal, QQueryProperty> {
  QueryBuilder<LifeBuddyStateLocal, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LifeBuddyStateLocal, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<LifeBuddyStateLocal, List<EquippedSlot>, QQueryOperations>
  equippedSlotsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'equippedSlots');
    });
  }

  QueryBuilder<LifeBuddyStateLocal, double, QQueryOperations>
  experienceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'experience');
    });
  }

  QueryBuilder<LifeBuddyStateLocal, int, QQueryOperations> levelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'level');
    });
  }

  QueryBuilder<LifeBuddyStateLocal, String, QQueryOperations> moodProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mood');
    });
  }

  QueryBuilder<LifeBuddyStateLocal, DateTime, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const EquippedSlotSchema = Schema(
  name: r'EquippedSlot',
  id: 4178327138473354450,
  properties: {
    r'itemId': PropertySchema(id: 0, name: r'itemId', type: IsarType.string),
    r'slot': PropertySchema(id: 1, name: r'slot', type: IsarType.string),
  },

  estimateSize: _equippedSlotEstimateSize,
  serialize: _equippedSlotSerialize,
  deserialize: _equippedSlotDeserialize,
  deserializeProp: _equippedSlotDeserializeProp,
);

int _equippedSlotEstimateSize(
  EquippedSlot object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.itemId.length * 3;
  bytesCount += 3 + object.slot.length * 3;
  return bytesCount;
}

void _equippedSlotSerialize(
  EquippedSlot object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.itemId);
  writer.writeString(offsets[1], object.slot);
}

EquippedSlot _equippedSlotDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = EquippedSlot();
  object.itemId = reader.readString(offsets[0]);
  object.slot = reader.readString(offsets[1]);
  return object;
}

P _equippedSlotDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension EquippedSlotQueryFilter
    on QueryBuilder<EquippedSlot, EquippedSlot, QFilterCondition> {
  QueryBuilder<EquippedSlot, EquippedSlot, QAfterFilterCondition> itemIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'itemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EquippedSlot, EquippedSlot, QAfterFilterCondition>
  itemIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'itemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EquippedSlot, EquippedSlot, QAfterFilterCondition>
  itemIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'itemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EquippedSlot, EquippedSlot, QAfterFilterCondition> itemIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'itemId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EquippedSlot, EquippedSlot, QAfterFilterCondition>
  itemIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'itemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EquippedSlot, EquippedSlot, QAfterFilterCondition>
  itemIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'itemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EquippedSlot, EquippedSlot, QAfterFilterCondition>
  itemIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'itemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EquippedSlot, EquippedSlot, QAfterFilterCondition> itemIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'itemId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EquippedSlot, EquippedSlot, QAfterFilterCondition>
  itemIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'itemId', value: ''),
      );
    });
  }

  QueryBuilder<EquippedSlot, EquippedSlot, QAfterFilterCondition>
  itemIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'itemId', value: ''),
      );
    });
  }

  QueryBuilder<EquippedSlot, EquippedSlot, QAfterFilterCondition> slotEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'slot',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EquippedSlot, EquippedSlot, QAfterFilterCondition>
  slotGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'slot',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EquippedSlot, EquippedSlot, QAfterFilterCondition> slotLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'slot',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EquippedSlot, EquippedSlot, QAfterFilterCondition> slotBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'slot',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EquippedSlot, EquippedSlot, QAfterFilterCondition>
  slotStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'slot',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EquippedSlot, EquippedSlot, QAfterFilterCondition> slotEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'slot',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EquippedSlot, EquippedSlot, QAfterFilterCondition> slotContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'slot',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EquippedSlot, EquippedSlot, QAfterFilterCondition> slotMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'slot',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EquippedSlot, EquippedSlot, QAfterFilterCondition>
  slotIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'slot', value: ''),
      );
    });
  }

  QueryBuilder<EquippedSlot, EquippedSlot, QAfterFilterCondition>
  slotIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'slot', value: ''),
      );
    });
  }
}

extension EquippedSlotQueryObject
    on QueryBuilder<EquippedSlot, EquippedSlot, QFilterCondition> {}
