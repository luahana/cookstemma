import 'package:dio/dio.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/error/exceptions.dart';
import 'package:pairing_planet2_frontend/data/models/common/slice_response_dto.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/log_post_summary_dto.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';
import 'package:pairing_planet2_frontend/data/models/user/my_profile_response_dto.dart';
import 'package:pairing_planet2_frontend/data/models/user/update_profile_request_dto.dart';
import 'package:pairing_planet2_frontend/data/models/user/user_dto.dart';

class UserRemoteDataSource {
  final Dio _dio;

  UserRemoteDataSource(this._dio);

  /// 내 프로필 조회
  Future<MyProfileResponseDto> getMyProfile() async {
    try {
      final response = await _dio.get(ApiEndpoints.myProfile);

      if (response.statusCode == HttpStatus.ok) {
        return MyProfileResponseDto.fromJson(response.data);
      } else {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// 내 레시피 목록 조회
  Future<SliceResponseDto<RecipeSummaryDto>> getMyRecipes({
    required int page,
    int size = 10,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.myRecipes,
        queryParameters: {'page': page, 'size': size},
      );

      return SliceResponseDto.fromJson(
        response.data as Map<String, dynamic>,
        (json) => RecipeSummaryDto.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 내 로그 목록 조회
  Future<SliceResponseDto<LogPostSummaryDto>> getMyLogs({
    required int page,
    int size = 10,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.myLogs,
        queryParameters: {'page': page, 'size': size},
      );

      return SliceResponseDto.fromJson(
        response.data as Map<String, dynamic>,
        (json) => LogPostSummaryDto.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 저장한 레시피 목록 조회
  Future<SliceResponseDto<RecipeSummaryDto>> getSavedRecipes({
    required int page,
    int size = 10,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.savedRecipes,
        queryParameters: {'page': page, 'size': size},
      );

      return SliceResponseDto.fromJson(
        response.data as Map<String, dynamic>,
        (json) => RecipeSummaryDto.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 프로필 수정
  Future<UserDto> updateProfile(UpdateProfileRequestDto request) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.myProfile,
        data: request.toJson(),
      );

      if (response.statusCode == HttpStatus.ok) {
        return UserDto.fromJson(response.data);
      } else {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
