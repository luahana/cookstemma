import 'package:json_annotation/json_annotation.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';

part 'recipe_summary_dto.g.dart';

// Helper function to safely parse foodName which might be String or Map (from stale cache)
String _parseFoodName(dynamic value) {
  if (value == null) return 'Unknown Food';
  if (value is String) return value;
  if (value is Map) {
    // If it's a Map (multilingual name), try to extract a name
    if (value.containsKey('ko-KR')) return value['ko-KR']?.toString() ?? 'Unknown Food';
    if (value.containsKey('en-US')) return value['en-US']?.toString() ?? 'Unknown Food';
    // Fallback to first value in map
    return value.values.firstOrNull?.toString() ?? 'Unknown Food';
  }
  return value.toString();
}

@JsonSerializable(explicitToJson: true)
class RecipeSummaryDto {
  final String publicId;
  @JsonKey(fromJson: _parseFoodName)
  final String foodName;
  final String foodMasterPublicId;
  final String title;
  final String? description;
  final String? culinaryLocale;
  final String? creatorName;
  final String? thumbnail;
  final int? variantCount;
  final int? logCount; // Activity count from backend (nullable for backward compat)
  final String? parentPublicId;
  final String? rootPublicId;
  final String? rootTitle; // Root recipe title for variants

  RecipeSummaryDto({
    required this.publicId,
    required this.foodName,
    required this.foodMasterPublicId,
    required this.title,
    this.description,
    this.culinaryLocale,
    required this.creatorName,
    this.thumbnail,
    this.variantCount,
    this.logCount,
    this.parentPublicId,
    this.rootPublicId,
    this.rootTitle,
  });

  factory RecipeSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$RecipeSummaryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeSummaryDtoToJson(this);

  RecipeSummary toEntity() => RecipeSummary(
    publicId: publicId,
    foodName: foodName,
    foodMasterPublicId: foodMasterPublicId,
    title: title,
    description: description ?? "",
    culinaryLocale: culinaryLocale ?? "",
    thumbnailUrl: thumbnail,
    creatorName: creatorName ?? "익명",
    variantCount: variantCount ?? 0,
    logCount: logCount ?? 0,
    parentPublicId: parentPublicId,
    rootPublicId: rootPublicId,
    rootTitle: rootTitle,
  );
}
