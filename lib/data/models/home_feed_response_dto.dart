import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';

import 'recipe/trending_tree_dto.dart';

class HomeFeedResponseDto {
  final List<RecipeSummaryDto> recentRecipes;
  final List<TrendingTreeDto> trendingTrees;

  HomeFeedResponseDto({
    required this.recentRecipes,
    required this.trendingTrees,
  });

  factory HomeFeedResponseDto.fromJson(Map<String, dynamic> json) =>
      HomeFeedResponseDto(
        recentRecipes: (json['recentRecipes'] as List)
            .map((e) => RecipeSummaryDto.fromJson(e))
            .toList(),
        trendingTrees: (json['trendingTrees'] as List)
            .map((e) => TrendingTreeDto.fromJson(e))
            .toList(),
      );
}
