// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_log_post_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateLogPostRequestDto _$UpdateLogPostRequestDtoFromJson(
        Map<String, dynamic> json) =>
    UpdateLogPostRequestDto(
      title: json['title'] as String?,
      content: json['content'] as String,
      outcome: json['outcome'] as String,
      hashtags: (json['hashtags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      imagePublicIds: (json['imagePublicIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$UpdateLogPostRequestDtoToJson(
        UpdateLogPostRequestDto instance) =>
    <String, dynamic>{
      'title': instance.title,
      'content': instance.content,
      'outcome': instance.outcome,
      'hashtags': instance.hashtags,
      'imagePublicIds': instance.imagePublicIds,
    };
