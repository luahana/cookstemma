// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_stats_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetProgressStatsEntryCollection on Isar {
  IsarCollection<ProgressStatsEntry> get progressStatsEntrys =>
      this.collection();
}

const ProgressStatsEntrySchema = CollectionSchema(
  name: r'ProgressStatsEntry',
  id: 1580388974921532789,
  properties: {
    r'currentStreak': PropertySchema(
      id: 0,
      name: r'currentStreak',
      type: IsarType.long,
    ),
    r'failedCount': PropertySchema(
      id: 1,
      name: r'failedCount',
      type: IsarType.long,
    ),
    r'lastLogDate': PropertySchema(
      id: 2,
      name: r'lastLogDate',
      type: IsarType.dateTime,
    ),
    r'longestStreak': PropertySchema(
      id: 3,
      name: r'longestStreak',
      type: IsarType.long,
    ),
    r'partialCount': PropertySchema(
      id: 4,
      name: r'partialCount',
      type: IsarType.long,
    ),
    r'statsKey': PropertySchema(
      id: 5,
      name: r'statsKey',
      type: IsarType.string,
    ),
    r'successCount': PropertySchema(
      id: 6,
      name: r'successCount',
      type: IsarType.long,
    )
  },
  estimateSize: _progressStatsEntryEstimateSize,
  serialize: _progressStatsEntrySerialize,
  deserialize: _progressStatsEntryDeserialize,
  deserializeProp: _progressStatsEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'statsKey': IndexSchema(
      id: 6761511032695272419,
      name: r'statsKey',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'statsKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _progressStatsEntryGetId,
  getLinks: _progressStatsEntryGetLinks,
  attach: _progressStatsEntryAttach,
  version: '3.1.0+1',
);

int _progressStatsEntryEstimateSize(
  ProgressStatsEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.statsKey.length * 3;
  return bytesCount;
}

void _progressStatsEntrySerialize(
  ProgressStatsEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.currentStreak);
  writer.writeLong(offsets[1], object.failedCount);
  writer.writeDateTime(offsets[2], object.lastLogDate);
  writer.writeLong(offsets[3], object.longestStreak);
  writer.writeLong(offsets[4], object.partialCount);
  writer.writeString(offsets[5], object.statsKey);
  writer.writeLong(offsets[6], object.successCount);
}

ProgressStatsEntry _progressStatsEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ProgressStatsEntry();
  object.currentStreak = reader.readLong(offsets[0]);
  object.failedCount = reader.readLong(offsets[1]);
  object.id = id;
  object.lastLogDate = reader.readDateTimeOrNull(offsets[2]);
  object.longestStreak = reader.readLong(offsets[3]);
  object.partialCount = reader.readLong(offsets[4]);
  object.statsKey = reader.readString(offsets[5]);
  object.successCount = reader.readLong(offsets[6]);
  return object;
}

P _progressStatsEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _progressStatsEntryGetId(ProgressStatsEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _progressStatsEntryGetLinks(
    ProgressStatsEntry object) {
  return [];
}

void _progressStatsEntryAttach(
    IsarCollection<dynamic> col, Id id, ProgressStatsEntry object) {
  object.id = id;
}

extension ProgressStatsEntryByIndex on IsarCollection<ProgressStatsEntry> {
  Future<ProgressStatsEntry?> getByStatsKey(String statsKey) {
    return getByIndex(r'statsKey', [statsKey]);
  }

  ProgressStatsEntry? getByStatsKeySync(String statsKey) {
    return getByIndexSync(r'statsKey', [statsKey]);
  }

  Future<bool> deleteByStatsKey(String statsKey) {
    return deleteByIndex(r'statsKey', [statsKey]);
  }

  bool deleteByStatsKeySync(String statsKey) {
    return deleteByIndexSync(r'statsKey', [statsKey]);
  }

  Future<List<ProgressStatsEntry?>> getAllByStatsKey(
      List<String> statsKeyValues) {
    final values = statsKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'statsKey', values);
  }

  List<ProgressStatsEntry?> getAllByStatsKeySync(List<String> statsKeyValues) {
    final values = statsKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'statsKey', values);
  }

  Future<int> deleteAllByStatsKey(List<String> statsKeyValues) {
    final values = statsKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'statsKey', values);
  }

  int deleteAllByStatsKeySync(List<String> statsKeyValues) {
    final values = statsKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'statsKey', values);
  }

  Future<Id> putByStatsKey(ProgressStatsEntry object) {
    return putByIndex(r'statsKey', object);
  }

  Id putByStatsKeySync(ProgressStatsEntry object, {bool saveLinks = true}) {
    return putByIndexSync(r'statsKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByStatsKey(List<ProgressStatsEntry> objects) {
    return putAllByIndex(r'statsKey', objects);
  }

  List<Id> putAllByStatsKeySync(List<ProgressStatsEntry> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'statsKey', objects, saveLinks: saveLinks);
  }
}

extension ProgressStatsEntryQueryWhereSort
    on QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QWhere> {
  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ProgressStatsEntryQueryWhere
    on QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QWhereClause> {
  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterWhereClause>
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

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterWhereClause>
      statsKeyEqualTo(String statsKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'statsKey',
        value: [statsKey],
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterWhereClause>
      statsKeyNotEqualTo(String statsKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'statsKey',
              lower: [],
              upper: [statsKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'statsKey',
              lower: [statsKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'statsKey',
              lower: [statsKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'statsKey',
              lower: [],
              upper: [statsKey],
              includeUpper: false,
            ));
      }
    });
  }
}

