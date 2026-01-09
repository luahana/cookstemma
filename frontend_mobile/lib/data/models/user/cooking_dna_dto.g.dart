// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cooking_dna_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CookingDnaDto _$CookingDnaDtoFromJson(Map<String, dynamic> json) =>
    CookingDnaDto(
      totalXp: (json['totalXp'] as num).toInt(),
      level: (json['level'] as num).toInt(),
      levelName: json['levelName'] as String,
      xpForCurrentLevel: (json['xpForCurrentLevel'] as num).toInt(),
      xpForNextLevel: (json['xpForNextLevel'] as num).toInt(),
      levelProgress: (json['levelProgress'] as num).toDouble(),
      successRate: (json['successRate'] as num).toDouble(),
      totalLogs: (json['totalLogs'] as num).toInt(),
      successCount: (json['successCount'] as num).toInt(),
      partialCount: (json['partialCount'] as num).toInt(),
      failedCount: (json['failedCount'] as num).toInt(),
      currentStreak: (json['currentStreak'] as num).toInt(),
      longestStreak: (json['longestStreak'] as num).toInt(),
      cuisineDistribution: (json['cuisineDistribution'] as List<dynamic>)
          .map((e) => CuisineStatDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      recipeCount: (json['recipeCount'] as num).toInt(),
      logCount: (json['logCount'] as num).toInt(),
      savedCount: (json['savedCount'] as num).toInt(),
    );

Map<String, dynamic> _$CookingDnaDtoToJson(CookingDnaDto instance) =>
    <String, dynamic>{
      'totalXp': instance.totalXp,
      'level': instance.level,
      'levelName': instance.levelName,
      'xpForCurrentLevel': instance.xpForCurrentLevel,
      'xpForNextLevel': instance.xpForNextLevel,
      'levelProgress': instance.levelProgress,
      'successRate': instance.successRate,
      'totalLogs': instance.totalLogs,
      'successCount': instance.successCount,
      'partialCount': instance.partialCount,
      'failedCount': instance.failedCount,
      'currentStreak': instance.currentStreak,
      'longestStreak': instance.longestStreak,
      'cuisineDistribution': instance.cuisineDistribution,
      'recipeCount': instance.recipeCount,
      'logCount': instance.logCount,
      'savedCount': instance.savedCount,
    };
