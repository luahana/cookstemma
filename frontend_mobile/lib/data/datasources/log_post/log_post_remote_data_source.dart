import 'package:dio/dio.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/create_log_post_request_dto.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/log_post_detail_response_dto.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/log_post_summary_dto.dart';
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

  Future<SliceResponseDto<LogPostSummaryDto>> getLogPosts({
    int page = 0,
    int size = 20,
    String? query,
    List<String>? outcomes,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
    };
    if (query != null && query.isNotEmpty) {
      queryParams['q'] = query;
    }
    if (outcomes != null && outcomes.isNotEmpty) {
      // Send outcomes as comma-separated string or array based on API spec
      queryParams['outcomes'] = outcomes.join(',');
    }

    final response = await _dio.get(
      ApiEndpoints.logPosts,
      queryParameters: queryParams,
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

  /// 저장한 로그 목록 조회
  Future<SliceResponseDto<LogPostSummaryDto>> getSavedLogs({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.savedLogs,
      queryParameters: {'page': page, 'size': size},
    );
    return SliceResponseDto.fromJson(
      response.data as Map<String, dynamic>,
      (json) => LogPostSummaryDto.fromJson(json),
    );
  }
}
