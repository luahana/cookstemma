import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';
import 'package:pairing_planet2_frontend/domain/entities/hashtag/hashtag.dart';

/// Linked recipe info for log post lineage display
class LinkedRecipeInfo {
  final String publicId;
  final String title;
  final String creatorName;
  final String? rootPublicId;
  final String? rootTitle;
  final String? rootCreatorName;

  LinkedRecipeInfo({
    required this.publicId,
    required this.title,
    required this.creatorName,
    this.rootPublicId,
    this.rootTitle,
    this.rootCreatorName,
  });

  bool get isVariant => rootPublicId != null;

  factory LinkedRecipeInfo.fromRecipeSummary(RecipeSummary summary) {
    return LinkedRecipeInfo(
      publicId: summary.publicId,
      title: summary.title,
      creatorName: summary.creatorName,
      rootPublicId: summary.rootPublicId,
      // Note: rootTitle and rootCreatorName need to come from backend
      rootTitle: null,
      rootCreatorName: null,
    );
  }
}

class LogPostDetail {
  final String publicId;
  final String content;
  final String outcome; // SUCCESS, PARTIAL, FAILED
  final List<String?> imageUrls;
  final String recipePublicId;
  final LinkedRecipeInfo? linkedRecipe; // Full recipe info for lineage display
  final DateTime createdAt;
  final List<Hashtag> hashtags;

  LogPostDetail({
    required this.publicId,
    required this.content,
    required this.outcome,
    required this.imageUrls,
    required this.recipePublicId,
    this.linkedRecipe,
    required this.createdAt,
    this.hashtags = const [],
  });
}
