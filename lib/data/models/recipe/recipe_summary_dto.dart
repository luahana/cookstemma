class RecipeSummaryDto {
  final String publicId;
  final String title;
  final String culinaryLocale;
  final String? creatorName;
  final String? thumbnail; // display_order = 0인 이미지

  RecipeSummaryDto({
    required this.publicId,
    required this.title,
    required this.culinaryLocale,
    this.creatorName,
    this.thumbnail,
  });

  factory RecipeSummaryDto.fromJson(Map<String, dynamic> json) =>
      RecipeSummaryDto(
        publicId: json['publicId'],
        title: json['title'],
        culinaryLocale: json['culinaryLocale'],
        creatorName: json['creatorName'],
        thumbnail: json['thumbnail'],
      );

  Map<String, dynamic> toJson() => {
    'publicId': publicId,
    'title': title,
    'culinaryLocale': culinaryLocale,
    'creatorName': creatorName,
    'thumbnail': thumbnail,
  };

  RecipeSummary toEntity() => RecipeSummary(
    id: publicId,
    title: title,
    culinaryLocale: culinaryLocale,
    thumbnail: thumbnail,
  );
}
