import 'package:dio/dio.dart';
import 'package:pairing_planet2_frontend/data/models/common/paged_response_dto.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_detail_response_dto.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';
import '../../core/constants/api_constants.dart';
import '../../core/error/exceptions.dart';
import '../models/home_feed_response_dto.dart';

class RecipeRemoteDataSource {
  final Dio _dio;

  RecipeRemoteDataSource(this._dio);

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

  Future<PagedResponseDto<RecipeSummaryDto>> getRecipes({
    required int page,
    int size = 10,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.recipes,
        queryParameters: {'page': page, 'size': size},
      );

      if (response.statusCode == HttpStatus.ok) {
        final data = response.data;
        return PagedResponseDto(
          items: (data['items'] as List)
              .map((e) => RecipeSummaryDto.fromJson(e))
              .toList(),
          currentPage: data['currentPage'],
          totalPages: data['totalPages'],
          hasNext: data['hasNext'],
        );
      } else {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
