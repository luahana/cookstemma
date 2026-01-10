import 'package:json_annotation/json_annotation.dart';
import 'package:pairing_planet2_frontend/domain/entities/hashtag/hashtag.dart';

part 'hashtag_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class HashtagDto {
  final String publicId;
  final String name;

  HashtagDto({
    required this.publicId,
    required this.name,
  });

  factory HashtagDto.fromJson(Map<String, dynamic> json) =>
      _$HashtagDtoFromJson(json);

  Map<String, dynamic> toJson() => _$HashtagDtoToJson(this);

  Hashtag toEntity() => Hashtag(
        publicId: publicId,
        name: name,
      );
}
