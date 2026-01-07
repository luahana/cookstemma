// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_log_post_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateLogPostRequestDto _$CreateLogPostRequestDtoFromJson(
        Map<String, dynamic> json) =>
    CreateLogPostRequestDto(
      recipePublicId: json['recipePublicId'] as String,
      content: json['content'] as String,
      outcome: json['outcome'] as String,
      title: json['title'] as String?,
      imagePublicIds: (json['imagePublicIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      hashtags: (json['hashtags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$CreateLogPostRequestDtoToJson(
        CreateLogPostRequestDto instance) =>
    <String, dynamic>{
      'recipePublicId': instance.recipePublicId,
      'content': instance.content,
      'outcome': instance.outcome,
      'title': instance.title,
      'imagePublicIds': instance.imagePublicIds,
      'hashtags': instance.hashtags,
    };
