// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_recipe_request_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateRecipeRequestDto _$CreateRecipeRequestDtoFromJson(
        Map<String, dynamic> json) =>
    CreateRecipeRequestDto(
      title: json['title'] as String,
      description: json['description'] as String,
      culinaryLocale: json['culinaryLocale'] as String?,
      food1MasterPublicId: json['food1MasterPublicId'] as String?,
      newFoodName: json['newFoodName'] as String?,
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((e) => IngredientDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      steps: (json['steps'] as List<dynamic>)
          .map((e) => StepDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      imagePublicIds: (json['imagePublicIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      changeCategory: json['changeCategory'] as String?,
      parentPublicId: json['parentPublicId'] as String?,
      rootPublicId: json['rootPublicId'] as String?,
      changeDiff: json['changeDiff'] as Map<String, dynamic>?,
      changeReason: json['changeReason'] as String?,
    );

Map<String, dynamic> _$CreateRecipeRequestDtoToJson(
        CreateRecipeRequestDto instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'culinaryLocale': instance.culinaryLocale,
      'food1MasterPublicId': instance.food1MasterPublicId,
      'newFoodName': instance.newFoodName,
      'ingredients': instance.ingredients,
      'steps': instance.steps,
      'imagePublicIds': instance.imagePublicIds,
      'changeCategory': instance.changeCategory,
      'parentPublicId': instance.parentPublicId,
      'rootPublicId': instance.rootPublicId,
      'changeDiff': instance.changeDiff,
      'changeReason': instance.changeReason,
    };
