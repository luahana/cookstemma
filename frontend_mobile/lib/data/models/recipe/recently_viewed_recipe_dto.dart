import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';

/// Lightweight DTO for storing recently viewed recipes locally.
/// Contains only essential info needed for recipe picker display.
class RecentlyViewedRecipeDto {
  final String publicId;
  final String title;
  final String foodName;
  final String? thumbnailUrl;
  final DateTime viewedAt;

  RecentlyViewedRecipeDto({
    required this.publicId,
    required this.title,
    required this.foodName,
    this.thumbnailUrl,
    required this.viewedAt,
  });

  factory RecentlyViewedRecipeDto.fromJson(Map<String, dynamic> json) {
    return RecentlyViewedRecipeDto(
      publicId: json['publicId'] as String,
      title: json['title'] as String,
      foodName: json['foodName'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      viewedAt: DateTime.parse(json['viewedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'publicId': publicId,
        'title': title,
        'foodName': foodName,
        'thumbnailUrl': thumbnailUrl,
        'viewedAt': viewedAt.toIso8601String(),
      };

  /// Convert to RecipeSummary for UI compatibility
  RecipeSummary toRecipeSummary() => RecipeSummary(
        publicId: publicId,
        title: title,
        foodName: foodName,
        thumbnailUrl: thumbnailUrl,
        description: '',
        culinaryLocale: '',
        creatorName: '',
        variantCount: 0,
        logCount: 0,
      );
}
