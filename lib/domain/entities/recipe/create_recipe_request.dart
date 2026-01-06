import 'package:pairing_planet2_frontend/domain/entities/recipe/ingredient.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_step.dart';

class CreateRecipeRequest {
  final String title;
  final String description;
  final String? culinaryLocale;
  final String? food1MasterPublicId;
  final String? newFoodName;
  final List<Ingredient> ingredients;
  final List<RecipeStep> steps;
  final List<String> imagePublicIds;
  final String? changeCategory;
  final String? parentPublicId;
  final String? rootPublicId;
  // Phase 7-3: Automatic Change Detection
  final Map<String, dynamic>? changeDiff;  // Structured diff
  final String? changeReason;              // User's explanation for changes

  CreateRecipeRequest({
    required this.title,
    required this.description,
    this.culinaryLocale,
    this.food1MasterPublicId,
    this.newFoodName,
    required this.ingredients,
    required this.steps,
    required this.imagePublicIds,
    this.changeCategory,
    this.parentPublicId,
    this.rootPublicId,
    this.changeDiff,
    this.changeReason,
  });
}
