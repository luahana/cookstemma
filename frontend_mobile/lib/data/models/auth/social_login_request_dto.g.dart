// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_login_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SocialLoginRequestDto _$SocialLoginRequestDtoFromJson(
        Map<String, dynamic> json) =>
    SocialLoginRequestDto(
      idToken: json['idToken'] as String,
      locale: json['locale'] as String,
    );

Map<String, dynamic> _$SocialLoginRequestDtoToJson(
        SocialLoginRequestDto instance) =>
    <String, dynamic>{
      'idToken': instance.idToken,
      'locale': instance.locale,
    };
