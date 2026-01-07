import 'package:json_annotation/json_annotation.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_step.dart';

part 'step_dto.g.dart';

@JsonSerializable()
class StepDto {
  final int stepNumber;
  final String? description;
  final String? imagePublicId; // [추가] 식별용 UUID
  final String? imageUrl; // [유지] 표시용 URL

  StepDto({
    required this.stepNumber,
    this.description,
    this.imagePublicId,
    this.imageUrl,
  });

  factory StepDto.fromJson(Map<String, dynamic> json) =>
      _$StepDtoFromJson(json);
  Map<String, dynamic> toJson() => _$StepDtoToJson(this);

  RecipeStep toEntity() => RecipeStep(
    stepNumber: stepNumber,
    description: description,
    imagePublicId: imagePublicId, // [추가됨]
    imageUrl: imageUrl, // [유지됨]
  );

  factory StepDto.fromEntity(RecipeStep step) {
    return StepDto(
      stepNumber: step.stepNumber,
      description: step.description,
      imagePublicId: step.imagePublicId,
      imageUrl: step.imageUrl,
    );
  }
}
