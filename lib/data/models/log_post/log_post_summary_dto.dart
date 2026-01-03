import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_summary.dart';

class LogPostSummaryDto {
  final String publicId;
  final String title;
  final int? rating;
  final String? thumbnail;
  final String? creatorName;

  LogPostSummaryDto({
    required this.publicId,
    required this.title,
    this.rating,
    this.thumbnail,
    this.creatorName,
  });

  factory LogPostSummaryDto.fromJson(Map<String, dynamic> json) =>
      LogPostSummaryDto(
        publicId: json['publicId'],
        title: json['title'],
        rating: json['rating'],
        thumbnail: json['thumbnail'],
        creatorName: json['creatorName'],
      );

  Map<String, dynamic> toJson() => {
    'publicId': publicId,
    'title': title,
    'rating': rating,
    'thumbnail': thumbnail,
    'creatorName': creatorName,
  };

  /// 💡 에러를 해결하는 핵심 매퍼 메서드
  LogPostSummary toEntity() {
    return LogPostSummary(
      id: publicId, // publicId를 엔티티의 id로 매핑
      title: title,
      rating: rating,
      thumbnail: thumbnail,
      creatorName: creatorName,
    );
  }
}
