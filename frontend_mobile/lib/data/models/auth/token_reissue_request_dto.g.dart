// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_reissue_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokenReissueRequestDto _$TokenReissueRequestDtoFromJson(
        Map<String, dynamic> json) =>
    TokenReissueRequestDto(
      refreshToken: json['refreshToken'] as String,
    );

Map<String, dynamic> _$TokenReissueRequestDtoToJson(
        TokenReissueRequestDto instance) =>
    <String, dynamic>{
      'refreshToken': instance.refreshToken,
    };
