/// Represents a draft ingredient for auto-save
class DraftIngredient {
  final String name;
  final String? amount;
  final String type;
  final bool isOriginal;
  final bool isDeleted;

  DraftIngredient({
    required this.name,
    this.amount,
    required this.type,
    this.isOriginal = false,
    this.isDeleted = false,
  });
}

/// Represents a draft step for auto-save
class DraftStep {
  final int stepNumber;
  final String? description;
  final String? imageUrl;
  final String? imagePublicId;
  final String? localImagePath;
  final bool isOriginal;
  final bool isDeleted;

  DraftStep({
    required this.stepNumber,
    this.description,
    this.imageUrl,
    this.imagePublicId,
    this.localImagePath,
    this.isOriginal = false,
    this.isDeleted = false,
  });
}

/// Represents a draft image (finished photo) for auto-save
class DraftImage {
  final String localPath;
  final String? serverUrl;
  final String? publicId;
  final String status;

  DraftImage({
    required this.localPath,
    this.serverUrl,
    this.publicId,
    required this.status,
  });
}

/// Represents a recipe draft for local auto-save storage
class RecipeDraft {
  final String id;
  final String title;
  final String description;
  final String? culinaryLocale;
  final String? food1MasterPublicId;
  final String? foodName;
  final List<DraftIngredient> ingredients;
  final List<DraftStep> steps;
  final List<DraftImage> images;
  final List<String> hashtags;
  final DateTime createdAt;
  final DateTime updatedAt;

  RecipeDraft({
    required this.id,
    required this.title,
    required this.description,
    this.culinaryLocale,
    this.food1MasterPublicId,
    this.foodName,
    required this.ingredients,
    required this.steps,
    required this.images,
    required this.hashtags,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if draft has expired (older than 7 days)
  bool get isExpired => DateTime.now().difference(createdAt).inDays > 7;

  /// Check if draft has meaningful content worth saving
  bool get hasContent =>
      title.isNotEmpty ||
      description.isNotEmpty ||
      foodName?.isNotEmpty == true ||
      ingredients.isNotEmpty ||
      steps.isNotEmpty ||
      images.isNotEmpty;
}
