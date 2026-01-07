import 'package:json_annotation/json_annotation.dart';

part 'image_response_dto.g.dart';

@JsonSerializable()
class ImageResponseDto {
  final String imagePublicId; // UUID
  final String? imageUrl; // 이미지 전체 경로

  ImageResponseDto({required this.imagePublicId, required this.imageUrl});

  factory ImageResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ImageResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ImageResponseDtoToJson(this);
}
