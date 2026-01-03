import 'package:pairing_planet2_frontend/domain/entities/recipe_step.dart';

class StepDto {
  final int stepNumber;
  final String description;
  final String? imageUrl;

  StepDto({required this.stepNumber, required this.description, this.imageUrl});

  factory StepDto.fromJson(Map<String, dynamic> json) => StepDto(
    stepNumber: json['stepNumber'],
    description: json['description'],
    imageUrl: json['imageUrl'],
  );

  Map<String, dynamic> toJson() => {
    'stepNumber': stepNumber,
    'description': description,
    'imageUrl': imageUrl,
  };

  RecipeStep toEntity() => RecipeStep(
    stepNumber: stepNumber,
    description: description,
    imageUrl: imageUrl,
  );
}
