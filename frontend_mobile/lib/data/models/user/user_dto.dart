import 'package:json_annotation/json_annotation.dart';

part 'user_dto.g.dart';

@JsonSerializable()
class UserDto {
  final String id;
  final String username;
  final String? profileImageId;
  final String? profileImageUrl;
  final String? gender;
  final String? birthDate;
  final String? locale;  // 언어 설정: ko-KR, en-US
  final int followerCount;
  final int followingCount;
  final int recipeCount;  // Number of recipes created by user
  final int logCount;     // Number of logs created by user
  final int level;        // Gamification level (1-26+)
  final String levelName; // Level title (beginner, homeCook, etc.)

  UserDto({
    required this.id,
    required this.username,
    this.profileImageId,
    this.profileImageUrl,
    this.gender,
    this.birthDate,
    this.locale,
    this.followerCount = 0,
    this.followingCount = 0,
    this.recipeCount = 0,
    this.logCount = 0,
    this.level = 1,
    this.levelName = 'beginner',
  });

  factory UserDto.fromJson(Map<String, dynamic> json) => _$UserDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UserDtoToJson(this);
}
