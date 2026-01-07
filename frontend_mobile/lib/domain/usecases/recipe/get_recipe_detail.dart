import 'package:dartz/dartz.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_detail.dart';
import 'package:pairing_planet2_frontend/domain/repositories/recipe_repository.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecase/usecase.dart';

class GetRecipeDetailUseCase implements UseCase<RecipeDetail, String> {
  final RecipeRepository repository;

  GetRecipeDetailUseCase(this.repository);

  @override
  Future<Either<Failure, RecipeDetail>> call(String publicId) async {
    final result = await repository.getRecipeDetail(publicId);

    // [비즈니스 로직 적용 공간]
    // 💡 레포지토리에서 데이터를 받은 후, 가공하거나 검증하는 로직을 여기서 수행합니다.
    return result.map((recipe) {
      if (recipe.logs.isEmpty) {
        // 예: 로그가 비어있을 때 UI에서 보여줄 별도의 안내 상태를
        // 엔티티 내에 플래그값으로 설정하거나 가공할 수 있습니다.
        print("Business Rule: 이 레시피는 아직 첫 기록이 없습니다. 도전자가 되어보세요!");
      }
      return recipe;
    });
  }
}
