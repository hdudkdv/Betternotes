// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_entities.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetNotebookEntityCollection on Isar {
  IsarCollection<NotebookEntity> get notebookEntitys => this.collection();
}

const NotebookEntitySchema = CollectionSchema(
  name: r'NotebookEntity',
  id: -429147861698866060,
  properties: {
    r'canvasMode': PropertySchema(
      id: 0,
      name: r'canvasMode',
      type: IsarType.string,
    ),
    r'coverColor': PropertySchema(
      id: 1,
      name: r'coverColor',
      type: IsarType.long,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'defaultOrientation': PropertySchema(
      id: 3,
      name: r'defaultOrientation',
      type: IsarType.string,
    ),
    r'defaultPaperFormat': PropertySchema(
      id: 4,
      name: r'defaultPaperFormat',
      type: IsarType.string,
    ),
    r'defaultTemplate': PropertySchema(
      id: 5,
      name: r'defaultTemplate',
      type: IsarType.string,
    ),
    r'isFavorite': PropertySchema(
      id: 6,
      name: r'isFavorite',
      type: IsarType.bool,
    ),
    r'lastOpenedAt': PropertySchema(
      id: 7,
      name: r'lastOpenedAt',
      type: IsarType.dateTime,
    ),
    r'pageCount': PropertySchema(
      id: 8,
      name: r'pageCount',
      type: IsarType.long,
    ),
    r'title': PropertySchema(id: 9, name: r'title', type: IsarType.string),
    r'updatedAt': PropertySchema(
      id: 10,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'uuid': PropertySchema(id: 11, name: r'uuid', type: IsarType.string),
  },

  estimateSize: _notebookEntityEstimateSize,
  serialize: _notebookEntitySerialize,
  deserialize: _notebookEntityDeserialize,
  deserializeProp: _notebookEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'uuid': IndexSchema(
      id: 2134397340427724972,
      name: r'uuid',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'uuid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _notebookEntityGetId,
  getLinks: _notebookEntityGetLinks,
  attach: _notebookEntityAttach,
  version: '3.3.2',
);

int _notebookEntityEstimateSize(
  NotebookEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.canvasMode.length * 3;
  bytesCount += 3 + object.defaultOrientation.length * 3;
  bytesCount += 3 + object.defaultPaperFormat.length * 3;
  bytesCount += 3 + object.defaultTemplate.length * 3;
  bytesCount += 3 + object.title.length * 3;
  bytesCount += 3 + object.uuid.length * 3;
  return bytesCount;
}

void _notebookEntitySerialize(
  NotebookEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.canvasMode);
  writer.writeLong(offsets[1], object.coverColor);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeString(offsets[3], object.defaultOrientation);
  writer.writeString(offsets[4], object.defaultPaperFormat);
  writer.writeString(offsets[5], object.defaultTemplate);
  writer.writeBool(offsets[6], object.isFavorite);
  writer.writeDateTime(offsets[7], object.lastOpenedAt);
  writer.writeLong(offsets[8], object.pageCount);
  writer.writeString(offsets[9], object.title);
  writer.writeDateTime(offsets[10], object.updatedAt);
  writer.writeString(offsets[11], object.uuid);
}

NotebookEntity _notebookEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = NotebookEntity();
  object.canvasMode = reader.readString(offsets[0]);
  object.coverColor = reader.readLong(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.defaultOrientation = reader.readString(offsets[3]);
  object.defaultPaperFormat = reader.readString(offsets[4]);
  object.defaultTemplate = reader.readString(offsets[5]);
  object.id = id;
  object.isFavorite = reader.readBool(offsets[6]);
  object.lastOpenedAt = reader.readDateTimeOrNull(offsets[7]);
  object.pageCount = reader.readLong(offsets[8]);
  object.title = reader.readString(offsets[9]);
  object.updatedAt = reader.readDateTime(offsets[10]);
  object.uuid = reader.readString(offsets[11]);
  return object;
}

P _notebookEntityDeserializeProp<P>(
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
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readDateTime(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _notebookEntityGetId(NotebookEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _notebookEntityGetLinks(NotebookEntity object) {
  return [];
}

void _notebookEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  NotebookEntity object,
) {
  object.id = id;
}

extension NotebookEntityByIndex on IsarCollection<NotebookEntity> {
  Future<NotebookEntity?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  NotebookEntity? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<NotebookEntity?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<NotebookEntity?> getAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uuid', values);
  }

  Future<int> deleteAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uuid', values);
  }

  int deleteAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uuid', values);
  }

  Future<Id> putByUuid(NotebookEntity object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(NotebookEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<NotebookEntity> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(
    List<NotebookEntity> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension NotebookEntityQueryWhereSort
    on QueryBuilder<NotebookEntity, NotebookEntity, QWhere> {
  QueryBuilder<NotebookEntity, NotebookEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension NotebookEntityQueryWhere
    on QueryBuilder<NotebookEntity, NotebookEntity, QWhereClause> {
  QueryBuilder<NotebookEntity, NotebookEntity, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
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

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterWhereClause> idBetween(
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

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterWhereClause> uuidEqualTo(
    String uuid,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'uuid', value: [uuid]),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterWhereClause>
  uuidNotEqualTo(String uuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [],
                upper: [uuid],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [uuid],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [uuid],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [],
                upper: [uuid],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension NotebookEntityQueryFilter
    on QueryBuilder<NotebookEntity, NotebookEntity, QFilterCondition> {
  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  canvasModeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'canvasMode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  canvasModeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'canvasMode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  canvasModeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'canvasMode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  canvasModeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'canvasMode',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  canvasModeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'canvasMode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  canvasModeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'canvasMode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  canvasModeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'canvasMode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  canvasModeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'canvasMode',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  canvasModeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'canvasMode', value: ''),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  canvasModeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'canvasMode', value: ''),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  coverColorEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'coverColor', value: value),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  coverColorGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'coverColor',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  coverColorLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'coverColor',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  coverColorBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'coverColor',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
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

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
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

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
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

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  defaultOrientationEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'defaultOrientation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  defaultOrientationGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'defaultOrientation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  defaultOrientationLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'defaultOrientation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  defaultOrientationBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'defaultOrientation',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  defaultOrientationStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'defaultOrientation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  defaultOrientationEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'defaultOrientation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  defaultOrientationContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'defaultOrientation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  defaultOrientationMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'defaultOrientation',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  defaultOrientationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'defaultOrientation', value: ''),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  defaultOrientationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'defaultOrientation', value: ''),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  defaultPaperFormatEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'defaultPaperFormat',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  defaultPaperFormatGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'defaultPaperFormat',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  defaultPaperFormatLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'defaultPaperFormat',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  defaultPaperFormatBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'defaultPaperFormat',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  defaultPaperFormatStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'defaultPaperFormat',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  defaultPaperFormatEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'defaultPaperFormat',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  defaultPaperFormatContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'defaultPaperFormat',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  defaultPaperFormatMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'defaultPaperFormat',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  defaultPaperFormatIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'defaultPaperFormat', value: ''),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  defaultPaperFormatIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'defaultPaperFormat', value: ''),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  defaultTemplateEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'defaultTemplate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  defaultTemplateGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'defaultTemplate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  defaultTemplateLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'defaultTemplate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  defaultTemplateBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'defaultTemplate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  defaultTemplateStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'defaultTemplate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  defaultTemplateEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'defaultTemplate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  defaultTemplateContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'defaultTemplate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  defaultTemplateMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'defaultTemplate',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  defaultTemplateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'defaultTemplate', value: ''),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  defaultTemplateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'defaultTemplate', value: ''),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
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

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
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

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition> idBetween(
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

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  isFavoriteEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isFavorite', value: value),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  lastOpenedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastOpenedAt'),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  lastOpenedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastOpenedAt'),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  lastOpenedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastOpenedAt', value: value),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  lastOpenedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastOpenedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  lastOpenedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastOpenedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  lastOpenedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastOpenedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  pageCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'pageCount', value: value),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  pageCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'pageCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  pageCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'pageCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  pageCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'pageCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  titleEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'title',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  titleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  titleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'title',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
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

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
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

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
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

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  uuidEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  uuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  uuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  uuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'uuid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  uuidStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  uuidEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  uuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  uuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'uuid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uuid', value: ''),
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterFilterCondition>
  uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'uuid', value: ''),
      );
    });
  }
}

