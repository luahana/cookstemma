import 'package:dartz/dartz.dart'; // 👈 import 필수!
import 'package:pairing_planet2_frontend/data/models/common/paged_response_dto.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_detail.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';
import '../../core/error/failures.dart';

abstract class RecipeRepository {
  Future<Either<Failure, RecipeDetail>> getRecipeDetail(String publicId);

  Future<Either<Failure, PagedResponseDto<RecipeSummary>>> getRecipes({
    required int page,
    int size = 10,
  });
}
