class LogPostDetail {
  final String publicId;
  final String content;
  final String outcome; // SUCCESS, PARTIAL, FAILED
  final List<String?> imageUrls;
  final String recipePublicId;
  final DateTime createdAt;

  LogPostDetail({
    required this.publicId,
    required this.content,
    required this.outcome,
    required this.imageUrls,
    required this.recipePublicId,
    required this.createdAt,
  });
}
