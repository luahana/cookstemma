import 'package:pairing_planet2_frontend/data/models/log_post/log_post_summary_dto.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_detail.dart';

import 'ingredient_dto.dart';
import 'step_dto.dart';

class RecipeDetailResponseDto {
  final String publicId;
  final String title;
  final String description;
  final String culinaryLocale;
  final String? changeCategory;
  final RecipeSummaryDto? rootInfo; // [원칙 1] 상단 고정 루트 레시피
  final RecipeSummaryDto? parentInfo; // Inspired by 정보
  final List<IngredientDto> ingredients;
  final List<StepDto> steps;
  final List<String> imageUrls;
  final List<RecipeSummaryDto> variants;
  final List<LogPostSummaryDto> logs;

  RecipeDetailResponseDto({
    required this.publicId,
    required this.title,
    required this.description,
    required this.culinaryLocale,
    this.changeCategory,
    this.rootInfo,
    this.parentInfo,
    required this.ingredients,
    required this.steps,
    required this.imageUrls,
    required this.variants,
    required this.logs,
  });

  factory RecipeDetailResponseDto.fromJson(Map<String, dynamic> json) =>
      RecipeDetailResponseDto(
        publicId: json['publicId'],
        title: json['title'],
        description: json['description'],
        culinaryLocale: json['culinaryLocale'],
        changeCategory: json['changeCategory'],
        rootInfo: json['rootInfo'] != null
            ? RecipeSummaryDto.fromJson(json['rootInfo'])
            : null,
        parentInfo: json['parentInfo'] != null
            ? RecipeSummaryDto.fromJson(json['parentInfo'])
            : null,
        ingredients: (json['ingredients'] as List)
            .map((e) => IngredientDto.fromJson(e))
            .toList(),
        steps: (json['steps'] as List).map((e) => StepDto.fromJson(e)).toList(),
        imageUrls: List<String>.from(json['imageUrls']),
        variants: (json['variants'] as List)
            .map((e) => RecipeSummaryDto.fromJson(e))
            .toList(),
        logs: (json['logs'] as List)
            .map((e) => LogPostSummaryDto.fromJson(e))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    'publicId': publicId,
    'title': title,
    'description': description,
    'culinaryLocale': culinaryLocale,
    'ingredients': ingredients.map((e) => e.toJson()).toList(),
    'steps': steps.map((e) => e.toJson()).toList(),
    'variants': variants.map((e) => e.toJson()).toList(),
    'logs': logs.map((e) => e.toJson()).toList(),
    'imageUrls': imageUrls,
    'rootInfo': rootInfo?.toJson(),
    'parentInfo': parentInfo?.toJson(),
  };

  RecipeDetail toEntity() {
    return RecipeDetail(
      id: publicId,
      title: title,
      description: description,
      culinaryLocale: culinaryLocale,
      changeCategory: changeCategory,
      // 하위 DTO들도 각각 toEntity()를 호출하여 변환
      rootInfo: rootInfo?.toEntity(),
      parentInfo: parentInfo?.toEntity(),
      ingredients: ingredients.map((i) => i.toEntity()).toList(),
      steps: steps.map((s) => s.toEntity()).toList(),
      imageUrls: imageUrls,
      variants: variants.map((v) => v.toEntity()).toList(),
      logs: logs.map((l) => l.toEntity()).toList(),
    );
  }
}
