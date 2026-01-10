import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_draft.dart';

/// DTO for DraftIngredient - handles JSON serialization for Hive storage
class DraftIngredientDto {
  final String name;
  final String? amount;
  final String type;
  final bool isOriginal;
  final bool isDeleted;

  DraftIngredientDto({
    required this.name,
    this.amount,
    required this.type,
    this.isOriginal = false,
    this.isDeleted = false,
  });

  factory DraftIngredientDto.fromJson(Map<String, dynamic> json) {
    return DraftIngredientDto(
      name: json['name'] as String,
      amount: json['amount'] as String?,
      type: json['type'] as String,
      isOriginal: json['isOriginal'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'type': type,
        'isOriginal': isOriginal,
        'isDeleted': isDeleted,
      };

  factory DraftIngredientDto.fromEntity(DraftIngredient entity) {
    return DraftIngredientDto(
      name: entity.name,
      amount: entity.amount,
      type: entity.type,
      isOriginal: entity.isOriginal,
      isDeleted: entity.isDeleted,
    );
  }

  DraftIngredient toEntity() {
    return DraftIngredient(
      name: name,
      amount: amount,
      type: type,
      isOriginal: isOriginal,
      isDeleted: isDeleted,
    );
  }
}

/// DTO for DraftStep - handles JSON serialization for Hive storage
class DraftStepDto {
  final int stepNumber;
  final String? description;
  final String? imageUrl;
  final String? imagePublicId;
  final String? localImagePath;
  final bool isOriginal;
  final bool isDeleted;

  DraftStepDto({
    required this.stepNumber,
    this.description,
    this.imageUrl,
    this.imagePublicId,
    this.localImagePath,
    this.isOriginal = false,
    this.isDeleted = false,
  });

  factory DraftStepDto.fromJson(Map<String, dynamic> json) {
    return DraftStepDto(
      stepNumber: json['stepNumber'] as int,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      imagePublicId: json['imagePublicId'] as String?,
      localImagePath: json['localImagePath'] as String?,
      isOriginal: json['isOriginal'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'stepNumber': stepNumber,
        'description': description,
        'imageUrl': imageUrl,
        'imagePublicId': imagePublicId,
        'localImagePath': localImagePath,
        'isOriginal': isOriginal,
        'isDeleted': isDeleted,
      };

  factory DraftStepDto.fromEntity(DraftStep entity) {
    return DraftStepDto(
      stepNumber: entity.stepNumber,
      description: entity.description,
      imageUrl: entity.imageUrl,
      imagePublicId: entity.imagePublicId,
      localImagePath: entity.localImagePath,
      isOriginal: entity.isOriginal,
      isDeleted: entity.isDeleted,
    );
  }

  DraftStep toEntity() {
    return DraftStep(
      stepNumber: stepNumber,
      description: description,
      imageUrl: imageUrl,
      imagePublicId: imagePublicId,
      localImagePath: localImagePath,
      isOriginal: isOriginal,
      isDeleted: isDeleted,
    );
  }
}

/// DTO for DraftImage - handles JSON serialization for Hive storage
class DraftImageDto {
  final String localPath;
  final String? serverUrl;
  final String? publicId;
  final String status;

  DraftImageDto({
    required this.localPath,
    this.serverUrl,
    this.publicId,
    required this.status,
  });

  factory DraftImageDto.fromJson(Map<String, dynamic> json) {
    return DraftImageDto(
      localPath: json['localPath'] as String,
      serverUrl: json['serverUrl'] as String?,
      publicId: json['publicId'] as String?,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'localPath': localPath,
        'serverUrl': serverUrl,
        'publicId': publicId,
        'status': status,
      };

  factory DraftImageDto.fromEntity(DraftImage entity) {
    return DraftImageDto(
      localPath: entity.localPath,
      serverUrl: entity.serverUrl,
      publicId: entity.publicId,
      status: entity.status,
    );
  }

  DraftImage toEntity() {
    return DraftImage(
      localPath: localPath,
      serverUrl: serverUrl,
      publicId: publicId,
      status: status,
    );
  }
}

/// DTO for RecipeDraft - handles JSON serialization for Hive storage
class RecipeDraftDto {
  final String id;
  final String title;
  final String description;
  final String? culinaryLocale;
  final String? food1MasterPublicId;
  final String? foodName;
  final List<DraftIngredientDto> ingredients;
  final List<DraftStepDto> steps;
  final List<DraftImageDto> images;
  final List<String> hashtags;
  final DateTime createdAt;
  final DateTime updatedAt;

  RecipeDraftDto({
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

  factory RecipeDraftDto.fromJson(Map<String, dynamic> json) {
    return RecipeDraftDto(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      culinaryLocale: json['culinaryLocale'] as String?,
      food1MasterPublicId: json['food1MasterPublicId'] as String?,
      foodName: json['foodName'] as String?,
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((e) => DraftIngredientDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      steps: (json['steps'] as List<dynamic>)
          .map((e) => DraftStepDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      images: (json['images'] as List<dynamic>)
          .map((e) => DraftImageDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      hashtags: (json['hashtags'] as List<dynamic>).cast<String>(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'culinaryLocale': culinaryLocale,
        'food1MasterPublicId': food1MasterPublicId,
        'foodName': foodName,
        'ingredients': ingredients.map((e) => e.toJson()).toList(),
        'steps': steps.map((e) => e.toJson()).toList(),
        'images': images.map((e) => e.toJson()).toList(),
        'hashtags': hashtags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory RecipeDraftDto.fromEntity(RecipeDraft entity) {
    return RecipeDraftDto(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      culinaryLocale: entity.culinaryLocale,
      food1MasterPublicId: entity.food1MasterPublicId,
      foodName: entity.foodName,
      ingredients:
          entity.ingredients.map((e) => DraftIngredientDto.fromEntity(e)).toList(),
      steps: entity.steps.map((e) => DraftStepDto.fromEntity(e)).toList(),
      images: entity.images.map((e) => DraftImageDto.fromEntity(e)).toList(),
      hashtags: entity.hashtags,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  RecipeDraft toEntity() {
    return RecipeDraft(
      id: id,
      title: title,
      description: description,
      culinaryLocale: culinaryLocale,
      food1MasterPublicId: food1MasterPublicId,
      foodName: foodName,
      ingredients: ingredients.map((e) => e.toEntity()).toList(),
      steps: steps.map((e) => e.toEntity()).toList(),
      images: images.map((e) => e.toEntity()).toList(),
      hashtags: hashtags,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
