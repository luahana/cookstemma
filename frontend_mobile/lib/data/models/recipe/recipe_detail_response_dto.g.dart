// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_detail_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeDetailResponseDto _$RecipeDetailResponseDtoFromJson(
        Map<String, dynamic> json) =>
    RecipeDetailResponseDto(
      publicId: json['publicId'] as String,
      foodName: json['foodName'] as String,
      foodMasterPublicId: json['foodMasterPublicId'] as String,
      creatorName: json['creatorName'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      culinaryLocale: json['culinaryLocale'] as String?,
      changeCategory: json['changeCategory'] as String?,
      rootInfo: json['rootInfo'] == null
          ? null
          : RecipeSummaryDto.fromJson(json['rootInfo'] as Map<String, dynamic>),
      parentInfo: json['parentInfo'] == null
          ? null
          : RecipeSummaryDto.fromJson(
              json['parentInfo'] as Map<String, dynamic>),
      ingredients: (json['ingredients'] as List<dynamic>?)
          ?.map((e) => IngredientDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      steps: (json['steps'] as List<dynamic>?)
          ?.map((e) => StepDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => ImageResponseDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      variants: (json['variants'] as List<dynamic>?)
          ?.map((e) => RecipeSummaryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      logs: (json['logs'] as List<dynamic>?)
          ?.map((e) => LogPostSummaryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      hashtags: (json['hashtags'] as List<dynamic>?)
          ?.map((e) => HashtagDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      isSavedByCurrentUser: json['isSavedByCurrentUser'] as bool?,
      changeDiff: json['changeDiff'] as Map<String, dynamic>?,
      changeCategories: (json['changeCategories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      changeReason: _parseChangeReason(json['changeReason']),
    );

Map<String, dynamic> _$RecipeDetailResponseDtoToJson(
        RecipeDetailResponseDto instance) =>
    <String, dynamic>{
      'publicId': instance.publicId,
      'foodName': instance.foodName,
      'foodMasterPublicId': instance.foodMasterPublicId,
      'creatorName': instance.creatorName,
      'title': instance.title,
      'description': instance.description,
      'culinaryLocale': instance.culinaryLocale,
      'changeCategory': instance.changeCategory,
      'rootInfo': instance.rootInfo,
      'parentInfo': instance.parentInfo,
      'ingredients': instance.ingredients,
      'steps': instance.steps,
      'images': instance.images,
      'variants': instance.variants,
      'logs': instance.logs,
      'hashtags': instance.hashtags,
      'isSavedByCurrentUser': instance.isSavedByCurrentUser,
      'changeDiff': instance.changeDiff,
      'changeCategories': instance.changeCategories,
      'changeReason': instance.changeReason,
    };
