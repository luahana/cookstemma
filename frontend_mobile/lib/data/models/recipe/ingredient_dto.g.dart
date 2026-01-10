// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IngredientDto _$IngredientDtoFromJson(Map<String, dynamic> json) =>
    IngredientDto(
      name: json['name'] as String,
      amount: json['amount'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: $enumDecodeNullable(_$MeasurementUnitEnumMap, json['unit']),
      type: $enumDecode(_$IngredientTypeEnumMap, json['type']),
    );

Map<String, dynamic> _$IngredientDtoToJson(IngredientDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'amount': instance.amount,
      'quantity': instance.quantity,
      'unit': _$MeasurementUnitEnumMap[instance.unit],
      'type': _$IngredientTypeEnumMap[instance.type]!,
    };

const _$MeasurementUnitEnumMap = {
  MeasurementUnit.ml: 'ML',
  MeasurementUnit.l: 'L',
  MeasurementUnit.tsp: 'TSP',
  MeasurementUnit.tbsp: 'TBSP',
  MeasurementUnit.cup: 'CUP',
  MeasurementUnit.flOz: 'FL_OZ',
  MeasurementUnit.pint: 'PINT',
  MeasurementUnit.quart: 'QUART',
  MeasurementUnit.g: 'G',
  MeasurementUnit.kg: 'KG',
  MeasurementUnit.oz: 'OZ',
  MeasurementUnit.lb: 'LB',
  MeasurementUnit.piece: 'PIECE',
  MeasurementUnit.pinch: 'PINCH',
  MeasurementUnit.dash: 'DASH',
  MeasurementUnit.toTaste: 'TO_TASTE',
  MeasurementUnit.clove: 'CLOVE',
  MeasurementUnit.bunch: 'BUNCH',
  MeasurementUnit.can: 'CAN',
  MeasurementUnit.package: 'PACKAGE',
};

const _$IngredientTypeEnumMap = {
  IngredientType.main: 'MAIN',
  IngredientType.secondary: 'SECONDARY',
  IngredientType.seasoning: 'SEASONING',
};
