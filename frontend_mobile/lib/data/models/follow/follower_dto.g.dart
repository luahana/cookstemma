// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follower_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FollowerDto _$FollowerDtoFromJson(Map<String, dynamic> json) => FollowerDto(
      publicId: json['publicId'] as String,
      username: json['username'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      isFollowingBack: json['isFollowingBack'] as bool?,
      followedAt: json['followedAt'] as String?,
    );

Map<String, dynamic> _$FollowerDtoToJson(FollowerDto instance) =>
    <String, dynamic>{
      'publicId': instance.publicId,
      'username': instance.username,
      'profileImageUrl': instance.profileImageUrl,
      'isFollowingBack': instance.isFollowingBack,
      'followedAt': instance.followedAt,
    };

FollowListResponse _$FollowListResponseFromJson(Map<String, dynamic> json) =>
    FollowListResponse(
      content: (json['content'] as List<dynamic>)
          .map((e) => FollowerDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasNext: json['hasNext'] as bool,
      page: (json['page'] as num).toInt(),
      size: (json['size'] as num).toInt(),
    );

Map<String, dynamic> _$FollowListResponseToJson(FollowListResponse instance) =>
    <String, dynamic>{
      'content': instance.content,
      'hasNext': instance.hasNext,
      'page': instance.page,
      'size': instance.size,
    };
