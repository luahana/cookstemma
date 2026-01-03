class RecipeSummary {
  final String id;
  final String title;
  final String culinaryLocale;
  final String? thumbnail;

  RecipeSummary({
    required this.id,
    required this.title,
    required this.culinaryLocale,
    this.thumbnail,
  });
}
