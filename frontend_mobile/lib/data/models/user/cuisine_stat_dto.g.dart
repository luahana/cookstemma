// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cuisine_stat_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CuisineStatDto _$CuisineStatDtoFromJson(Map<String, dynamic> json) =>
    CuisineStatDto(
      categoryCode: json['categoryCode'] as String,
      categoryName: json['categoryName'] as String,
      count: (json['count'] as num).toInt(),
      percentage: (json['percentage'] as num).toDouble(),
    );

Map<String, dynamic> _$CuisineStatDtoToJson(CuisineStatDto instance) =>
    <String, dynamic>{
      'categoryCode': instance.categoryCode,
      'categoryName': instance.categoryName,
      'count': instance.count,
      'percentage': instance.percentage,
    };
