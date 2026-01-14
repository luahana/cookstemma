import 'package:dio/dio.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/data/models/common/cursor_page_response_dto.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/create_log_post_request_dto.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/log_post_detail_response_dto.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/log_post_summary_dto.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/update_log_post_request_dto.dart';
import 'package:pairing_planet2_frontend/data/models/common/slice_response_dto.dart';

class LogPostRemoteDataSource {
  final Dio _dio;
  LogPostRemoteDataSource(this._dio);

  Future<LogPostDetailResponseDto> createLog(
    CreateLogPostRequestDto request,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.logPosts,
      data: request.toJson(),
    );
    return LogPostDetailResponseDto.fromJson(response.data);
  }

  Future<LogPostDetailResponseDto> getLogDetail(String publicId) async {
    final response = await _dio.get('${ApiEndpoints.logPosts}/$publicId');
    return LogPostDetailResponseDto.fromJson(response.data);
  }

  /// 로그 수정
  Future<LogPostDetailResponseDto> updateLog(
    String publicId,
    UpdateLogPostRequestDto request,
  ) async {
    final response = await _dio.put(
      '${ApiEndpoints.logPosts}/$publicId',
      data: request.toJson(),
    );
    return LogPostDetailResponseDto.fromJson(response.data);
  }

  /// 로그 삭제
  Future<void> deleteLog(String publicId) async {
    await _dio.delete('${ApiEndpoints.logPosts}/$publicId');
  }

  /// Get logs with cursor-based pagination
  Future<CursorPageResponseDto<LogPostSummaryDto>> getLogPosts({
    String? cursor,
    int size = 20,
    String? query,
    List<String>? outcomes,
  }) async {
    final queryParams = <String, dynamic>{
      'size': size,
    };
    if (cursor != null && cursor.isNotEmpty) {
      queryParams['cursor'] = cursor;
    }
    if (query != null && query.isNotEmpty) {
      queryParams['q'] = query;
    }
    if (outcomes != null && outcomes.isNotEmpty) {
      queryParams['outcomes'] = outcomes.join(',');
    }

    final response = await _dio.get(
      ApiEndpoints.logPosts,
      queryParameters: queryParams,
    );

    return CursorPageResponseDto.fromJson(
      response.data as Map<String, dynamic>,
      (json) => LogPostSummaryDto.fromJson(json),
    );
  }

  /// 특정 레시피의 로그 목록 조회
  Future<SliceResponseDto<LogPostSummaryDto>> getLogsByRecipe({
    required String recipeId,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.logsByRecipe(recipeId),
      queryParameters: {'page': page, 'size': size},
    );
    return SliceResponseDto.fromJson(
      response.data as Map<String, dynamic>,
      (json) => LogPostSummaryDto.fromJson(json),
    );
  }

  /// 로그 저장 (북마크)
  Future<void> saveLog(String publicId) async {
    await _dio.post(ApiEndpoints.logPostSave(publicId));
  }

  /// 로그 저장 취소
  Future<void> unsaveLog(String publicId) async {
    await _dio.delete(ApiEndpoints.logPostSave(publicId));
  }

  /// 저장한 로그 목록 조회 (cursor-based pagination)
  Future<CursorPageResponseDto<LogPostSummaryDto>> getSavedLogs({
    String? cursor,
    int size = 20,
  }) async {
    final queryParams = <String, dynamic>{'size': size};
    if (cursor != null && cursor.isNotEmpty) {
      queryParams['cursor'] = cursor;
    }
    final response = await _dio.get(
      ApiEndpoints.savedLogs,
      queryParameters: queryParams,
    );
    return CursorPageResponseDto.fromJson(
      response.data as Map<String, dynamic>,
      (json) => LogPostSummaryDto.fromJson(json),
    );
  }
}
