import 'package:dio/dio.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/data/models/follow/follow_status_dto.dart';
import 'package:pairing_planet2_frontend/data/models/follow/follower_dto.dart';

class FollowRemoteDataSource {
  final Dio _dio;

  FollowRemoteDataSource(this._dio);

  /// Follow a user
  Future<void> follow(String userId) async {
    await _dio.post(ApiEndpoints.follow(userId));
  }

  /// Unfollow a user
  Future<void> unfollow(String userId) async {
    await _dio.delete(ApiEndpoints.follow(userId));
  }

  /// Get follow status for a user
  Future<FollowStatusDto> getFollowStatus(String userId) async {
    final response = await _dio.get(ApiEndpoints.followStatus(userId));
    return FollowStatusDto.fromJson(response.data);
  }

  /// Get followers of a user
  Future<FollowListResponse> getFollowers(
    String userId, {
    required int page,
    int size = 20,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.followers(userId),
      queryParameters: {'page': page, 'size': size},
    );
    return FollowListResponse.fromJson(response.data);
  }

  /// Get users that a user is following
  Future<FollowListResponse> getFollowing(
    String userId, {
    required int page,
    int size = 20,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.following(userId),
      queryParameters: {'page': page, 'size': size},
    );
    return FollowListResponse.fromJson(response.data);
  }
}
