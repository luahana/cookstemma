// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recently_viewed_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRecentlyViewedEntryCollection on Isar {
  IsarCollection<RecentlyViewedEntry> get recentlyViewedEntrys =>
      this.collection();
}

const RecentlyViewedEntrySchema = CollectionSchema(
  name: r'RecentlyViewedEntry',
  id: 6647797435228121781,
  properties: {
    r'jsonData': PropertySchema(
      id: 0,
      name: r'jsonData',
      type: IsarType.string,
    ),
    r'publicId': PropertySchema(
      id: 1,
      name: r'publicId',
      type: IsarType.string,
    ),
    r'viewedAt': PropertySchema(
      id: 2,
      name: r'viewedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _recentlyViewedEntryEstimateSize,
  serialize: _recentlyViewedEntrySerialize,
  deserialize: _recentlyViewedEntryDeserialize,
  deserializeProp: _recentlyViewedEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'publicId': IndexSchema(
      id: 779961479559886054,
      name: r'publicId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'publicId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _recentlyViewedEntryGetId,
  getLinks: _recentlyViewedEntryGetLinks,
  attach: _recentlyViewedEntryAttach,
  version: '3.1.0+1',
);

int _recentlyViewedEntryEstimateSize(
  RecentlyViewedEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.jsonData.length * 3;
  bytesCount += 3 + object.publicId.length * 3;
  return bytesCount;
}

void _recentlyViewedEntrySerialize(
  RecentlyViewedEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.jsonData);
  writer.writeString(offsets[1], object.publicId);
  writer.writeDateTime(offsets[2], object.viewedAt);
}

RecentlyViewedEntry _recentlyViewedEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RecentlyViewedEntry();
  object.id = id;
  object.jsonData = reader.readString(offsets[0]);
  object.publicId = reader.readString(offsets[1]);
  object.viewedAt = reader.readDateTime(offsets[2]);
  return object;
}

P _recentlyViewedEntryDeserializeProp<P>(
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
    case 2:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _recentlyViewedEntryGetId(RecentlyViewedEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _recentlyViewedEntryGetLinks(
    RecentlyViewedEntry object) {
  return [];
}

void _recentlyViewedEntryAttach(
    IsarCollection<dynamic> col, Id id, RecentlyViewedEntry object) {
  object.id = id;
}

extension RecentlyViewedEntryByIndex on IsarCollection<RecentlyViewedEntry> {
  Future<RecentlyViewedEntry?> getByPublicId(String publicId) {
    return getByIndex(r'publicId', [publicId]);
  }

  RecentlyViewedEntry? getByPublicIdSync(String publicId) {
    return getByIndexSync(r'publicId', [publicId]);
  }

  Future<bool> deleteByPublicId(String publicId) {
    return deleteByIndex(r'publicId', [publicId]);
  }

  bool deleteByPublicIdSync(String publicId) {
    return deleteByIndexSync(r'publicId', [publicId]);
  }

  Future<List<RecentlyViewedEntry?>> getAllByPublicId(
      List<String> publicIdValues) {
    final values = publicIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'publicId', values);
  }

  List<RecentlyViewedEntry?> getAllByPublicIdSync(List<String> publicIdValues) {
    final values = publicIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'publicId', values);
  }

  Future<int> deleteAllByPublicId(List<String> publicIdValues) {
    final values = publicIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'publicId', values);
  }

  int deleteAllByPublicIdSync(List<String> publicIdValues) {
    final values = publicIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'publicId', values);
  }

  Future<Id> putByPublicId(RecentlyViewedEntry object) {
    return putByIndex(r'publicId', object);
  }

  Id putByPublicIdSync(RecentlyViewedEntry object, {bool saveLinks = true}) {
    return putByIndexSync(r'publicId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByPublicId(List<RecentlyViewedEntry> objects) {
    return putAllByIndex(r'publicId', objects);
  }

  List<Id> putAllByPublicIdSync(List<RecentlyViewedEntry> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'publicId', objects, saveLinks: saveLinks);
  }
}

