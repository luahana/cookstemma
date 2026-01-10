import 'package:flutter/foundation.dart';

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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DraftIngredient) return false;
    return name == other.name &&
        amount == other.amount &&
        type == other.type &&
        isOriginal == other.isOriginal &&
        isDeleted == other.isDeleted;
  }

  @override
  int get hashCode => Object.hash(name, amount, type, isOriginal, isDeleted);

  /// Check if this ingredient has meaningful content (not just a blank placeholder)
  bool get hasMeaningfulContent => name.isNotEmpty;
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DraftStep) return false;
    return stepNumber == other.stepNumber &&
        description == other.description &&
        imageUrl == other.imageUrl &&
        imagePublicId == other.imagePublicId &&
        localImagePath == other.localImagePath &&
        isOriginal == other.isOriginal &&
        isDeleted == other.isDeleted;
  }

  @override
  int get hashCode => Object.hash(
        stepNumber,
        description,
        imageUrl,
        imagePublicId,
        localImagePath,
        isOriginal,
        isDeleted,
      );

  /// Check if this step has meaningful content (not just a blank placeholder)
  bool get hasMeaningfulContent =>
      (description?.isNotEmpty == true) ||
      (imageUrl?.isNotEmpty == true) ||
      localImagePath != null;
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DraftImage) return false;
    return localPath == other.localPath &&
        serverUrl == other.serverUrl &&
        publicId == other.publicId &&
        status == other.status;
  }

  @override
  int get hashCode => Object.hash(localPath, serverUrl, publicId, status);
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
  /// Note: Empty placeholder ingredients/steps don't count as content
  bool get hasContent =>
      title.isNotEmpty ||
      description.isNotEmpty ||
      foodName?.isNotEmpty == true ||
      ingredients.any((i) => i.hasMeaningfulContent) ||
      steps.any((s) => s.hasMeaningfulContent) ||
      images.isNotEmpty ||
      hashtags.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RecipeDraft) return false;
    return title == other.title &&
        description == other.description &&
        culinaryLocale == other.culinaryLocale &&
        food1MasterPublicId == other.food1MasterPublicId &&
        foodName == other.foodName &&
        listEquals(ingredients, other.ingredients) &&
        listEquals(steps, other.steps) &&
        listEquals(images, other.images) &&
        listEquals(hashtags, other.hashtags);
  }

  @override
  int get hashCode => Object.hash(
        title,
        description,
        culinaryLocale,
        food1MasterPublicId,
        foodName,
        Object.hashAll(ingredients),
        Object.hashAll(steps),
        Object.hashAll(images),
        Object.hashAll(hashtags),
      );
}
