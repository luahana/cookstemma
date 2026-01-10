import 'package:json_annotation/json_annotation.dart';

part 'update_log_post_request_dto.g.dart';

@JsonSerializable()
class UpdateLogPostRequestDto {
  final String? title;
  final String content;
  final String outcome; // SUCCESS, PARTIAL, FAILED
  final List<String>? hashtags;
  final List<String>? imagePublicIds; // Update images if provided

  UpdateLogPostRequestDto({
    this.title,
    required this.content,
    required this.outcome,
    this.hashtags,
    this.imagePublicIds,
  });

  factory UpdateLogPostRequestDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateLogPostRequestDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateLogPostRequestDtoToJson(this);
}
