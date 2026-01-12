import 'package:json_annotation/json_annotation.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_summary.dart';

part 'recent_activity_dto.g.dart';

@JsonSerializable()
class RecentActivityDto {
  final String logPublicId;
  final String outcome;
  final String? thumbnailUrl;
  final String creatorName;
  final String recipeTitle;
  final String recipePublicId;
  final String foodName;
  final DateTime? createdAt;
  final List<String>? hashtags;

  RecentActivityDto({
    required this.logPublicId,
    required this.outcome,
    this.thumbnailUrl,
    required this.creatorName,
    required this.recipeTitle,
    required this.recipePublicId,
    required this.foodName,
    this.createdAt,
    this.hashtags,
  });

  factory RecentActivityDto.fromJson(Map<String, dynamic> json) =>
      _$RecentActivityDtoFromJson(json);
  Map<String, dynamic> toJson() => _$RecentActivityDtoToJson(this);

  /// Convert to LogPostSummary for use with LogPostCard widget
  LogPostSummary toLogPostSummary() => LogPostSummary(
        id: logPublicId,
        title: foodName.isNotEmpty ? foodName : recipeTitle,
        outcome: outcome,
        thumbnailUrl: thumbnailUrl,
        creatorName: creatorName,
        foodName: foodName,
        hashtags: hashtags,
        createdAt: createdAt,
      );
}
