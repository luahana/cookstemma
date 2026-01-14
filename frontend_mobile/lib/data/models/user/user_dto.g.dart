// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDto _$UserDtoFromJson(Map<String, dynamic> json) => UserDto(
      id: json['id'] as String,
      username: json['username'] as String,
      profileImageId: json['profileImageId'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      gender: json['gender'] as String?,
      birthDate: json['birthDate'] as String?,
      locale: json['locale'] as String?,
      defaultFoodStyle: json['defaultFoodStyle'] as String?,
      followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
      recipeCount: (json['recipeCount'] as num?)?.toInt() ?? 0,
      logCount: (json['logCount'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      levelName: json['levelName'] as String? ?? 'beginner',
      bio: json['bio'] as String?,
      youtubeUrl: json['youtubeUrl'] as String?,
      instagramHandle: json['instagramHandle'] as String?,
      termsAcceptedAt: json['termsAcceptedAt'] as String?,
      termsVersion: json['termsVersion'] as String?,
      privacyAcceptedAt: json['privacyAcceptedAt'] as String?,
      privacyVersion: json['privacyVersion'] as String?,
      marketingAgreed: json['marketingAgreed'] as bool?,
    );

Map<String, dynamic> _$UserDtoToJson(UserDto instance) => <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'profileImageId': instance.profileImageId,
      'profileImageUrl': instance.profileImageUrl,
      'gender': instance.gender,
      'birthDate': instance.birthDate,
      'locale': instance.locale,
      'defaultFoodStyle': instance.defaultFoodStyle,
      'followerCount': instance.followerCount,
      'followingCount': instance.followingCount,
      'recipeCount': instance.recipeCount,
      'logCount': instance.logCount,
      'level': instance.level,
      'levelName': instance.levelName,
      'bio': instance.bio,
      'youtubeUrl': instance.youtubeUrl,
      'instagramHandle': instance.instagramHandle,
      'termsAcceptedAt': instance.termsAcceptedAt,
      'termsVersion': instance.termsVersion,
      'privacyAcceptedAt': instance.privacyAcceptedAt,
      'privacyVersion': instance.privacyVersion,
      'marketingAgreed': instance.marketingAgreed,
    };