extension NotebookEntityQueryObject
    on QueryBuilder<NotebookEntity, NotebookEntity, QFilterCondition> {}

extension NotebookEntityQueryLinks
    on QueryBuilder<NotebookEntity, NotebookEntity, QFilterCondition> {}

extension NotebookEntityQuerySortBy
    on QueryBuilder<NotebookEntity, NotebookEntity, QSortBy> {
  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  sortByCanvasMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canvasMode', Sort.asc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  sortByCanvasModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canvasMode', Sort.desc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  sortByCoverColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coverColor', Sort.asc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  sortByCoverColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coverColor', Sort.desc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  sortByDefaultOrientation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultOrientation', Sort.asc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  sortByDefaultOrientationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultOrientation', Sort.desc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  sortByDefaultPaperFormat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultPaperFormat', Sort.asc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  sortByDefaultPaperFormatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultPaperFormat', Sort.desc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  sortByDefaultTemplate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultTemplate', Sort.asc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  sortByDefaultTemplateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultTemplate', Sort.desc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  sortByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  sortByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  sortByLastOpenedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastOpenedAt', Sort.asc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  sortByLastOpenedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastOpenedAt', Sort.desc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy> sortByPageCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageCount', Sort.asc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  sortByPageCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageCount', Sort.desc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension NotebookEntityQuerySortThenBy
    on QueryBuilder<NotebookEntity, NotebookEntity, QSortThenBy> {
  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  thenByCanvasMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canvasMode', Sort.asc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  thenByCanvasModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canvasMode', Sort.desc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  thenByCoverColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coverColor', Sort.asc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  thenByCoverColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coverColor', Sort.desc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  thenByDefaultOrientation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultOrientation', Sort.asc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  thenByDefaultOrientationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultOrientation', Sort.desc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  thenByDefaultPaperFormat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultPaperFormat', Sort.asc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  thenByDefaultPaperFormatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultPaperFormat', Sort.desc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  thenByDefaultTemplate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultTemplate', Sort.asc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  thenByDefaultTemplateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultTemplate', Sort.desc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  thenByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  thenByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  thenByLastOpenedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastOpenedAt', Sort.asc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  thenByLastOpenedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastOpenedAt', Sort.desc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy> thenByPageCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageCount', Sort.asc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  thenByPageCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageCount', Sort.desc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension NotebookEntityQueryWhereDistinct
    on QueryBuilder<NotebookEntity, NotebookEntity, QDistinct> {
  QueryBuilder<NotebookEntity, NotebookEntity, QDistinct> distinctByCanvasMode({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'canvasMode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QDistinct>
  distinctByCoverColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'coverColor');
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QDistinct>
  distinctByDefaultOrientation({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'defaultOrientation',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QDistinct>
  distinctByDefaultPaperFormat({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'defaultPaperFormat',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QDistinct>
  distinctByDefaultTemplate({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'defaultTemplate',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QDistinct>
  distinctByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFavorite');
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QDistinct>
  distinctByLastOpenedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastOpenedAt');
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QDistinct>
  distinctByPageCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pageCount');
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QDistinct> distinctByTitle({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<NotebookEntity, NotebookEntity, QDistinct> distinctByUuid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }
}

extension NotebookEntityQueryProperty
    on QueryBuilder<NotebookEntity, NotebookEntity, QQueryProperty> {
  QueryBuilder<NotebookEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<NotebookEntity, String, QQueryOperations> canvasModeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'canvasMode');
    });
  }

  QueryBuilder<NotebookEntity, int, QQueryOperations> coverColorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'coverColor');
    });
  }

  QueryBuilder<NotebookEntity, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<NotebookEntity, String, QQueryOperations>
  defaultOrientationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'defaultOrientation');
    });
  }

  QueryBuilder<NotebookEntity, String, QQueryOperations>
  defaultPaperFormatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'defaultPaperFormat');
    });
  }

  QueryBuilder<NotebookEntity, String, QQueryOperations>
  defaultTemplateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'defaultTemplate');
    });
  }

  QueryBuilder<NotebookEntity, bool, QQueryOperations> isFavoriteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFavorite');
    });
  }

  QueryBuilder<NotebookEntity, DateTime?, QQueryOperations>
  lastOpenedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastOpenedAt');
    });
  }

  QueryBuilder<NotebookEntity, int, QQueryOperations> pageCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pageCount');
    });
  }

  QueryBuilder<NotebookEntity, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<NotebookEntity, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<NotebookEntity, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPageEntityCollection on Isar {
  IsarCollection<PageEntity> get pageEntitys => this.collection();
}

