class RecipeStep {
  final int stepNumber;
  final String? description;
  final String? imageUrl;
  final String? imagePublicId;

  RecipeStep({
    required this.stepNumber,
    required this.description,
    this.imageUrl,
    this.imagePublicId,
  });
}
