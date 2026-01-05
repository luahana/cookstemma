import 'package:json_annotation/json_annotation.dart';
part 'create_log_post_request_dto.g.dart';

@JsonSerializable()
class CreateLogPostRequestDto {
  final String recipePublicId;
  final String content;
  final double rating;
  final List<String> imagePublicIds;

  CreateLogPostRequestDto({
    required this.recipePublicId,
    required this.content,
    required this.rating,
    required this.imagePublicIds,
  });

  Map<String, dynamic> toJson() => _$CreateLogPostRequestDtoToJson(this);
}
