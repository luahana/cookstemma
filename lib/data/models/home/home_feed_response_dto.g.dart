// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_feed_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeFeedResponseDto _$HomeFeedResponseDtoFromJson(Map<String, dynamic> json) =>
    HomeFeedResponseDto(
      recentActivity: (json['recentActivity'] as List<dynamic>)
          .map((e) => RecentActivityDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentRecipes: (json['recentRecipes'] as List<dynamic>)
          .map((e) => RecipeSummaryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      trendingTrees: (json['trendingTrees'] as List<dynamic>)
          .map((e) => TrendingTreeDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$HomeFeedResponseDtoToJson(
        HomeFeedResponseDto instance) =>
    <String, dynamic>{
      'recentActivity': instance.recentActivity,
      'recentRecipes': instance.recentRecipes,
      'trendingTrees': instance.trendingTrees,
    };
