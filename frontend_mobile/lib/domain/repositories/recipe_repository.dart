import 'package:dartz/dartz.dart'; // 👈 import 필수!
import 'package:pairing_planet2_frontend/domain/entities/common/slice_response.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/create_recipe_request.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_detail.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_modifiable.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/update_recipe_request.dart';
import '../../core/error/failures.dart';

abstract class RecipeRepository {
  Future<Either<Failure, String>> createRecipe(CreateRecipeRequest recipe);

  Future<Either<Failure, RecipeDetail>> getRecipeDetail(String publicId);

  Future<Either<Failure, SliceResponse<RecipeSummary>>> getRecipes({
    required int page,
    int size = 10,
    String? query,
    String? cuisineFilter,
    String? typeFilter,
    String? sortBy,
  });

  // P1: 레시피 저장/저장취소
  Future<Either<Failure, void>> saveRecipe(String publicId);
  Future<Either<Failure, void>> unsaveRecipe(String publicId);

  // Recipe modification (edit/delete)
  Future<Either<Failure, RecipeModifiable>> checkRecipeModifiable(String publicId);
  Future<Either<Failure, RecipeDetail>> updateRecipe(String publicId, UpdateRecipeRequest request);
  Future<Either<Failure, void>> deleteRecipe(String publicId);
}
