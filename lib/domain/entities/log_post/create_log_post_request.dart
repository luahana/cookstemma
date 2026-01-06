class CreateLogPostRequest {
  final String? title;
  final String content;
  final String outcome; // SUCCESS, PARTIAL, FAILED
  final String recipePublicId;
  final List<String> imagePublicIds;

  CreateLogPostRequest({
    this.title,
    required this.content,
    required this.outcome,
    required this.recipePublicId,
    required this.imagePublicIds,
  });
}
