// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_activity_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecentActivityDto _$RecentActivityDtoFromJson(Map<String, dynamic> json) =>
    RecentActivityDto(
      logPublicId: json['logPublicId'] as String,
      outcome: json['outcome'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      creatorName: json['creatorName'] as String,
      recipeTitle: json['recipeTitle'] as String,
      recipePublicId: json['recipePublicId'] as String,
      foodName: json['foodName'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      hashtags: (json['hashtags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$RecentActivityDtoToJson(RecentActivityDto instance) =>
    <String, dynamic>{
      'logPublicId': instance.logPublicId,
      'outcome': instance.outcome,
      'thumbnailUrl': instance.thumbnailUrl,
      'creatorName': instance.creatorName,
      'recipeTitle': instance.recipeTitle,
      'recipePublicId': instance.recipePublicId,
      'foodName': instance.foodName,
      'createdAt': instance.createdAt?.toIso8601String(),
      'hashtags': instance.hashtags,
    };