const PageEntitySchema = CollectionSchema(
  name: r'PageEntity',
  id: 7780399719172098451,
  properties: {
    r'backgroundPdfPath': PropertySchema(
      id: 0,
      name: r'backgroundPdfPath',
      type: IsarType.string,
    ),
    r'customPaperJson': PropertySchema(
      id: 1,
      name: r'customPaperJson',
      type: IsarType.string,
    ),
    r'index': PropertySchema(id: 2, name: r'index', type: IsarType.long),
    r'notebookId': PropertySchema(
      id: 3,
      name: r'notebookId',
      type: IsarType.string,
    ),
    r'orientation': PropertySchema(
      id: 4,
      name: r'orientation',
      type: IsarType.string,
    ),
    r'paperFormat': PropertySchema(
      id: 5,
      name: r'paperFormat',
      type: IsarType.string,
    ),
    r'paperTemplateId': PropertySchema(
      id: 6,
      name: r'paperTemplateId',
      type: IsarType.string,
    ),
    r'strokesJson': PropertySchema(
      id: 7,
      name: r'strokesJson',
      type: IsarType.string,
    ),
    r'template': PropertySchema(
      id: 8,
      name: r'template',
      type: IsarType.string,
    ),
    r'textBlocksJson': PropertySchema(
      id: 9,
      name: r'textBlocksJson',
      type: IsarType.string,
    ),
    r'thumbnailPath': PropertySchema(
      id: 10,
      name: r'thumbnailPath',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 11,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'uuid': PropertySchema(id: 12, name: r'uuid', type: IsarType.string),
  },

  estimateSize: _pageEntityEstimateSize,
  serialize: _pageEntitySerialize,
  deserialize: _pageEntityDeserialize,
  deserializeProp: _pageEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'uuid': IndexSchema(
      id: 2134397340427724972,
      name: r'uuid',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'uuid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'notebookId': IndexSchema(
      id: -4215995649193063521,
      name: r'notebookId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'notebookId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _pageEntityGetId,
  getLinks: _pageEntityGetLinks,
  attach: _pageEntityAttach,
  version: '3.3.2',
);

int _pageEntityEstimateSize(
  PageEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.backgroundPdfPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.customPaperJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.notebookId.length * 3;
  bytesCount += 3 + object.orientation.length * 3;
  bytesCount += 3 + object.paperFormat.length * 3;
  {
    final value = object.paperTemplateId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.strokesJson.length * 3;
  bytesCount += 3 + object.template.length * 3;
  bytesCount += 3 + object.textBlocksJson.length * 3;
  {
    final value = object.thumbnailPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.uuid.length * 3;
  return bytesCount;
}

void _pageEntitySerialize(
  PageEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.backgroundPdfPath);
  writer.writeString(offsets[1], object.customPaperJson);
  writer.writeLong(offsets[2], object.index);
  writer.writeString(offsets[3], object.notebookId);
  writer.writeString(offsets[4], object.orientation);
  writer.writeString(offsets[5], object.paperFormat);
  writer.writeString(offsets[6], object.paperTemplateId);
  writer.writeString(offsets[7], object.strokesJson);
  writer.writeString(offsets[8], object.template);
  writer.writeString(offsets[9], object.textBlocksJson);
  writer.writeString(offsets[10], object.thumbnailPath);
  writer.writeDateTime(offsets[11], object.updatedAt);
  writer.writeString(offsets[12], object.uuid);
}

PageEntity _pageEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PageEntity();
  object.backgroundPdfPath = reader.readStringOrNull(offsets[0]);
  object.customPaperJson = reader.readStringOrNull(offsets[1]);
  object.id = id;
  object.index = reader.readLong(offsets[2]);
  object.notebookId = reader.readString(offsets[3]);
  object.orientation = reader.readString(offsets[4]);
  object.paperFormat = reader.readString(offsets[5]);
  object.paperTemplateId = reader.readStringOrNull(offsets[6]);
  object.strokesJson = reader.readString(offsets[7]);
  object.template = reader.readString(offsets[8]);
  object.textBlocksJson = reader.readString(offsets[9]);
  object.thumbnailPath = reader.readStringOrNull(offsets[10]);
  object.updatedAt = reader.readDateTimeOrNull(offsets[11]);
  object.uuid = reader.readString(offsets[12]);
  return object;
}

P _pageEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _pageEntityGetId(PageEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _pageEntityGetLinks(PageEntity object) {
  return [];
}

void _pageEntityAttach(IsarCollection<dynamic> col, Id id, PageEntity object) {
  object.id = id;
}

extension PageEntityByIndex on IsarCollection<PageEntity> {
  Future<PageEntity?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  PageEntity? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<PageEntity?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<PageEntity?> getAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uuid', values);
  }

  Future<int> deleteAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uuid', values);
  }

  int deleteAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uuid', values);
  }

  Future<Id> putByUuid(PageEntity object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(PageEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<PageEntity> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(List<PageEntity> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension PageEntityQueryWhereSort
    on QueryBuilder<PageEntity, PageEntity, QWhere> {
  QueryBuilder<PageEntity, PageEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PageEntityQueryWhere
    on QueryBuilder<PageEntity, PageEntity, QWhereClause> {
  QueryBuilder<PageEntity, PageEntity, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<PageEntity, PageEntity, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterWhereClause> idBetween(
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

  QueryBuilder<PageEntity, PageEntity, QAfterWhereClause> uuidEqualTo(
    String uuid,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'uuid', value: [uuid]),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterWhereClause> uuidNotEqualTo(
    String uuid,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [],
                upper: [uuid],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [uuid],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [uuid],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [],
                upper: [uuid],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterWhereClause> notebookIdEqualTo(
    String notebookId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'notebookId', value: [notebookId]),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterWhereClause> notebookIdNotEqualTo(
    String notebookId,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'notebookId',
                lower: [],
                upper: [notebookId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'notebookId',
                lower: [notebookId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'notebookId',
                lower: [notebookId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'notebookId',
                lower: [],
                upper: [notebookId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension PageEntityQueryFilter
    on QueryBuilder<PageEntity, PageEntity, QFilterCondition> {
  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  backgroundPdfPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'backgroundPdfPath'),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  backgroundPdfPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'backgroundPdfPath'),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  backgroundPdfPathEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'backgroundPdfPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  backgroundPdfPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'backgroundPdfPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  backgroundPdfPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'backgroundPdfPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  backgroundPdfPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'backgroundPdfPath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  backgroundPdfPathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'backgroundPdfPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  backgroundPdfPathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'backgroundPdfPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  backgroundPdfPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'backgroundPdfPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  backgroundPdfPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'backgroundPdfPath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  backgroundPdfPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'backgroundPdfPath', value: ''),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  backgroundPdfPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'backgroundPdfPath', value: ''),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  customPaperJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'customPaperJson'),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  customPaperJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'customPaperJson'),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  customPaperJsonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'customPaperJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  customPaperJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'customPaperJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  customPaperJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'customPaperJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  customPaperJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'customPaperJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  customPaperJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'customPaperJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  customPaperJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'customPaperJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  customPaperJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'customPaperJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  customPaperJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'customPaperJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  customPaperJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'customPaperJson', value: ''),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  customPaperJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'customPaperJson', value: ''),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> idBetween(
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

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> indexEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'index', value: value),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> indexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'index',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> indexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'index',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> indexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'index',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> notebookIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'notebookId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  notebookIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'notebookId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  notebookIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'notebookId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> notebookIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'notebookId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  notebookIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'notebookId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  notebookIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'notebookId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  notebookIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'notebookId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> notebookIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'notebookId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  notebookIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'notebookId', value: ''),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  notebookIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'notebookId', value: ''),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  orientationEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'orientation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  orientationGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'orientation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  orientationLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'orientation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  orientationBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'orientation',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  orientationStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'orientation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  orientationEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'orientation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  orientationContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'orientation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  orientationMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'orientation',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  orientationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'orientation', value: ''),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  orientationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'orientation', value: ''),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  paperFormatEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'paperFormat',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  paperFormatGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'paperFormat',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  paperFormatLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'paperFormat',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  paperFormatBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'paperFormat',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  paperFormatStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'paperFormat',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  paperFormatEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'paperFormat',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  paperFormatContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'paperFormat',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  paperFormatMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'paperFormat',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  paperFormatIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'paperFormat', value: ''),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  paperFormatIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'paperFormat', value: ''),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  paperTemplateIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'paperTemplateId'),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  paperTemplateIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'paperTemplateId'),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  paperTemplateIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'paperTemplateId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  paperTemplateIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'paperTemplateId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  paperTemplateIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'paperTemplateId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  paperTemplateIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'paperTemplateId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  paperTemplateIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'paperTemplateId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  paperTemplateIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'paperTemplateId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  paperTemplateIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'paperTemplateId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  paperTemplateIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'paperTemplateId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  paperTemplateIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'paperTemplateId', value: ''),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  paperTemplateIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'paperTemplateId', value: ''),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  strokesJsonEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'strokesJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  strokesJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'strokesJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  strokesJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'strokesJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  strokesJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'strokesJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  strokesJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'strokesJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  strokesJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'strokesJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  strokesJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'strokesJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  strokesJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'strokesJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  strokesJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'strokesJson', value: ''),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  strokesJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'strokesJson', value: ''),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> templateEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'template',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  templateGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'template',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> templateLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'template',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> templateBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'template',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  templateStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'template',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> templateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'template',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> templateContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'template',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> templateMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'template',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  templateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'template', value: ''),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  templateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'template', value: ''),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  textBlocksJsonEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'textBlocksJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  textBlocksJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'textBlocksJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  textBlocksJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'textBlocksJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  textBlocksJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'textBlocksJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  textBlocksJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'textBlocksJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  textBlocksJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'textBlocksJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  textBlocksJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'textBlocksJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  textBlocksJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'textBlocksJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  textBlocksJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'textBlocksJson', value: ''),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  textBlocksJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'textBlocksJson', value: ''),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  thumbnailPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'thumbnailPath'),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  thumbnailPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'thumbnailPath'),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  thumbnailPathEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'thumbnailPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  thumbnailPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'thumbnailPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  thumbnailPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'thumbnailPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  thumbnailPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'thumbnailPath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  thumbnailPathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'thumbnailPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  thumbnailPathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'thumbnailPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  thumbnailPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'thumbnailPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  thumbnailPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'thumbnailPath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  thumbnailPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'thumbnailPath', value: ''),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  thumbnailPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'thumbnailPath', value: ''),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'updatedAt'),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'updatedAt'),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> updatedAtEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition>
  updatedAtGreaterThan(DateTime? value, {bool include = false}) {
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

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> updatedAtLessThan(
    DateTime? value, {
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

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> updatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
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

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> uuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> uuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> uuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> uuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'uuid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> uuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> uuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> uuidContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> uuidMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'uuid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uuid', value: ''),
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterFilterCondition> uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'uuid', value: ''),
      );
    });
  }
}

