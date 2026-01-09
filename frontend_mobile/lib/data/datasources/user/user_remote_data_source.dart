import 'package:dio/dio.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/error/exceptions.dart';
import 'package:pairing_planet2_frontend/data/models/common/slice_response_dto.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/log_post_summary_dto.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';
import 'package:pairing_planet2_frontend/data/models/user/cooking_dna_dto.dart';
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

  /// 내 Cooking DNA 조회 (XP, 레벨, 성공률, 요리 분포 등)
  Future<CookingDnaDto> getCookingDna() async {
    try {
      final response = await _dio.get(ApiEndpoints.myCookingDna);

      if (response.statusCode == HttpStatus.ok) {
        return CookingDnaDto.fromJson(response.data);
      } else {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// 내 레시피 목록 조회
  /// [typeFilter] - 'original', 'variants', or null for all
  Future<SliceResponseDto<RecipeSummaryDto>> getMyRecipes({
    required int page,
    int size = 10,
    String? typeFilter,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'size': size};
      if (typeFilter != null && typeFilter.isNotEmpty) {
        queryParams['typeFilter'] = typeFilter;
      }

      final response = await _dio.get(
        ApiEndpoints.myRecipes,
        queryParameters: queryParams,
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
  /// [outcome] - 'SUCCESS', 'PARTIAL', 'FAILED', or null for all
  Future<SliceResponseDto<LogPostSummaryDto>> getMyLogs({
    required int page,
    int size = 10,
    String? outcome,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'size': size};
      if (outcome != null && outcome.isNotEmpty) {
        queryParams['outcome'] = outcome;
      }

      final response = await _dio.get(
        ApiEndpoints.myLogs,
        queryParameters: queryParams,
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

  /// 계정 삭제 (30일 유예 기간 후 완전 삭제)
  Future<void> deleteAccount() async {
    try {
      final response = await _dio.delete(ApiEndpoints.myProfile);

      if (response.statusCode != HttpStatus.ok &&
          response.statusCode != HttpStatus.noContent) {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
