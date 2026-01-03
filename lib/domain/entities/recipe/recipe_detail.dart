import 'ingredient.dart';
import 'recipe_step.dart';
import 'recipe_summary.dart';
import 'log_post_summary.dart';

class RecipeDetail {
  final String id;
  final String title;
  final String description;
  final String culinaryLocale;
  final String? changeCategory;
  final RecipeSummary? rootInfo; // [원칙 1] 상단 고정 루트 정보
  final RecipeSummary? parentInfo; // Inspired by 정보
  final List<Ingredient> ingredients;
  final List<RecipeStep> steps;
  final List<String> imageUrls;
  final List<RecipeSummary> variants;
  final List<LogPostSummary> logs;

  RecipeDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.culinaryLocale,
    this.changeCategory,
    this.rootInfo,
    this.parentInfo,
    required this.ingredients,
    required this.steps,
    required this.imageUrls,
    required this.variants,
    required this.logs,
  });
}