extension PageEntityQueryObject
    on QueryBuilder<PageEntity, PageEntity, QFilterCondition> {}

extension PageEntityQueryLinks
    on QueryBuilder<PageEntity, PageEntity, QFilterCondition> {}

extension PageEntityQuerySortBy
    on QueryBuilder<PageEntity, PageEntity, QSortBy> {
  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByBackgroundPdfPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backgroundPdfPath', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy>
  sortByBackgroundPdfPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backgroundPdfPath', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByCustomPaperJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customPaperJson', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy>
  sortByCustomPaperJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customPaperJson', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'index', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'index', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByNotebookId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notebookId', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByNotebookIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notebookId', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByOrientation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orientation', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByOrientationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orientation', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByPaperFormat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paperFormat', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByPaperFormatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paperFormat', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByPaperTemplateId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paperTemplateId', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy>
  sortByPaperTemplateIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paperTemplateId', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByStrokesJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'strokesJson', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByStrokesJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'strokesJson', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByTemplate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'template', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByTemplateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'template', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByTextBlocksJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textBlocksJson', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy>
  sortByTextBlocksJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textBlocksJson', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByThumbnailPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailPath', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByThumbnailPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailPath', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension PageEntityQuerySortThenBy
    on QueryBuilder<PageEntity, PageEntity, QSortThenBy> {
  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByBackgroundPdfPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backgroundPdfPath', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy>
  thenByBackgroundPdfPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backgroundPdfPath', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByCustomPaperJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customPaperJson', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy>
  thenByCustomPaperJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customPaperJson', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'index', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'index', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByNotebookId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notebookId', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByNotebookIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notebookId', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByOrientation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orientation', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByOrientationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orientation', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByPaperFormat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paperFormat', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByPaperFormatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paperFormat', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByPaperTemplateId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paperTemplateId', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy>
  thenByPaperTemplateIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paperTemplateId', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByStrokesJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'strokesJson', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByStrokesJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'strokesJson', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByTemplate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'template', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByTemplateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'template', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByTextBlocksJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textBlocksJson', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy>
  thenByTextBlocksJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textBlocksJson', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByThumbnailPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailPath', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByThumbnailPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailPath', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension PageEntityQueryWhereDistinct
    on QueryBuilder<PageEntity, PageEntity, QDistinct> {
  QueryBuilder<PageEntity, PageEntity, QDistinct> distinctByBackgroundPdfPath({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'backgroundPdfPath',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QDistinct> distinctByCustomPaperJson({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'customPaperJson',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QDistinct> distinctByIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'index');
    });
  }

  QueryBuilder<PageEntity, PageEntity, QDistinct> distinctByNotebookId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notebookId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QDistinct> distinctByOrientation({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orientation', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QDistinct> distinctByPaperFormat({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paperFormat', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QDistinct> distinctByPaperTemplateId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'paperTemplateId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QDistinct> distinctByStrokesJson({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'strokesJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QDistinct> distinctByTemplate({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'template', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PageEntity, PageEntity, QDistinct> distinctByTextBlocksJson({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'textBlocksJson',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QDistinct> distinctByThumbnailPath({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'thumbnailPath',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<PageEntity, PageEntity, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<PageEntity, PageEntity, QDistinct> distinctByUuid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }
}

extension PageEntityQueryProperty
    on QueryBuilder<PageEntity, PageEntity, QQueryProperty> {
  QueryBuilder<PageEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PageEntity, String?, QQueryOperations>
  backgroundPdfPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'backgroundPdfPath');
    });
  }

  QueryBuilder<PageEntity, String?, QQueryOperations>
  customPaperJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customPaperJson');
    });
  }

  QueryBuilder<PageEntity, int, QQueryOperations> indexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'index');
    });
  }

  QueryBuilder<PageEntity, String, QQueryOperations> notebookIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notebookId');
    });
  }

  QueryBuilder<PageEntity, String, QQueryOperations> orientationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orientation');
    });
  }

  QueryBuilder<PageEntity, String, QQueryOperations> paperFormatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paperFormat');
    });
  }

  QueryBuilder<PageEntity, String?, QQueryOperations>
  paperTemplateIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paperTemplateId');
    });
  }

  QueryBuilder<PageEntity, String, QQueryOperations> strokesJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'strokesJson');
    });
  }

  QueryBuilder<PageEntity, String, QQueryOperations> templateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'template');
    });
  }

  QueryBuilder<PageEntity, String, QQueryOperations> textBlocksJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'textBlocksJson');
    });
  }

  QueryBuilder<PageEntity, String?, QQueryOperations> thumbnailPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'thumbnailPath');
    });
  }

  QueryBuilder<PageEntity, DateTime?, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<PageEntity, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetKvEntityCollection on Isar {
  IsarCollection<KvEntity> get kvEntitys => this.collection();
}

