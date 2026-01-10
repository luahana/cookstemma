import 'package:json_annotation/json_annotation.dart';
import 'package:pairing_planet2_frontend/data/models/image/image_response_dto.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';
import 'package:pairing_planet2_frontend/data/models/hashtag/hashtag_dto.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_detail.dart';

part 'log_post_detail_response_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class LogPostDetailResponseDto {
  final String publicId;
  final String? title;
  final String content;
  final String? outcome; // SUCCESS, PARTIAL, FAILED (nullable for backward compat)
  final List<ImageResponseDto>? images;
  final RecipeSummaryDto? linkedRecipe;
  final String createdAt;
  final List<HashtagDto>? hashtags;
  final bool? isSavedByCurrentUser;
  final String? creatorPublicId; // For ownership check (UUID string)

  LogPostDetailResponseDto({
    required this.publicId,
    required this.title,
    required this.content,
    this.outcome,
    required this.images,
    required this.linkedRecipe,
    required this.createdAt,
    this.hashtags,
    this.isSavedByCurrentUser,
    this.creatorPublicId,
  });

  factory LogPostDetailResponseDto.fromJson(Map<String, dynamic> json) =>
      _$LogPostDetailResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$LogPostDetailResponseDtoToJson(this);

  LogPostDetail toEntity() {
    return LogPostDetail(
      publicId: publicId,
      content: content,
      outcome: outcome ?? 'PARTIAL', // Default to PARTIAL if null
      imageUrls: images?.map((img) => img.imageUrl).toList() ?? [],
      imagePublicIds: images?.map((img) => img.imagePublicId).toList() ?? [],
      recipePublicId: linkedRecipe?.publicId ?? "",
      linkedRecipe: linkedRecipe != null
          ? LinkedRecipeInfo.fromRecipeSummary(linkedRecipe!.toEntity())
          : null,
      createdAt: DateTime.parse(createdAt),
      hashtags: hashtags?.map((e) => e.toEntity()).toList() ?? [],
      isSavedByCurrentUser: isSavedByCurrentUser,
      creatorPublicId: creatorPublicId,
    );
  }
}
