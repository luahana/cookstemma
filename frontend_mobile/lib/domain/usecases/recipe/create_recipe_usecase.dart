import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../entities/recipe/create_recipe_request.dart';
import '../../repositories/recipe_repository.dart';

class CreateRecipeUseCase {
  final RecipeRepository _repository;

  CreateRecipeUseCase(this._repository);

  /// 레시피 생성을 실행합니다.
  Future<Either<Failure, String>> execute(
    CreateRecipeRequest request,
  ) async {
    return await _repository.createRecipe(request);
  }
}