const KvEntitySchema = CollectionSchema(
  name: r'KvEntity',
  id: -8563681111507351438,
  properties: {
    r'key': PropertySchema(id: 0, name: r'key', type: IsarType.string),
    r'valueJson': PropertySchema(
      id: 1,
      name: r'valueJson',
      type: IsarType.string,
    ),
  },

  estimateSize: _kvEntityEstimateSize,
  serialize: _kvEntitySerialize,
  deserialize: _kvEntityDeserialize,
  deserializeProp: _kvEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'key': IndexSchema(
      id: -4906094122524121629,
      name: r'key',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'key',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _kvEntityGetId,
  getLinks: _kvEntityGetLinks,
  attach: _kvEntityAttach,
  version: '3.3.2',
);

int _kvEntityEstimateSize(
  KvEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.key.length * 3;
  bytesCount += 3 + object.valueJson.length * 3;
  return bytesCount;
}

void _kvEntitySerialize(
  KvEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.key);
  writer.writeString(offsets[1], object.valueJson);
}

KvEntity _kvEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = KvEntity();
  object.id = id;
  object.key = reader.readString(offsets[0]);
  object.valueJson = reader.readString(offsets[1]);
  return object;
}

P _kvEntityDeserializeProp<P>(
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

Id _kvEntityGetId(KvEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _kvEntityGetLinks(KvEntity object) {
  return [];
}

void _kvEntityAttach(IsarCollection<dynamic> col, Id id, KvEntity object) {
  object.id = id;
}

extension KvEntityByIndex on IsarCollection<KvEntity> {
  Future<KvEntity?> getByKey(String key) {
    return getByIndex(r'key', [key]);
  }

  KvEntity? getByKeySync(String key) {
    return getByIndexSync(r'key', [key]);
  }

  Future<bool> deleteByKey(String key) {
    return deleteByIndex(r'key', [key]);
  }

  bool deleteByKeySync(String key) {
    return deleteByIndexSync(r'key', [key]);
  }

  Future<List<KvEntity?>> getAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndex(r'key', values);
  }

  List<KvEntity?> getAllByKeySync(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'key', values);
  }

  Future<int> deleteAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'key', values);
  }

  int deleteAllByKeySync(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'key', values);
  }

  Future<Id> putByKey(KvEntity object) {
    return putByIndex(r'key', object);
  }

  Id putByKeySync(KvEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'key', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByKey(List<KvEntity> objects) {
    return putAllByIndex(r'key', objects);
  }

  List<Id> putAllByKeySync(List<KvEntity> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'key', objects, saveLinks: saveLinks);
  }
}

