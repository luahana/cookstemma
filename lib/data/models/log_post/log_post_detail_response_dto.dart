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
  final String? outcome; // SUCCESS, PARTIAL, FAILED (nullable for backward compat)
  final List<ImageResponseDto>? images;
  final RecipeSummaryDto? linkedRecipe;
  final String createdAt;

  LogPostDetailResponseDto({
    required this.publicId,
    required this.title,
    required this.content,
    this.outcome,
    required this.images,
    required this.linkedRecipe,
    required this.createdAt,
  });

  factory LogPostDetailResponseDto.fromJson(Map<String, dynamic> json) =>
      _$LogPostDetailResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$LogPostDetailResponseDtoToJson(this);

  LogPostDetail toEntity() => LogPostDetail(
    publicId: publicId,
    content: content,
    outcome: outcome ?? 'PARTIAL', // Default to PARTIAL if null
    imageUrls: images?.map((img) => img.imageUrl).toList() ?? [],
    recipePublicId: linkedRecipe?.publicId ?? "",
    createdAt: DateTime.parse(createdAt),
  );
}
