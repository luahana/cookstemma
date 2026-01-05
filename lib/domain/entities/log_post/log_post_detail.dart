class LogPostDetail {
  final String publicId;
  final String content;
  final double rating; // 💡 int에서 double로 변경 (평점은 보통 소수점 지원)
  final List<String?> imageUrls; // 💡 ImageResponseDto 리스트에서 String 리스트로 변경
  final String recipePublicId;
  final DateTime createdAt;

  LogPostDetail({
    required this.publicId,
    required this.content,
    required this.rating,
    required this.imageUrls,
    required this.recipePublicId,
    required this.createdAt,
  });
}
