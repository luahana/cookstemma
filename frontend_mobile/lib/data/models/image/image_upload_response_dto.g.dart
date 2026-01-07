// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_upload_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImageUploadResponseDto _$ImageUploadResponseDtoFromJson(
        Map<String, dynamic> json) =>
    ImageUploadResponseDto(
      imagePublicId: json['imagePublicId'] as String,
      imageUrl: json['imageUrl'] as String,
      originalFilename: json['originalFilename'] as String,
    );

Map<String, dynamic> _$ImageUploadResponseDtoToJson(
        ImageUploadResponseDto instance) =>
    <String, dynamic>{
      'imagePublicId': instance.imagePublicId,
      'imageUrl': instance.imageUrl,
      'originalFilename': instance.originalFilename,
    };
