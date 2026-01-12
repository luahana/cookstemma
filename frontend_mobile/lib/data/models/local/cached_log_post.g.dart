// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_log_post.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCachedLogPostCollection on Isar {
  IsarCollection<CachedLogPost> get cachedLogPosts => this.collection();
}

const CachedLogPostSchema = CollectionSchema(
  name: r'CachedLogPost',
  id: -5819253122177324205,
  properties: {
    r'cachedAt': PropertySchema(
      id: 0,
      name: r'cachedAt',
      type: IsarType.dateTime,
    ),
    r'jsonData': PropertySchema(
      id: 1,
      name: r'jsonData',
      type: IsarType.string,
    ),
    r'publicId': PropertySchema(
      id: 2,
      name: r'publicId',
      type: IsarType.string,
    )
  },
  estimateSize: _cachedLogPostEstimateSize,
  serialize: _cachedLogPostSerialize,
  deserialize: _cachedLogPostDeserialize,
  deserializeProp: _cachedLogPostDeserializeProp,
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
  getId: _cachedLogPostGetId,
  getLinks: _cachedLogPostGetLinks,
  attach: _cachedLogPostAttach,
  version: '3.1.0+1',
);

int _cachedLogPostEstimateSize(
  CachedLogPost object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.jsonData.length * 3;
  bytesCount += 3 + object.publicId.length * 3;
  return bytesCount;
}

void _cachedLogPostSerialize(
  CachedLogPost object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.cachedAt);
  writer.writeString(offsets[1], object.jsonData);
  writer.writeString(offsets[2], object.publicId);
}

CachedLogPost _cachedLogPostDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedLogPost();
  object.cachedAt = reader.readDateTime(offsets[0]);
  object.id = id;
  object.jsonData = reader.readString(offsets[1]);
  object.publicId = reader.readString(offsets[2]);
  return object;
}

P _cachedLogPostDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cachedLogPostGetId(CachedLogPost object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cachedLogPostGetLinks(CachedLogPost object) {
  return [];
}

void _cachedLogPostAttach(
    IsarCollection<dynamic> col, Id id, CachedLogPost object) {
  object.id = id;
}

extension CachedLogPostByIndex on IsarCollection<CachedLogPost> {
  Future<CachedLogPost?> getByPublicId(String publicId) {
    return getByIndex(r'publicId', [publicId]);
  }

  CachedLogPost? getByPublicIdSync(String publicId) {
    return getByIndexSync(r'publicId', [publicId]);
  }

  Future<bool> deleteByPublicId(String publicId) {
    return deleteByIndex(r'publicId', [publicId]);
  }

  bool deleteByPublicIdSync(String publicId) {
    return deleteByIndexSync(r'publicId', [publicId]);
  }

  Future<List<CachedLogPost?>> getAllByPublicId(List<String> publicIdValues) {
    final values = publicIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'publicId', values);
  }

  List<CachedLogPost?> getAllByPublicIdSync(List<String> publicIdValues) {
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

  Future<Id> putByPublicId(CachedLogPost object) {
    return putByIndex(r'publicId', object);
  }

  Id putByPublicIdSync(CachedLogPost object, {bool saveLinks = true}) {
    return putByIndexSync(r'publicId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByPublicId(List<CachedLogPost> objects) {
    return putAllByIndex(r'publicId', objects);
  }

  List<Id> putAllByPublicIdSync(List<CachedLogPost> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'publicId', objects, saveLinks: saveLinks);
  }
}

extension CachedLogPostQueryWhereSort
    on QueryBuilder<CachedLogPost, CachedLogPost, QWhere> {
  QueryBuilder<CachedLogPost, CachedLogPost, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CachedLogPostQueryWhere
    on QueryBuilder<CachedLogPost, CachedLogPost, QWhereClause> {
  QueryBuilder<CachedLogPost, CachedLogPost, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterWhereClause> idBetween(
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

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterWhereClause> publicIdEqualTo(
      String publicId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'publicId',
        value: [publicId],
      ));
    });
  }

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterWhereClause>
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

