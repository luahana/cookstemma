import 'package:dio/dio.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/data/models/common/cursor_page_response_dto.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/log_post_summary_dto.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';

class HashtagRemoteDataSource {
  final Dio _dio;

  HashtagRemoteDataSource(this._dio);

  /// Fetch recipes tagged with the given hashtag.
  Future<CursorPageResponseDto<RecipeSummaryDto>> getRecipesByHashtag({
    required String hashtagName,
    String? cursor,
    int size = 20,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.hashtagRecipes(hashtagName),
      queryParameters: {
        if (cursor != null) 'cursor': cursor,
        'size': size,
      },
    );

    return CursorPageResponseDto.fromJson(
      response.data as Map<String, dynamic>,
      (json) => RecipeSummaryDto.fromJson(json),
    );
  }

  /// Fetch log posts tagged with the given hashtag.
  Future<CursorPageResponseDto<LogPostSummaryDto>> getLogPostsByHashtag({
    required String hashtagName,
    String? cursor,
    int size = 20,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.hashtagLogPosts(hashtagName),
      queryParameters: {
        if (cursor != null) 'cursor': cursor,
        'size': size,
      },
    );

    return CursorPageResponseDto.fromJson(
      response.data as Map<String, dynamic>,
      (json) => LogPostSummaryDto.fromJson(json),
    );
  }
}
