import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';

class LogPostDetailResponseDto {
  final String publicId;
  final String title;
  final String content;
  final int? rating;
  final List<String> imageUrls;
  final RecipeSummaryDto linkedRecipe;

  LogPostDetailResponseDto({
    required this.publicId,
    required this.title,
    required this.content,
    this.rating,
    required this.imageUrls,
    required this.linkedRecipe,
  });

  factory LogPostDetailResponseDto.fromJson(Map<String, dynamic> json) =>
      LogPostDetailResponseDto(
        publicId: json['publicId'],
        title: json['title'],
        content: json['content'],
        rating: json['rating'],
        imageUrls: List<String>.from(json['imageUrls']),
        linkedRecipe: RecipeSummaryDto.fromJson(json['linkedRecipe']),
      );

  // 💡 아래 toJson 메서드를 추가했습니다.
  Map<String, dynamic> toJson() => {
    'publicId': publicId,
    'title': title,
    'content': content,
    'rating': rating,
    'imageUrls': imageUrls,
    // 중첩된 DTO도 toJson()을 호출하여 Map으로 변환합니다.
    'linkedRecipe': linkedRecipe.toJson(),
  };
}
