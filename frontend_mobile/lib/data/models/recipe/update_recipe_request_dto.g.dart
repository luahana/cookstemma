// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_recipe_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateRecipeRequestDto _$UpdateRecipeRequestDtoFromJson(
        Map<String, dynamic> json) =>
    UpdateRecipeRequestDto(
      title: json['title'] as String,
      description: json['description'] as String?,
      culinaryLocale: json['culinaryLocale'] as String?,
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((e) => IngredientDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      steps: (json['steps'] as List<dynamic>)
          .map((e) => StepDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      imagePublicIds: (json['imagePublicIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      hashtags: (json['hashtags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$UpdateRecipeRequestDtoToJson(
        UpdateRecipeRequestDto instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'culinaryLocale': instance.culinaryLocale,
      'ingredients': instance.ingredients,
      'steps': instance.steps,
      'imagePublicIds': instance.imagePublicIds,
      'hashtags': instance.hashtags,
    };
