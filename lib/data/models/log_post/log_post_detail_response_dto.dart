import 'package:json_annotation/json_annotation.dart';
import 'package:pairing_planet2_frontend/data/models/image/image_response_dto.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_detail.dart';

part 'log_post_detail_response_dto.g.dart';

@JsonSerializable()
class LogPostDetailResponseDto {
  final String publicId;
  final String? title;
  final String content;
  final int rating;
  final List<ImageResponseDto>? images;
  final RecipeSummaryDto? linkedRecipe;
  final String createdAt;

  LogPostDetailResponseDto({
    required this.publicId,
    required this.title,
    required this.content,
    required this.rating,
    required this.images,
    required this.linkedRecipe,
    required this.createdAt,
  });

  factory LogPostDetailResponseDto.fromJson(Map<String, dynamic> json) =>
      _$LogPostDetailResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$LogPostDetailResponseDtoToJson(this);

  // 💡 수정된 매핑 로직
  LogPostDetail toEntity() => LogPostDetail(
    publicId: publicId,
    content: content,
    rating: rating.toDouble(), // 💡 int를 엔티티의 double 타입으로 변환
    imageUrls:
        images?.map((img) => img.imageUrl).toList() ??
        [], // 💡 객체 리스트를 URL 문자열 리스트로 변환
    recipePublicId: linkedRecipe?.publicId ?? "",
    createdAt: DateTime.parse(createdAt),
  );
}
