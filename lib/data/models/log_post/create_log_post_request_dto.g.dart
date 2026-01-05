// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_log_post_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateLogPostRequestDto _$CreateLogPostRequestDtoFromJson(
  Map<String, dynamic> json,
) => CreateLogPostRequestDto(
  recipePublicId: json['recipePublicId'] as String,
  content: json['content'] as String,
  rating: (json['rating'] as num).toDouble(),
  imagePublicIds: (json['imagePublicIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$CreateLogPostRequestDtoToJson(
  CreateLogPostRequestDto instance,
) => <String, dynamic>{
  'recipePublicId': instance.recipePublicId,
  'content': instance.content,
  'rating': instance.rating,
  'imagePublicIds': instance.imagePublicIds,
};
