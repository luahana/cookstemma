import 'package:json_annotation/json_annotation.dart';
import 'cuisine_stat_dto.dart';

part 'cooking_dna_dto.g.dart';

@JsonSerializable()
class CookingDnaDto {
  // XP & Level
  final int totalXp;
  final int level;
  final String levelName;
  final int xpForCurrentLevel;
  final int xpForNextLevel;
  final double levelProgress;

  // Cooking Stats
  final double successRate;
  final int totalLogs;
  final int successCount;
  final int partialCount;
  final int failedCount;

  // Streak
  final int currentStreak;
  final int longestStreak;

  // Cuisine Distribution
  final List<CuisineStatDto> cuisineDistribution;

  // Content counts
  final int recipeCount;
  final int logCount;
  final int savedCount;

  CookingDnaDto({
    required this.totalXp,
    required this.level,
    required this.levelName,
    required this.xpForCurrentLevel,
    required this.xpForNextLevel,
    required this.levelProgress,
    required this.successRate,
    required this.totalLogs,
    required this.successCount,
    required this.partialCount,
    required this.failedCount,
    required this.currentStreak,
    required this.longestStreak,
    required this.cuisineDistribution,
    required this.recipeCount,
    required this.logCount,
    required this.savedCount,
  });

  factory CookingDnaDto.fromJson(Map<String, dynamic> json) =>
      _$CookingDnaDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CookingDnaDtoToJson(this);

  /// Get localized level name key for i18n
  String get levelNameKey => 'profile.$levelName';

  /// Get XP progress as percentage string
  String get xpProgressText => '$totalXp / $xpForNextLevel XP';

  /// Get success rate as percentage
  int get successRatePercent => (successRate * 100).round();
}
