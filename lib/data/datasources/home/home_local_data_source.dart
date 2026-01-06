import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:pairing_planet2_frontend/core/utils/cache_utils.dart';
import 'package:pairing_planet2_frontend/data/models/home/home_feed_response_dto.dart';

/// Local data source for caching home feed data using Hive.
class HomeLocalDataSource {
  static const String _boxName = 'home_feed_box';
  static const String _cacheKey = 'home_feed';

  /// Cache the home feed data with current timestamp.
  Future<void> cacheHomeFeed(HomeFeedResponseDto feed) async {
    final box = await Hive.openBox(_boxName);
    final cached = CachedData(data: feed, cachedAt: DateTime.now());
    final jsonData = {
      'data': feed.toJson(),
      'cachedAt': cached.cachedAt.toIso8601String(),
    };
    await box.put(_cacheKey, jsonEncode(jsonData));
  }

  /// Get cached home feed data with timestamp.
  /// Returns null if no cached data exists.
  Future<CachedData<HomeFeedResponseDto>?> getCachedHomeFeed() async {
    final box = await Hive.openBox(_boxName);
    final jsonString = box.get(_cacheKey);

    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final feedJson = json['data'] as Map<String, dynamic>;
      final cachedAt = DateTime.parse(json['cachedAt'] as String);

      return CachedData(
        data: HomeFeedResponseDto.fromJson(feedJson),
        cachedAt: cachedAt,
      );
    } catch (e) {
      // If deserialization fails, clear the corrupted cache
      await clearCache();
      return null;
    }
  }

  /// Clear all cached home feed data.
  Future<void> clearCache() async {
    final box = await Hive.openBox(_boxName);
    await box.clear();
  }
}