extension KvEntityQueryWhereSort on QueryBuilder<KvEntity, KvEntity, QWhere> {
  QueryBuilder<KvEntity, KvEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension KvEntityQueryWhere on QueryBuilder<KvEntity, KvEntity, QWhereClause> {
  QueryBuilder<KvEntity, KvEntity, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<KvEntity, KvEntity, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterWhereClause> idBetween(
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

  QueryBuilder<KvEntity, KvEntity, QAfterWhereClause> keyEqualTo(String key) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'key', value: [key]),
      );
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterWhereClause> keyNotEqualTo(
    String key,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'key',
                lower: [],
                upper: [key],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'key',
                lower: [key],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'key',
                lower: [key],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'key',
                lower: [],
                upper: [key],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension KvEntityQueryFilter
    on QueryBuilder<KvEntity, KvEntity, QFilterCondition> {
  QueryBuilder<KvEntity, KvEntity, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<KvEntity, KvEntity, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<KvEntity, KvEntity, QAfterFilterCondition> idBetween(
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

  QueryBuilder<KvEntity, KvEntity, QAfterFilterCondition> keyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterFilterCondition> keyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterFilterCondition> keyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterFilterCondition> keyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'key',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterFilterCondition> keyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterFilterCondition> keyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterFilterCondition> keyContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterFilterCondition> keyMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'key',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterFilterCondition> keyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'key', value: ''),
      );
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterFilterCondition> keyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'key', value: ''),
      );
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterFilterCondition> valueJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'valueJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterFilterCondition> valueJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'valueJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterFilterCondition> valueJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'valueJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterFilterCondition> valueJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'valueJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterFilterCondition> valueJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'valueJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterFilterCondition> valueJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'valueJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterFilterCondition> valueJsonContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'valueJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterFilterCondition> valueJsonMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'valueJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterFilterCondition> valueJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'valueJson', value: ''),
      );
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterFilterCondition>
  valueJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'valueJson', value: ''),
      );
    });
  }
}

