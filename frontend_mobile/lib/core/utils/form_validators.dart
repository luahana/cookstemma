import 'package:easy_localization/easy_localization.dart';
import 'package:pairing_planet2_frontend/shared/data/model/upload_item_model.dart';

/// Validation result containing error state and message
class ValidationResult {
  final bool isValid;
  final String? errorKey;

  const ValidationResult.valid() : isValid = true, errorKey = null;
  const ValidationResult.invalid(String key) : isValid = false, errorKey = key;

  String? get errorMessage => errorKey?.tr();
}

/// Recipe form validation helper
class RecipeFormValidator {
  // Minimum title length requirement
  static const int minTitleLength = 2;

  /// Validate recipe title (required, min 2 characters)
  static ValidationResult validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const ValidationResult.invalid('validation.recipe.titleRequired');
    }
    if (value.trim().length < minTitleLength) {
      return const ValidationResult.invalid('validation.recipe.titleMinLength');
    }
    return const ValidationResult.valid();
  }

  /// Validate food name (required for new recipes, not variants)
  static ValidationResult validateFoodName(String? value, {required bool isVariantMode}) {
    if (isVariantMode) return const ValidationResult.valid();
    if (value == null || value.trim().isEmpty) {
      return const ValidationResult.invalid('validation.recipe.foodNameRequired');
    }
    return const ValidationResult.valid();
  }

  /// Validate photos (at least 1 successfully uploaded)
  static ValidationResult validatePhotos(List<UploadItem> images) {
    final successCount = images.where((img) => img.status == UploadStatus.success).length;
    if (successCount < 1) {
      return const ValidationResult.invalid('validation.recipe.photoRequired');
    }
    return const ValidationResult.valid();
  }

  /// Validate ingredients (at least 1 non-deleted with name)
  static ValidationResult validateIngredients(List<Map<String, dynamic>> ingredients) {
    final validIngredients = ingredients.where((ing) {
      final isDeleted = ing['isDeleted'] == true;
      final hasName = (ing['name'] as String?)?.trim().isNotEmpty == true;
      return !isDeleted && hasName;
    }).toList();

    if (validIngredients.isEmpty) {
      return const ValidationResult.invalid('validation.recipe.ingredientRequired');
    }
    return const ValidationResult.valid();
  }

  /// Validate steps (at least 1 non-deleted with description)
  static ValidationResult validateSteps(List<Map<String, dynamic>> steps) {
    final validSteps = steps.where((step) {
      final isDeleted = step['isDeleted'] == true;
      final hasDescription = (step['description'] as String?)?.trim().isNotEmpty == true;
      return !isDeleted && hasDescription;
    }).toList();

    if (validSteps.isEmpty) {
      return const ValidationResult.invalid('validation.recipe.stepRequired');
    }
    return const ValidationResult.valid();
  }

  /// Validate change reason (required for variant mode)
  static ValidationResult validateChangeReason(String? value, {required bool isVariantMode}) {
    if (!isVariantMode) return const ValidationResult.valid();
    if (value == null || value.trim().isEmpty) {
      return const ValidationResult.invalid('validation.recipe.changeReasonRequired');
    }
    return const ValidationResult.valid();
  }

  /// Check if entire form is valid
  static bool isFormValid({
    required String title,
    required String foodName,
    required List<UploadItem> photos,
    required List<Map<String, dynamic>> ingredients,
    required List<Map<String, dynamic>> steps,
    required String changeReason,
    required bool isVariantMode,
  }) {
    return validateTitle(title).isValid &&
        validateFoodName(foodName, isVariantMode: isVariantMode).isValid &&
        validatePhotos(photos).isValid &&
        validateIngredients(ingredients).isValid &&
        validateSteps(steps).isValid &&
        validateChangeReason(changeReason, isVariantMode: isVariantMode).isValid;
  }

  /// Get all validation errors for display
  static List<ValidationResult> getAllValidations({
    required String title,
    required String foodName,
    required List<UploadItem> photos,
    required List<Map<String, dynamic>> ingredients,
    required List<Map<String, dynamic>> steps,
    required String changeReason,
    required bool isVariantMode,
  }) {
    return [
      validateTitle(title),
      validateFoodName(foodName, isVariantMode: isVariantMode),
      validatePhotos(photos),
      validateIngredients(ingredients),
      validateSteps(steps),
      validateChangeReason(changeReason, isVariantMode: isVariantMode),
    ];
  }
}

/// Log post form validation helper
class LogFormValidator {
  /// Validate content (required)
  static ValidationResult validateContent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const ValidationResult.invalid('validation.log.contentRequired');
    }
    return const ValidationResult.valid();
  }

  /// Check if entire form is valid
  static bool isFormValid({required String content}) {
    return validateContent(content).isValid;
  }
}
