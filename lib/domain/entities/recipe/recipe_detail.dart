import 'ingredient.dart';
import 'recipe_step.dart';
import 'recipe_summary.dart';
import '../log_post/log_post_summary.dart';

class RecipeDetail {
  final String publicId;
  final String foodName;
  final String foodMasterPublicId;
  final String title;
  final String? description;
  final String? culinaryLocale;
  final String? changeCategory;
  final RecipeSummary? rootInfo; // [원칙 1] 상단 고정 루트 정보
  final RecipeSummary? parentInfo; // Inspired by 정보
  final List<Ingredient> ingredients;
  final List<RecipeStep> steps;
  final List<String> imageUrls;
  final List<RecipeSummary> variants;
  final List<LogPostSummary> logs;
  final bool? isSavedByCurrentUser; // P1: 북마크 저장 여부

  RecipeDetail({
    required this.publicId,
    required this.foodName,
    required this.foodMasterPublicId,
    required this.title,
    required this.description,
    this.culinaryLocale,
    this.changeCategory,
    this.rootInfo,
    this.parentInfo,
    required this.ingredients,
    required this.steps,
    required this.imageUrls,
    required this.variants,
    required this.logs,
    this.isSavedByCurrentUser,
  });
}
