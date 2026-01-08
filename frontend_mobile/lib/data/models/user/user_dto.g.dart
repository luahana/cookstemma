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
      followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$UserDtoToJson(UserDto instance) => <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'profileImageId': instance.profileImageId,
      'profileImageUrl': instance.profileImageUrl,
      'gender': instance.gender,
      'birthDate': instance.birthDate,
      'locale': instance.locale,
      'followerCount': instance.followerCount,
      'followingCount': instance.followingCount,
    };
