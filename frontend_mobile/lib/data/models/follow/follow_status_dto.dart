import 'package:json_annotation/json_annotation.dart';

part 'follow_status_dto.g.dart';

@JsonSerializable()
class FollowStatusDto {
  final bool isFollowing;

  FollowStatusDto({
    required this.isFollowing,
  });

  factory FollowStatusDto.fromJson(Map<String, dynamic> json) =>
      _$FollowStatusDtoFromJson(json);
  Map<String, dynamic> toJson() => _$FollowStatusDtoToJson(this);
}