extension ProgressStatsEntryQueryFilter
    on QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QFilterCondition> {
  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      currentStreakEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      currentStreakGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      currentStreakLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      currentStreakBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentStreak',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      failedCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'failedCount',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      failedCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'failedCount',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      failedCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'failedCount',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      failedCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'failedCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      lastLogDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastLogDate',
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      lastLogDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastLogDate',
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      lastLogDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastLogDate',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      lastLogDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastLogDate',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      lastLogDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastLogDate',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      lastLogDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastLogDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      longestStreakEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'longestStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      longestStreakGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'longestStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      longestStreakLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'longestStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      longestStreakBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'longestStreak',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      partialCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'partialCount',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      partialCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'partialCount',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      partialCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'partialCount',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      partialCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'partialCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      statsKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'statsKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      statsKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'statsKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      statsKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'statsKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      statsKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'statsKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      statsKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'statsKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      statsKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'statsKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      statsKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'statsKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      statsKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'statsKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      statsKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'statsKey',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      statsKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'statsKey',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      successCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'successCount',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      successCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'successCount',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      successCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'successCount',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterFilterCondition>
      successCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'successCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ProgressStatsEntryQueryObject
    on QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QFilterCondition> {}

extension ProgressStatsEntryQueryLinks
    on QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QFilterCondition> {}

extension ProgressStatsEntryQuerySortBy
    on QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QSortBy> {
  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterSortBy>
      sortByCurrentStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.asc);
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterSortBy>
      sortByCurrentStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.desc);
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterSortBy>
      sortByFailedCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failedCount', Sort.asc);
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterSortBy>
      sortByFailedCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failedCount', Sort.desc);
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterSortBy>
      sortByLastLogDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastLogDate', Sort.asc);
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterSortBy>
      sortByLastLogDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastLogDate', Sort.desc);
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterSortBy>
      sortByLongestStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.asc);
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterSortBy>
      sortByLongestStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.desc);
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterSortBy>
      sortByPartialCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partialCount', Sort.asc);
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterSortBy>
      sortByPartialCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partialCount', Sort.desc);
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterSortBy>
      sortByStatsKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statsKey', Sort.asc);
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterSortBy>
      sortByStatsKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statsKey', Sort.desc);
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterSortBy>
      sortBySuccessCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'successCount', Sort.asc);
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterSortBy>
      sortBySuccessCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'successCount', Sort.desc);
    });
  }
}

extension ProgressStatsEntryQuerySortThenBy
    on QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QSortThenBy> {
  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterSortBy>
      thenByCurrentStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.asc);
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterSortBy>
      thenByCurrentStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.desc);
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterSortBy>
      thenByFailedCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failedCount', Sort.asc);
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterSortBy>
      thenByFailedCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failedCount', Sort.desc);
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterSortBy>
      thenByLastLogDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastLogDate', Sort.asc);
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterSortBy>
      thenByLastLogDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastLogDate', Sort.desc);
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterSortBy>
      thenByLongestStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.asc);
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterSortBy>
      thenByLongestStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.desc);
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterSortBy>
      thenByPartialCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partialCount', Sort.asc);
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterSortBy>
      thenByPartialCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partialCount', Sort.desc);
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterSortBy>
      thenByStatsKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statsKey', Sort.asc);
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterSortBy>
      thenByStatsKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statsKey', Sort.desc);
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterSortBy>
      thenBySuccessCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'successCount', Sort.asc);
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QAfterSortBy>
      thenBySuccessCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'successCount', Sort.desc);
    });
  }
}

extension ProgressStatsEntryQueryWhereDistinct
    on QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QDistinct> {
  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QDistinct>
      distinctByCurrentStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentStreak');
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QDistinct>
      distinctByFailedCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'failedCount');
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QDistinct>
      distinctByLastLogDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastLogDate');
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QDistinct>
      distinctByLongestStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'longestStreak');
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QDistinct>
      distinctByPartialCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'partialCount');
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QDistinct>
      distinctByStatsKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'statsKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QDistinct>
      distinctBySuccessCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'successCount');
    });
  }
}

extension ProgressStatsEntryQueryProperty
    on QueryBuilder<ProgressStatsEntry, ProgressStatsEntry, QQueryProperty> {
  QueryBuilder<ProgressStatsEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ProgressStatsEntry, int, QQueryOperations>
      currentStreakProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentStreak');
    });
  }

  QueryBuilder<ProgressStatsEntry, int, QQueryOperations>
      failedCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'failedCount');
    });
  }

  QueryBuilder<ProgressStatsEntry, DateTime?, QQueryOperations>
      lastLogDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastLogDate');
    });
  }

  QueryBuilder<ProgressStatsEntry, int, QQueryOperations>
      longestStreakProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'longestStreak');
    });
  }

  QueryBuilder<ProgressStatsEntry, int, QQueryOperations>
      partialCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'partialCount');
    });
  }

  QueryBuilder<ProgressStatsEntry, String, QQueryOperations>
      statsKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'statsKey');
    });
  }

  QueryBuilder<ProgressStatsEntry, int, QQueryOperations>
      successCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'successCount');
    });
  }
}
