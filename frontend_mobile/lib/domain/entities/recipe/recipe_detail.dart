import 'ingredient.dart';
import 'recipe_step.dart';
import 'recipe_summary.dart';
import '../log_post/log_post_summary.dart';
import '../hashtag/hashtag.dart';

class RecipeDetail {
  final String publicId;
  final String foodName;
  final String foodMasterPublicId;
  final String title;
  final String? description;
  final String? culinaryLocale;
  final String? changeCategory;
  final RecipeSummary? rootInfo;
  final RecipeSummary? parentInfo;
  final List<Ingredient> ingredients;
  final List<RecipeStep> steps;
  final List<String> imageUrls;
  final List<RecipeSummary> variants;
  final List<LogPostSummary> logs;
  final List<Hashtag> hashtags;
  final bool? isSavedByCurrentUser;

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
    required this.hashtags,
    this.isSavedByCurrentUser,
  });
}
