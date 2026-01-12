// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_history_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSearchHistoryEntryCollection on Isar {
  IsarCollection<SearchHistoryEntry> get searchHistoryEntrys =>
      this.collection();
}

const SearchHistoryEntrySchema = CollectionSchema(
  name: r'SearchHistoryEntry',
  id: -924937489064202741,
  properties: {
    r'searchType': PropertySchema(
      id: 0,
      name: r'searchType',
      type: IsarType.string,
    ),
    r'searchedAt': PropertySchema(
      id: 1,
      name: r'searchedAt',
      type: IsarType.dateTime,
    ),
    r'term': PropertySchema(
      id: 2,
      name: r'term',
      type: IsarType.string,
    )
  },
  estimateSize: _searchHistoryEntryEstimateSize,
  serialize: _searchHistoryEntrySerialize,
  deserialize: _searchHistoryEntryDeserialize,
  deserializeProp: _searchHistoryEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'searchType': IndexSchema(
      id: -6096003951041207502,
      name: r'searchType',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'searchType',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'term': IndexSchema(
      id: 5114652110782333408,
      name: r'term',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'term',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _searchHistoryEntryGetId,
  getLinks: _searchHistoryEntryGetLinks,
  attach: _searchHistoryEntryAttach,
  version: '3.1.0+1',
);

int _searchHistoryEntryEstimateSize(
  SearchHistoryEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.searchType.length * 3;
  bytesCount += 3 + object.term.length * 3;
  return bytesCount;
}

void _searchHistoryEntrySerialize(
  SearchHistoryEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.searchType);
  writer.writeDateTime(offsets[1], object.searchedAt);
  writer.writeString(offsets[2], object.term);
}

SearchHistoryEntry _searchHistoryEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SearchHistoryEntry();
  object.id = id;
  object.searchType = reader.readString(offsets[0]);
  object.searchedAt = reader.readDateTime(offsets[1]);
  object.term = reader.readString(offsets[2]);
  return object;
}

P _searchHistoryEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _searchHistoryEntryGetId(SearchHistoryEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _searchHistoryEntryGetLinks(
    SearchHistoryEntry object) {
  return [];
}

void _searchHistoryEntryAttach(
    IsarCollection<dynamic> col, Id id, SearchHistoryEntry object) {
  object.id = id;
}

extension SearchHistoryEntryQueryWhereSort
    on QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QWhere> {
  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SearchHistoryEntryQueryWhere
    on QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QWhereClause> {
  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterWhereClause>
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

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterWhereClause>
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

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterWhereClause>
      searchTypeEqualTo(String searchType) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'searchType',
        value: [searchType],
      ));
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterWhereClause>
      searchTypeNotEqualTo(String searchType) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'searchType',
              lower: [],
              upper: [searchType],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'searchType',
              lower: [searchType],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'searchType',
              lower: [searchType],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'searchType',
              lower: [],
              upper: [searchType],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterWhereClause>
      termEqualTo(String term) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'term',
        value: [term],
      ));
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterWhereClause>
      termNotEqualTo(String term) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'term',
              lower: [],
              upper: [term],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'term',
              lower: [term],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'term',
              lower: [term],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'term',
              lower: [],
              upper: [term],
              includeUpper: false,
            ));
      }
    });
  }
}

extension SearchHistoryEntryQueryFilter
    on QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QFilterCondition> {
  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterFilterCondition>
      searchTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'searchType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterFilterCondition>
      searchTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'searchType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterFilterCondition>
      searchTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'searchType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterFilterCondition>
      searchTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'searchType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterFilterCondition>
      searchTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'searchType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterFilterCondition>
      searchTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'searchType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterFilterCondition>
      searchTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'searchType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterFilterCondition>
      searchTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'searchType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterFilterCondition>
      searchTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'searchType',
        value: '',
      ));
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterFilterCondition>
      searchTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'searchType',
        value: '',
      ));
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterFilterCondition>
      searchedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'searchedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterFilterCondition>
      searchedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'searchedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterFilterCondition>
      searchedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'searchedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterFilterCondition>
      searchedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'searchedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterFilterCondition>
      termEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'term',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterFilterCondition>
      termGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'term',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterFilterCondition>
      termLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'term',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterFilterCondition>
      termBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'term',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterFilterCondition>
      termStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'term',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterFilterCondition>
      termEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'term',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterFilterCondition>
      termContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'term',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterFilterCondition>
      termMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'term',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterFilterCondition>
      termIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'term',
        value: '',
      ));
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterFilterCondition>
      termIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'term',
        value: '',
      ));
    });
  }
}

extension SearchHistoryEntryQueryObject
    on QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QFilterCondition> {}

extension SearchHistoryEntryQueryLinks
    on QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QFilterCondition> {}

extension SearchHistoryEntryQuerySortBy
    on QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QSortBy> {
  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterSortBy>
      sortBySearchType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'searchType', Sort.asc);
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterSortBy>
      sortBySearchTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'searchType', Sort.desc);
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterSortBy>
      sortBySearchedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'searchedAt', Sort.asc);
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterSortBy>
      sortBySearchedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'searchedAt', Sort.desc);
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterSortBy>
      sortByTerm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'term', Sort.asc);
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterSortBy>
      sortByTermDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'term', Sort.desc);
    });
  }
}

extension SearchHistoryEntryQuerySortThenBy
    on QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QSortThenBy> {
  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterSortBy>
      thenBySearchType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'searchType', Sort.asc);
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterSortBy>
      thenBySearchTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'searchType', Sort.desc);
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterSortBy>
      thenBySearchedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'searchedAt', Sort.asc);
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterSortBy>
      thenBySearchedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'searchedAt', Sort.desc);
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterSortBy>
      thenByTerm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'term', Sort.asc);
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QAfterSortBy>
      thenByTermDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'term', Sort.desc);
    });
  }
}

extension SearchHistoryEntryQueryWhereDistinct
    on QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QDistinct> {
  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QDistinct>
      distinctBySearchType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'searchType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QDistinct>
      distinctBySearchedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'searchedAt');
    });
  }

  QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QDistinct>
      distinctByTerm({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'term', caseSensitive: caseSensitive);
    });
  }
}

extension SearchHistoryEntryQueryProperty
    on QueryBuilder<SearchHistoryEntry, SearchHistoryEntry, QQueryProperty> {
  QueryBuilder<SearchHistoryEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SearchHistoryEntry, String, QQueryOperations>
      searchTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'searchType');
    });
  }

  QueryBuilder<SearchHistoryEntry, DateTime, QQueryOperations>
      searchedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'searchedAt');
    });
  }

  QueryBuilder<SearchHistoryEntry, String, QQueryOperations> termProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'term');
    });
  }
}