extension CachedLogPostQueryFilter
    on QueryBuilder<CachedLogPost, CachedLogPost, QFilterCondition> {
  QueryBuilder<CachedLogPost, CachedLogPost, QAfterFilterCondition>
      cachedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterFilterCondition>
      cachedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterFilterCondition>
      cachedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterFilterCondition>
      cachedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cachedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterFilterCondition>
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

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterFilterCondition> idBetween(
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

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterFilterCondition>
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

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterFilterCondition>
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

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterFilterCondition>
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

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterFilterCondition>
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

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterFilterCondition>
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

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterFilterCondition>
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

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterFilterCondition>
      jsonDataContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'jsonData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterFilterCondition>
      jsonDataMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'jsonData',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterFilterCondition>
      jsonDataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'jsonData',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterFilterCondition>
      jsonDataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'jsonData',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterFilterCondition>
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

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterFilterCondition>
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

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterFilterCondition>
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

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterFilterCondition>
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

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterFilterCondition>
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

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterFilterCondition>
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

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterFilterCondition>
      publicIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'publicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterFilterCondition>
      publicIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'publicId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterFilterCondition>
      publicIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'publicId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterFilterCondition>
      publicIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'publicId',
        value: '',
      ));
    });
  }
}

extension CachedLogPostQueryObject
    on QueryBuilder<CachedLogPost, CachedLogPost, QFilterCondition> {}

extension CachedLogPostQueryLinks
    on QueryBuilder<CachedLogPost, CachedLogPost, QFilterCondition> {}

extension CachedLogPostQuerySortBy
    on QueryBuilder<CachedLogPost, CachedLogPost, QSortBy> {
  QueryBuilder<CachedLogPost, CachedLogPost, QAfterSortBy> sortByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterSortBy>
      sortByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterSortBy> sortByJsonData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jsonData', Sort.asc);
    });
  }

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterSortBy>
      sortByJsonDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jsonData', Sort.desc);
    });
  }

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterSortBy> sortByPublicId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'publicId', Sort.asc);
    });
  }

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterSortBy>
      sortByPublicIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'publicId', Sort.desc);
    });
  }
}

extension CachedLogPostQuerySortThenBy
    on QueryBuilder<CachedLogPost, CachedLogPost, QSortThenBy> {
  QueryBuilder<CachedLogPost, CachedLogPost, QAfterSortBy> thenByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterSortBy>
      thenByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterSortBy> thenByJsonData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jsonData', Sort.asc);
    });
  }

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterSortBy>
      thenByJsonDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jsonData', Sort.desc);
    });
  }

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterSortBy> thenByPublicId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'publicId', Sort.asc);
    });
  }

  QueryBuilder<CachedLogPost, CachedLogPost, QAfterSortBy>
      thenByPublicIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'publicId', Sort.desc);
    });
  }
}

extension CachedLogPostQueryWhereDistinct
    on QueryBuilder<CachedLogPost, CachedLogPost, QDistinct> {
  QueryBuilder<CachedLogPost, CachedLogPost, QDistinct> distinctByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedAt');
    });
  }

  QueryBuilder<CachedLogPost, CachedLogPost, QDistinct> distinctByJsonData(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'jsonData', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedLogPost, CachedLogPost, QDistinct> distinctByPublicId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'publicId', caseSensitive: caseSensitive);
    });
  }
}

extension CachedLogPostQueryProperty
    on QueryBuilder<CachedLogPost, CachedLogPost, QQueryProperty> {
  QueryBuilder<CachedLogPost, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CachedLogPost, DateTime, QQueryOperations> cachedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedAt');
    });
  }

  QueryBuilder<CachedLogPost, String, QQueryOperations> jsonDataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'jsonData');
    });
  }

  QueryBuilder<CachedLogPost, String, QQueryOperations> publicIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'publicId');
    });
  }
}
