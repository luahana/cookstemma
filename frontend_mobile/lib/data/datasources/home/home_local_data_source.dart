import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:pairing_planet2_frontend/core/utils/cache_utils.dart';
import 'package:pairing_planet2_frontend/core/utils/json_parser.dart';
import 'package:pairing_planet2_frontend/data/models/home/home_feed_response_dto.dart';
import 'package:pairing_planet2_frontend/data/models/local/cached_home_feed.dart';

class HomeLocalDataSource {
  final Isar _isar;
  static const String _cacheKey = 'home_feed';

  HomeLocalDataSource(this._isar);

  Future<void> cacheHomeFeed(HomeFeedResponseDto feed) async {
    final cachedAt = DateTime.now();
    final jsonData = {
      'data': feed.toJson(),
      'cachedAt': cachedAt.toIso8601String(),
    };

    await _isar.writeTxn(() async {
      final existing = await _isar.cachedHomeFeeds
          .filter()
          .cacheKeyEqualTo(_cacheKey)
          .findFirst();

      final cached = CachedHomeFeed()
        ..cacheKey = _cacheKey
        ..jsonData = jsonEncode(jsonData)
        ..cachedAt = cachedAt;

      if (existing != null) {
        cached.id = existing.id;
      }
      await _isar.cachedHomeFeeds.put(cached);
    });
  }

  Future<CachedData<HomeFeedResponseDto>?> getCachedHomeFeed() async {
    final cached = await _isar.cachedHomeFeeds
        .filter()
        .cacheKeyEqualTo(_cacheKey)
        .findFirst();

    if (cached == null) return null;

    try {
      // Parse JSON in background isolate to avoid UI thread blocking
      final json = await parseJsonInBackground(cached.jsonData);
      final feedJson = json['data'] as Map<String, dynamic>;
      final cachedAt = DateTime.parse(json['cachedAt'] as String);

      return CachedData(
        data: HomeFeedResponseDto.fromJson(feedJson),
        cachedAt: cachedAt,
      );
    } catch (e) {
      await clearCache();
      return null;
    }
  }

  Future<void> clearCache() async {
    await _isar.writeTxn(() async {
      await _isar.cachedHomeFeeds.clear();
    });
  }
}
