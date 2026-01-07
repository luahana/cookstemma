class CreateLogPostRequest {
  final String? title;
  final String content;
  final String outcome; // SUCCESS, PARTIAL, FAILED
  final String recipePublicId;
  final List<String> imagePublicIds;
  final List<String>? hashtags;

  CreateLogPostRequest({
    this.title,
    required this.content,
    required this.outcome,
    required this.recipePublicId,
    required this.imagePublicIds,
    this.hashtags,
  });
}
