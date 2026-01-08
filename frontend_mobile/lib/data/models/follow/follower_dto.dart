import 'package:json_annotation/json_annotation.dart';

part 'follower_dto.g.dart';

@JsonSerializable()
class FollowerDto {
  final String publicId;
  final String username;
  final String? profileImageUrl;
  final bool? isFollowingBack;
  final String? followedAt;

  FollowerDto({
    required this.publicId,
    required this.username,
    this.profileImageUrl,
    this.isFollowingBack,
    this.followedAt,
  });

  factory FollowerDto.fromJson(Map<String, dynamic> json) =>
      _$FollowerDtoFromJson(json);
  Map<String, dynamic> toJson() => _$FollowerDtoToJson(this);
}

@JsonSerializable()
class FollowListResponse {
  final List<FollowerDto> content;
  final bool hasNext;
  final int page;
  final int size;

  FollowListResponse({
    required this.content,
    required this.hasNext,
    required this.page,
    required this.size,
  });

  factory FollowListResponse.fromJson(Map<String, dynamic> json) =>
      _$FollowListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$FollowListResponseToJson(this);
}
