class RecipeStep {
  final int stepNumber;
  final String description;
  final String? imageUrl;

  RecipeStep({
    required this.stepNumber,
    required this.description,
    this.imageUrl,
  });
}
