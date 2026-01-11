import 'package:json_annotation/json_annotation.dart';

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

  RecentActivityDto({
    required this.logPublicId,
    required this.outcome,
    this.thumbnailUrl,
    required this.creatorName,
    required this.recipeTitle,
    required this.recipePublicId,
    required this.foodName,
    this.createdAt,
  });

  factory RecentActivityDto.fromJson(Map<String, dynamic> json) =>
      _$RecentActivityDtoFromJson(json);
  Map<String, dynamic> toJson() => _$RecentActivityDtoToJson(this);
}