extension RecentlyViewedEntryQueryWhereSort
    on QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QWhere> {
  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension RecentlyViewedEntryQueryWhere
    on QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QWhereClause> {
  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterWhereClause>
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

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterWhereClause>
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

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterWhereClause>
      publicIdEqualTo(String publicId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'publicId',
        value: [publicId],
      ));
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterWhereClause>
      publicIdNotEqualTo(String publicId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'publicId',
              lower: [],
              upper: [publicId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'publicId',
              lower: [publicId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'publicId',
              lower: [publicId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'publicId',
              lower: [],
              upper: [publicId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension RecentlyViewedEntryQueryFilter on QueryBuilder<RecentlyViewedEntry,
    RecentlyViewedEntry, QFilterCondition> {
  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterFilterCondition>
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

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterFilterCondition>
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

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterFilterCondition>
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

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterFilterCondition>
      jsonDataEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'jsonData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterFilterCondition>
      jsonDataGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'jsonData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterFilterCondition>
      jsonDataLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'jsonData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterFilterCondition>
      jsonDataBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'jsonData',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterFilterCondition>
      jsonDataStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'jsonData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterFilterCondition>
      jsonDataEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'jsonData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterFilterCondition>
      jsonDataContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'jsonData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterFilterCondition>
      jsonDataMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'jsonData',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterFilterCondition>
      jsonDataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'jsonData',
        value: '',
      ));
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterFilterCondition>
      jsonDataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'jsonData',
        value: '',
      ));
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterFilterCondition>
      publicIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'publicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterFilterCondition>
      publicIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'publicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterFilterCondition>
      publicIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'publicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterFilterCondition>
      publicIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'publicId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterFilterCondition>
      publicIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'publicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterFilterCondition>
      publicIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'publicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterFilterCondition>
      publicIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'publicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterFilterCondition>
      publicIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'publicId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterFilterCondition>
      publicIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'publicId',
        value: '',
      ));
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterFilterCondition>
      publicIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'publicId',
        value: '',
      ));
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterFilterCondition>
      viewedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'viewedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterFilterCondition>
      viewedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'viewedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterFilterCondition>
      viewedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'viewedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterFilterCondition>
      viewedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'viewedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension RecentlyViewedEntryQueryObject on QueryBuilder<RecentlyViewedEntry,
    RecentlyViewedEntry, QFilterCondition> {}

extension RecentlyViewedEntryQueryLinks on QueryBuilder<RecentlyViewedEntry,
    RecentlyViewedEntry, QFilterCondition> {}

extension RecentlyViewedEntryQuerySortBy
    on QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QSortBy> {
  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterSortBy>
      sortByJsonData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jsonData', Sort.asc);
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterSortBy>
      sortByJsonDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jsonData', Sort.desc);
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterSortBy>
      sortByPublicId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'publicId', Sort.asc);
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterSortBy>
      sortByPublicIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'publicId', Sort.desc);
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterSortBy>
      sortByViewedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'viewedAt', Sort.asc);
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterSortBy>
      sortByViewedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'viewedAt', Sort.desc);
    });
  }
}

extension RecentlyViewedEntryQuerySortThenBy
    on QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QSortThenBy> {
  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterSortBy>
      thenByJsonData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jsonData', Sort.asc);
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterSortBy>
      thenByJsonDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jsonData', Sort.desc);
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterSortBy>
      thenByPublicId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'publicId', Sort.asc);
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterSortBy>
      thenByPublicIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'publicId', Sort.desc);
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterSortBy>
      thenByViewedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'viewedAt', Sort.asc);
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QAfterSortBy>
      thenByViewedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'viewedAt', Sort.desc);
    });
  }
}

extension RecentlyViewedEntryQueryWhereDistinct
    on QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QDistinct> {
  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QDistinct>
      distinctByJsonData({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'jsonData', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QDistinct>
      distinctByPublicId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'publicId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QDistinct>
      distinctByViewedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'viewedAt');
    });
  }
}

extension RecentlyViewedEntryQueryProperty
    on QueryBuilder<RecentlyViewedEntry, RecentlyViewedEntry, QQueryProperty> {
  QueryBuilder<RecentlyViewedEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<RecentlyViewedEntry, String, QQueryOperations>
      jsonDataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'jsonData');
    });
  }

  QueryBuilder<RecentlyViewedEntry, String, QQueryOperations>
      publicIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'publicId');
    });
  }

  QueryBuilder<RecentlyViewedEntry, DateTime, QQueryOperations>
      viewedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'viewedAt');
    });
  }
}
