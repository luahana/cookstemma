import 'package:dio/dio.dart';
import 'package:pairing_planet2_frontend/data/models/common/cursor_page_response_dto.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_detail_response_dto.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/create_recipe_request_dtos.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_modifiable_dto.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/update_recipe_request_dto.dart';
import '../../../core/constants/constants.dart';
import '../../../core/error/exceptions.dart';
import '../../models/home/home_feed_response_dto.dart';

class RecipeRemoteDataSource {
  final Dio _dio;

  RecipeRemoteDataSource(this._dio);

  Future<String> createRecipe(CreateRecipeRequestDto recipe) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.recipes, // 보통 조회와 등록 엔드포인트는 동일(POST)합니다.
        data: recipe.toJson(),
      );

      if (response.statusCode != HttpStatus.ok &&
          response.statusCode != HttpStatus.created) {
        throw ServerException();
      }
      return response.data['publicId'] as String;
    } on DioException catch (e) {
      throw ServerException(e.message ?? "서버 응답 에러");
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// 레시피 상세 조회
  Future<RecipeDetailResponseDto> getRecipeDetail(String publicId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.recipeDetail(publicId),
      ); // 상수 사용

      if (response.statusCode == HttpStatus.ok) {
        return RecipeDetailResponseDto.fromJson(response.data); //
      } else {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// 홈 피드 조회 (최근 레시피 및 트렌딩 트리)
  Future<HomeFeedResponseDto> getHomeFeed() async {
    try {
      final response = await _dio.get(ApiEndpoints.homeFeed); // 상수 사용

      if (response.statusCode == HttpStatus.ok) {
        return HomeFeedResponseDto.fromJson(response.data); //
      } else {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// Get recipes with cursor-based pagination
  Future<CursorPageResponseDto<RecipeSummaryDto>> getRecipes({
    String? cursor,
    int size = 20,
    String? query,
    String? cuisineFilter,
    String? typeFilter, // 'original', 'variant', or null for all
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'size': size,
      };
      if (cursor != null && cursor.isNotEmpty) {
        queryParams['cursor'] = cursor;
      }
      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }
      if (cuisineFilter != null && cuisineFilter.isNotEmpty) {
        queryParams['locale'] = cuisineFilter;
      }
      // Map frontend filter to backend parameter
      if (typeFilter == 'original') {
        queryParams['onlyRoot'] = true;
      } else if (typeFilter == 'variant') {
        queryParams['typeFilter'] = 'variant';
      }

      final response = await _dio.get(
        ApiEndpoints.recipes,
        queryParameters: queryParams,
      );

      return CursorPageResponseDto.fromJson(
        response.data as Map<String, dynamic>,
        (json) => RecipeSummaryDto.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// P1: 레시피 저장 (북마크)
  Future<void> saveRecipe(String publicId) async {
    try {
      final response = await _dio.post(ApiEndpoints.recipeSave(publicId));
      if (response.statusCode != HttpStatus.ok) {
        throw ServerException();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// P1: 레시피 저장 취소
  Future<void> unsaveRecipe(String publicId) async {
    try {
      final response = await _dio.delete(ApiEndpoints.recipeSave(publicId));
      if (response.statusCode != HttpStatus.ok) {
        throw ServerException();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Check if recipe can be modified (edited/deleted)
  Future<RecipeModifiableDto> checkRecipeModifiable(String publicId) async {
    try {
      final response = await _dio.get(ApiEndpoints.recipeModifiable(publicId));
      if (response.statusCode == HttpStatus.ok) {
        return RecipeModifiableDto.fromJson(response.data);
      } else {
        throw ServerException();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update recipe in-place
  Future<RecipeDetailResponseDto> updateRecipe(
    String publicId,
    UpdateRecipeRequestDto request,
  ) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.recipeDetail(publicId),
        data: request.toJson(),
      );
      if (response.statusCode == HttpStatus.ok) {
        return RecipeDetailResponseDto.fromJson(response.data);
      } else {
        throw ServerException();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete recipe (soft delete)
  Future<void> deleteRecipe(String publicId) async {
    try {
      final response = await _dio.delete(ApiEndpoints.recipeDetail(publicId));
      if (response.statusCode != HttpStatus.ok &&
          response.statusCode != HttpStatus.noContent) {
        throw ServerException();
      }
    } catch (e) {
      rethrow;
    }
  }
}
