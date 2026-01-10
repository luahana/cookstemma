import 'package:json_annotation/json_annotation.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_modifiable.dart';

part 'recipe_modifiable_dto.g.dart';

/// DTO for checking if a recipe can be modified (edited/deleted).
@JsonSerializable()
class RecipeModifiableDto {
  final bool canModify;
  final bool isOwner;
  final bool hasVariants;
  final bool hasLogs;
  final int variantCount;
  final int logCount;
  final String? reason;

  RecipeModifiableDto({
    required this.canModify,
    required this.isOwner,
    required this.hasVariants,
    required this.hasLogs,
    required this.variantCount,
    required this.logCount,
    this.reason,
  });

  factory RecipeModifiableDto.fromJson(Map<String, dynamic> json) =>
      _$RecipeModifiableDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeModifiableDtoToJson(this);

  RecipeModifiable toEntity() => RecipeModifiable(
        canModify: canModify,
        isOwner: isOwner,
        hasVariants: hasVariants,
        hasLogs: hasLogs,
        variantCount: variantCount,
        logCount: logCount,
        reason: reason,
      );
}
