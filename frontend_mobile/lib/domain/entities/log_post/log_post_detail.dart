import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';
import 'package:pairing_planet2_frontend/domain/entities/hashtag/hashtag.dart';

/// Simple class holding image URL and publicId
class LogImage {
  final String publicId;
  final String? url;

  LogImage({required this.publicId, this.url});
}

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
  final List<String> imagePublicIds; // For image editing
  final String recipePublicId;
  final LinkedRecipeInfo? linkedRecipe; // Full recipe info for lineage display
  final DateTime createdAt;
  final List<Hashtag> hashtags;
  final bool? isSavedByCurrentUser;
  final String? creatorPublicId; // For ownership check (UUID string)

  LogPostDetail({
    required this.publicId,
    required this.content,
    required this.outcome,
    required this.imageUrls,
    this.imagePublicIds = const [],
    required this.recipePublicId,
    this.linkedRecipe,
    required this.createdAt,
    this.hashtags = const [],
    this.isSavedByCurrentUser,
    this.creatorPublicId,
  });

  /// Get list of LogImage objects combining URL and publicId
  List<LogImage> get images {
    final result = <LogImage>[];
    for (int i = 0; i < imageUrls.length; i++) {
      result.add(LogImage(
        publicId: i < imagePublicIds.length ? imagePublicIds[i] : '',
        url: imageUrls[i],
      ));
    }
    return result;
  }
}
