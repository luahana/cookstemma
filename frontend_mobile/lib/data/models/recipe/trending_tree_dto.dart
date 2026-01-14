import 'package:json_annotation/json_annotation.dart';

part 'trending_tree_dto.g.dart';

@JsonSerializable()
class TrendingTreeDto {
  final String rootRecipeId;
  final String title;
  final String? foodName;
  final String culinaryLocale;
  final String? thumbnail;
  final int variantCount;
  final int logCount;
  final String? latestChangeSummary;
  final String? creatorName;
  final String? creatorPublicId;

  TrendingTreeDto({
    required this.rootRecipeId,
    required this.title,
    this.foodName,
    required this.culinaryLocale,
    this.thumbnail,
    required this.variantCount,
    required this.logCount,
    this.latestChangeSummary,
    this.creatorName,
    this.creatorPublicId,
  });

  factory TrendingTreeDto.fromJson(Map<String, dynamic> json) =>
      _$TrendingTreeDtoFromJson(json);
  Map<String, dynamic> toJson() => _$TrendingTreeDtoToJson(this);
}
