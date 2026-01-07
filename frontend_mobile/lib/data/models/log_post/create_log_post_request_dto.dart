import 'package:json_annotation/json_annotation.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/create_log_post_request.dart';

part 'create_log_post_request_dto.g.dart';

@JsonSerializable()
class CreateLogPostRequestDto {
  final String recipePublicId;
  final String content;
  final String outcome; // SUCCESS, PARTIAL, FAILED
  final String? title;
  final List<String> imagePublicIds;
  final List<String>? hashtags;

  CreateLogPostRequestDto({
    required this.recipePublicId,
    required this.content,
    required this.outcome,
    this.title,
    required this.imagePublicIds,
    this.hashtags,
  });

  Map<String, dynamic> toJson() => _$CreateLogPostRequestDtoToJson(this);

  factory CreateLogPostRequestDto.fromEntity(CreateLogPostRequest request) {
    return CreateLogPostRequestDto(
      recipePublicId: request.recipePublicId,
      content: request.content,
      outcome: request.outcome,
      title: request.title,
      imagePublicIds: request.imagePublicIds,
      hashtags: request.hashtags,
    );
  }
}
