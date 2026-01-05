import 'package:dio/dio.dart';
import 'package:pairing_planet2_frontend/data/models/common/paged_response_dto.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_detail_response_dto.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/create_recipe_request_dtos.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';
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
      print("❌ JSON Parsing Error: $e");
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

  Future<PagedResponseDto<RecipeSummaryDto>> getRecipes({
    required int page,
    int size = 10,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.recipes,
        queryParameters: {'page': page, 'size': size},
      );

      final data = response.data;

      return PagedResponseDto<RecipeSummaryDto>(
        // 💡 핵심 수정: Spring Slice는 'items'가 아니라 'content'를 사용합니다.
        items: (data['content'] as List)
            .map((e) => RecipeSummaryDto.fromJson(e))
            .toList(),
        // 💡 Spring Slice/Page 필드명에 맞춰 수정
        currentPage: data['number'] ?? 0,
        totalPages: data['totalPages'] ?? 1,
        hasNext: data['last'] == false, // 'last'가 false면 다음 페이지가 있음
      );
    } catch (e) {
      rethrow; // Repository에서 잡을 수 있도록 던짐
    }
  }
}
