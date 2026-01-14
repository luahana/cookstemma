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
  final String? defaultFoodStyle;  // 기본 요리 스타일: ISO country code (e.g., "KR", "US")
  final int followerCount;
  final int followingCount;
  final int recipeCount;  // Number of recipes created by user
  final int logCount;     // Number of logs created by user
  final int level;        // Gamification level (1-26+)
  final String levelName; // Level title (beginner, homeCook, etc.)
  final String? bio;      // User bio/description (max 150 chars)
  final String? youtubeUrl;  // YouTube channel URL
  final String? instagramHandle;  // Instagram handle (without @)

  // Legal acceptance fields
  final String? termsAcceptedAt;
  final String? termsVersion;
  final String? privacyAcceptedAt;
  final String? privacyVersion;
  final bool? marketingAgreed;

  UserDto({
    required this.id,
    required this.username,
    this.profileImageId,
    this.profileImageUrl,
    this.gender,
    this.birthDate,
    this.locale,
    this.defaultFoodStyle,
    this.followerCount = 0,
    this.followingCount = 0,
    this.recipeCount = 0,
    this.logCount = 0,
    this.level = 1,
    this.levelName = 'beginner',
    this.bio,
    this.youtubeUrl,
    this.instagramHandle,
    this.termsAcceptedAt,
    this.termsVersion,
    this.privacyAcceptedAt,
    this.privacyVersion,
    this.marketingAgreed,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) => _$UserDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UserDtoToJson(this);
}
