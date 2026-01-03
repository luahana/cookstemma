import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_detail_response_dto.dart';

class RecipeLocalDataSource {
  static const String _recipeBoxName = 'recipe_box';

  Future<void> cacheRecipeDetail(RecipeDetailResponseDto recipe) async {
    final box = await Hive.openBox(_recipeBoxName);
    // 이제 recipe.toJson()을 인식합니다.
    await box.put(recipe.publicId, jsonEncode(recipe.toJson()));
  }

  Future<RecipeDetailResponseDto?> getLastRecipeDetail(String publicId) async {
    final box = await Hive.openBox(_recipeBoxName);
    final jsonString = box.get(publicId);

    if (jsonString != null) {
      return RecipeDetailResponseDto.fromJson(jsonDecode(jsonString));
    }
    return null;
  }
}
