import 'package:json_annotation/json_annotation.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/update_recipe_request.dart';
import 'ingredient_dto.dart';
import 'step_dto.dart';

part 'update_recipe_request_dto.g.dart';

/// DTO for updating an existing recipe.
@JsonSerializable()
class UpdateRecipeRequestDto {
  final String title;
  final String? description;
  final String? culinaryLocale;
  final List<IngredientDto> ingredients;
  final List<StepDto> steps;
  final List<String> imagePublicIds;
  final List<String>? hashtags;

  UpdateRecipeRequestDto({
    required this.title,
    this.description,
    this.culinaryLocale,
    required this.ingredients,
    required this.steps,
    required this.imagePublicIds,
    this.hashtags,
  });

  factory UpdateRecipeRequestDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateRecipeRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateRecipeRequestDtoToJson(this);

  factory UpdateRecipeRequestDto.fromEntity(UpdateRecipeRequest request) {
    return UpdateRecipeRequestDto(
      title: request.title,
      description: request.description,
      culinaryLocale: request.culinaryLocale,
      ingredients:
          request.ingredients.map((e) => IngredientDto.fromEntity(e)).toList(),
      steps: request.steps.map((e) => StepDto.fromEntity(e)).toList(),
      imagePublicIds: request.imagePublicIds,
      hashtags: request.hashtags,
    );
  }
}
