// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_post_summary_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LogPostSummaryDto _$LogPostSummaryDtoFromJson(Map<String, dynamic> json) =>
    LogPostSummaryDto(
      publicId: json['publicId'] as String,
      title: json['title'] as String?,
      outcome: json['outcome'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      creatorPublicId: json['creatorPublicId'] as String?,
      creatorName: json['creatorName'] as String?,
      foodName: json['foodName'] as String?,
      hashtags: (json['hashtags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isVariant: json['isVariant'] as bool?,
    );

Map<String, dynamic> _$LogPostSummaryDtoToJson(LogPostSummaryDto instance) =>
    <String, dynamic>{
      'publicId': instance.publicId,
      'title': instance.title,
      'outcome': instance.outcome,
      'thumbnailUrl': instance.thumbnailUrl,
      'creatorPublicId': instance.creatorPublicId,
      'creatorName': instance.creatorName,
      'foodName': instance.foodName,
      'hashtags': instance.hashtags,
      'isVariant': instance.isVariant,
    };
