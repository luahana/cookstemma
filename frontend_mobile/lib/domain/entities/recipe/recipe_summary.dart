class RecipeSummary {
  final String publicId;
  final String foodName;
  final String? foodMasterPublicId;
  final String title;
  final String description;
  final String culinaryLocale;
  final String? thumbnailUrl;
  final String? creatorPublicId; // Creator's publicId for profile navigation
  final String creatorName;
  final int variantCount;
  final int logCount; // Activity count: number of cooking logs
  final String? parentPublicId;
  final String? rootPublicId;
  final String? rootTitle; // For displaying root recipe link in variants

  RecipeSummary({
    required this.publicId,
    required this.foodName,
    this.foodMasterPublicId,
    required this.title,
    required this.description,
    required this.culinaryLocale,
    this.thumbnailUrl,
    this.creatorPublicId,
    required this.creatorName,
    required this.variantCount,
    this.logCount = 0,
    this.parentPublicId,
    this.rootPublicId,
    this.rootTitle,
  });

  bool get isVariant => rootPublicId != null;
}
