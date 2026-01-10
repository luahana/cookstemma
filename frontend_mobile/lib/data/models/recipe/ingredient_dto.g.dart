// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IngredientDto _$IngredientDtoFromJson(Map<String, dynamic> json) =>
    IngredientDto(
      name: json['name'] as String,
      amount: json['amount'] as String?,
      type: $enumDecode(_$IngredientTypeEnumMap, json['type']),
    );

Map<String, dynamic> _$IngredientDtoToJson(IngredientDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'amount': instance.amount,
      'type': _$IngredientTypeEnumMap[instance.type]!,
    };

const _$IngredientTypeEnumMap = {
  IngredientType.main: 'MAIN',
  IngredientType.secondary: 'SECONDARY',
  IngredientType.seasoning: 'SEASONING',
};
