// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_modifiable_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeModifiableDto _$RecipeModifiableDtoFromJson(Map<String, dynamic> json) =>
    RecipeModifiableDto(
      canModify: json['canModify'] as bool,
      isOwner: json['isOwner'] as bool,
      hasVariants: json['hasVariants'] as bool,
      hasLogs: json['hasLogs'] as bool,
      variantCount: (json['variantCount'] as num).toInt(),
      logCount: (json['logCount'] as num).toInt(),
      reason: json['reason'] as String?,
    );

Map<String, dynamic> _$RecipeModifiableDtoToJson(
        RecipeModifiableDto instance) =>
    <String, dynamic>{
      'canModify': instance.canModify,
      'isOwner': instance.isOwner,
      'hasVariants': instance.hasVariants,
      'hasLogs': instance.hasLogs,
      'variantCount': instance.variantCount,
      'logCount': instance.logCount,
      'reason': instance.reason,
    };
