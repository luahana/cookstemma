// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_summary_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeSummaryDto _$RecipeSummaryDtoFromJson(Map<String, dynamic> json) =>
    RecipeSummaryDto(
      publicId: json['publicId'] as String,
      foodName: json['foodName'] as String,
      foodMasterPublicId: json['foodMasterPublicId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      culinaryLocale: json['culinaryLocale'] as String?,
      creatorPublicId: json['creatorPublicId'] as String?,
      creatorName: json['creatorName'] as String?,
      thumbnail: json['thumbnail'] as String?,
      variantCount: (json['variantCount'] as num?)?.toInt(),
      logCount: (json['logCount'] as num?)?.toInt(),
      parentPublicId: json['parentPublicId'] as String?,
      rootPublicId: json['rootPublicId'] as String?,
      rootTitle: json['rootTitle'] as String?,
    );

Map<String, dynamic> _$RecipeSummaryDtoToJson(RecipeSummaryDto instance) =>
    <String, dynamic>{
      'publicId': instance.publicId,
      'foodName': instance.foodName,
      'foodMasterPublicId': instance.foodMasterPublicId,
      'title': instance.title,
      'description': instance.description,
      'culinaryLocale': instance.culinaryLocale,
      'creatorPublicId': instance.creatorPublicId,
      'creatorName': instance.creatorName,
      'thumbnail': instance.thumbnail,
      'variantCount': instance.variantCount,
      'logCount': instance.logCount,
      'parentPublicId': instance.parentPublicId,
      'rootPublicId': instance.rootPublicId,
      'rootTitle': instance.rootTitle,
    };
