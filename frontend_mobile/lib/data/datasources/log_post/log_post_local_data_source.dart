import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:pairing_planet2_frontend/core/utils/json_parser.dart';
import 'package:pairing_planet2_frontend/data/models/local/cached_log_post.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/log_post_detail_response_dto.dart';

class LogPostLocalDataSource {
  final Isar _isar;

  LogPostLocalDataSource(this._isar);

  Future<void> cacheLogDetail(LogPostDetailResponseDto logPost) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.cachedLogPosts
          .filter()
          .publicIdEqualTo(logPost.publicId)
          .findFirst();

      final cached = CachedLogPost()
        ..publicId = logPost.publicId
        ..jsonData = jsonEncode(logPost.toJson())
        ..cachedAt = DateTime.now();

      if (existing != null) {
        cached.id = existing.id;
      }
      await _isar.cachedLogPosts.put(cached);
    });
  }

  Future<LogPostDetailResponseDto?> getLastLogDetail(String publicId) async {
    final cached = await _isar.cachedLogPosts
        .filter()
        .publicIdEqualTo(publicId)
        .findFirst();

    if (cached != null) {
      try {
        // Parse JSON in background isolate to avoid UI thread blocking
        final json = await parseJsonInBackground(cached.jsonData);
        return LogPostDetailResponseDto.fromJson(json);
      } catch (e) {
        await _isar.writeTxn(() async {
          await _isar.cachedLogPosts.delete(cached.id);
        });
        return null;
      }
    }
    return null;
  }

  Future<void> clearCache() async {
    await _isar.writeTxn(() async {
      await _isar.cachedLogPosts.clear();
    });
  }
}
