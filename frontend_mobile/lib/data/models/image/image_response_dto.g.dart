// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImageResponseDto _$ImageResponseDtoFromJson(Map<String, dynamic> json) =>
    ImageResponseDto(
      imagePublicId: json['imagePublicId'] as String,
      imageUrl: json['imageUrl'] as String?,
    );

Map<String, dynamic> _$ImageResponseDtoToJson(ImageResponseDto instance) =>
    <String, dynamic>{
      'imagePublicId': instance.imagePublicId,
      'imageUrl': instance.imageUrl,
    };
