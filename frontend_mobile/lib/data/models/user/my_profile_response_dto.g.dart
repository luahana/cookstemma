// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_profile_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MyProfileResponseDto _$MyProfileResponseDtoFromJson(
        Map<String, dynamic> json) =>
    MyProfileResponseDto(
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
      recipeCount: (json['recipeCount'] as num).toInt(),
      logCount: (json['logCount'] as num).toInt(),
      savedCount: (json['savedCount'] as num).toInt(),
    );

Map<String, dynamic> _$MyProfileResponseDtoToJson(
        MyProfileResponseDto instance) =>
    <String, dynamic>{
      'user': instance.user,
      'recipeCount': instance.recipeCount,
      'logCount': instance.logCount,
      'savedCount': instance.savedCount,
    };
