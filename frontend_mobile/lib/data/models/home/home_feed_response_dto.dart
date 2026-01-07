import 'package:json_annotation/json_annotation.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';
import '../recipe/trending_tree_dto.dart';
import 'recent_activity_dto.dart';

part 'home_feed_response_dto.g.dart';

@JsonSerializable()
class HomeFeedResponseDto {
  final List<RecentActivityDto> recentActivity;
  final List<RecipeSummaryDto> recentRecipes;
  final List<TrendingTreeDto> trendingTrees;

  HomeFeedResponseDto({
    required this.recentActivity,
    required this.recentRecipes,
    required this.trendingTrees,
  });

  factory HomeFeedResponseDto.fromJson(Map<String, dynamic> json) =>
      _$HomeFeedResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$HomeFeedResponseDtoToJson(this);
}
