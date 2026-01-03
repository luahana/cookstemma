class LogPostSummary {
  final String id;
  final String title;
  final int? rating;
  final String? thumbnail;
  final String? creatorName;

  LogPostSummary({
    required this.id,
    required this.title,
    this.rating,
    this.thumbnail,
    this.creatorName,
  });
}
