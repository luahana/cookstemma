class TrendingTreeDto {
  final String rootRecipeId; // UUID는 String으로 처리
  final String title;
  final String culinaryLocale;
  final int variantCount;
  final int logCount;
  final String? latestChangeSummary;

  TrendingTreeDto({
    required this.rootRecipeId,
    required this.title,
    required this.culinaryLocale,
    required this.variantCount,
    required this.logCount,
    this.latestChangeSummary,
  });

  factory TrendingTreeDto.fromJson(Map<String, dynamic> json) =>
      TrendingTreeDto(
        rootRecipeId: json['rootRecipeId'],
        title: json['title'],
        culinaryLocale: json['culinaryLocale'],
        variantCount: json['variantCount'],
        logCount: json['logCount'],
        latestChangeSummary: json['latestChangeSummary'],
      );
}
