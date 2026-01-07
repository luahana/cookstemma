class LogPostSummary {
  final String id;
  final String title;
  final String? outcome; // SUCCESS, PARTIAL, FAILED
  final String? thumbnailUrl;
  final String? creatorName;

  LogPostSummary({
    required this.id,
    required this.title,
    this.outcome,
    this.thumbnailUrl,
    this.creatorName,
  });
}