extension KvEntityQueryObject
    on QueryBuilder<KvEntity, KvEntity, QFilterCondition> {}

extension KvEntityQueryLinks
    on QueryBuilder<KvEntity, KvEntity, QFilterCondition> {}

extension KvEntityQuerySortBy on QueryBuilder<KvEntity, KvEntity, QSortBy> {
  QueryBuilder<KvEntity, KvEntity, QAfterSortBy> sortByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterSortBy> sortByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterSortBy> sortByValueJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueJson', Sort.asc);
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterSortBy> sortByValueJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueJson', Sort.desc);
    });
  }
}

extension KvEntityQuerySortThenBy
    on QueryBuilder<KvEntity, KvEntity, QSortThenBy> {
  QueryBuilder<KvEntity, KvEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterSortBy> thenByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterSortBy> thenByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterSortBy> thenByValueJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueJson', Sort.asc);
    });
  }

  QueryBuilder<KvEntity, KvEntity, QAfterSortBy> thenByValueJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueJson', Sort.desc);
    });
  }
}

extension KvEntityQueryWhereDistinct
    on QueryBuilder<KvEntity, KvEntity, QDistinct> {
  QueryBuilder<KvEntity, KvEntity, QDistinct> distinctByKey({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'key', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<KvEntity, KvEntity, QDistinct> distinctByValueJson({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'valueJson', caseSensitive: caseSensitive);
    });
  }
}

extension KvEntityQueryProperty
    on QueryBuilder<KvEntity, KvEntity, QQueryProperty> {
  QueryBuilder<KvEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<KvEntity, String, QQueryOperations> keyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'key');
    });
  }

  QueryBuilder<KvEntity, String, QQueryOperations> valueJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'valueJson');
    });
  }
}
