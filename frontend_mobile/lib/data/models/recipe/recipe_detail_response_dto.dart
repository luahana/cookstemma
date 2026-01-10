import 'package:json_annotation/json_annotation.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_detail.dart';
import '../image/image_response_dto.dart';
import '../log_post/log_post_summary_dto.dart';
import '../hashtag/hashtag_dto.dart';
import 'recipe_summary_dto.dart';
import 'ingredient_dto.dart';
import 'step_dto.dart';

part 'recipe_detail_response_dto.g.dart';

// Helper function to safely parse changeReason which might be String or Map
String? _parseChangeReason(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is Map) {
    // If it's a Map, try to extract a meaningful string or convert to JSON string
    if (value.containsKey('reason')) return value['reason']?.toString();
    if (value.containsKey('text')) return value['text']?.toString();
    // Fallback: return null if we can't extract a string
    return null;
  }
  return value.toString();
}

@JsonSerializable()
class RecipeDetailResponseDto {
  final String publicId;
  final String foodName;
  final String foodMasterPublicId;
  final String title;
  final String? description;
  final String? culinaryLocale;
  final String? changeCategory;
  final RecipeSummaryDto? rootInfo;
  final RecipeSummaryDto? parentInfo;

  final List<IngredientDto>? ingredients;
  final List<StepDto>? steps;
  final List<ImageResponseDto>? images;
  final List<RecipeSummaryDto>? variants;
  final List<LogPostSummaryDto>? logs;
  final List<HashtagDto>? hashtags;
  final bool? isSavedByCurrentUser;

  // Living Blueprint: Diff fields for variation tracking
  final Map<String, dynamic>? changeDiff;
  final List<String>? changeCategories;
  @JsonKey(fromJson: _parseChangeReason)
  final String? changeReason;

  RecipeDetailResponseDto({
    required this.publicId,
    required this.foodName,
    required this.foodMasterPublicId,
    required this.title,
    required this.description,
    this.culinaryLocale,
    this.changeCategory,
    this.rootInfo,
    this.parentInfo,
    this.ingredients,
    this.steps,
    this.images,
    this.variants,
    this.logs,
    this.hashtags,
    this.isSavedByCurrentUser,
    this.changeDiff,
    this.changeCategories,
    this.changeReason,
  });

  factory RecipeDetailResponseDto.fromJson(Map<String, dynamic> json) =>
      _$RecipeDetailResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeDetailResponseDtoToJson(this);

  RecipeDetail toEntity() => RecipeDetail(
    publicId: publicId,
    foodName: foodName,
    foodMasterPublicId: foodMasterPublicId,
    title: title,
    description: description ?? "",
    culinaryLocale: (culinaryLocale?.isEmpty ?? true) ? "ko-KR" : culinaryLocale!,
    changeCategory: changeCategory,
    rootInfo: rootInfo?.toEntity(),
    parentInfo: parentInfo?.toEntity(),
    ingredients: ingredients?.map((e) => e.toEntity()).toList() ?? [],
    steps: steps?.map((e) => e.toEntity()).toList() ?? [],
    imageUrls:
        images
            ?.map((img) => img.imageUrl ?? "")
            .where((url) => url.isNotEmpty)
            .toList() ??
        [],
    variants: variants?.map((e) => e.toEntity()).toList() ?? [],
    logs: logs?.map((e) => e.toEntity()).toList() ?? [],
    hashtags: hashtags?.map((e) => e.toEntity()).toList() ?? [],
    isSavedByCurrentUser: isSavedByCurrentUser,
    changeDiff: changeDiff,
    changeCategories: changeCategories,
    changeReason: changeReason,
  );
}
