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
      ApiEndpoints.log_posts,
      data: request.toJson(),
    );
    return LogPostDetailResponseDto.fromJson(response.data);
  }

  Future<LogPostDetailResponseDto> getLogDetail(String publicId) async {
    final response = await _dio.get('${ApiEndpoints.log_posts}/$publicId');
    return LogPostDetailResponseDto.fromJson(response.data);
  }

  Future<SliceResponseDto<LogPostSummaryDto>> getLogPosts({
    int page = 0,
    int size = 20,
    String? query,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
    };
    if (query != null && query.isNotEmpty) {
      queryParams['q'] = query;
    }

    final response = await _dio.get(
      ApiEndpoints.log_posts,
      queryParameters: queryParams,
    );

    return SliceResponseDto.fromJson(
      response.data as Map<String, dynamic>,
      (json) => LogPostSummaryDto.fromJson(json),
    );
  }
}
