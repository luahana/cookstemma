// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_post_detail_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LogPostDetailResponseDto _$LogPostDetailResponseDtoFromJson(
        Map<String, dynamic> json) =>
    LogPostDetailResponseDto(
      publicId: json['publicId'] as String,
      title: json['title'] as String?,
      content: json['content'] as String,
      outcome: json['outcome'] as String?,
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => ImageResponseDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      linkedRecipe: json['linkedRecipe'] == null
          ? null
          : RecipeSummaryDto.fromJson(
              json['linkedRecipe'] as Map<String, dynamic>),
      createdAt: json['createdAt'] as String,
      hashtags: (json['hashtags'] as List<dynamic>?)
          ?.map((e) => HashtagDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      isSavedByCurrentUser: json['isSavedByCurrentUser'] as bool?,
    );

Map<String, dynamic> _$LogPostDetailResponseDtoToJson(
        LogPostDetailResponseDto instance) =>
    <String, dynamic>{
      'publicId': instance.publicId,
      'title': instance.title,
      'content': instance.content,
      'outcome': instance.outcome,
      'images': instance.images,
      'linkedRecipe': instance.linkedRecipe,
      'createdAt': instance.createdAt,
      'hashtags': instance.hashtags,
      'isSavedByCurrentUser': instance.isSavedByCurrentUser,
    };
