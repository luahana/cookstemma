// lib/data/datasources/log/log_post_local_data_source.dart

import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/log_post_detail_response_dto.dart';

class LogPostLocalDataSource {
  static const String _logBoxName = 'log_post_box';

  // 💡 로그 상세 정보를 Hive에 캐싱합니다.
  Future<void> cacheLogDetail(LogPostDetailResponseDto logPost) async {
    final box = await Hive.openBox(_logBoxName);
    await box.put(logPost.publicId, jsonEncode(logPost.toJson()));
  }

  // 💡 저장된 로그 상세 정보를 불러옵니다.
  Future<LogPostDetailResponseDto?> getLastLogDetail(String publicId) async {
    final box = await Hive.openBox(_logBoxName);
    final jsonString = box.get(publicId);

    if (jsonString != null) {
      return LogPostDetailResponseDto.fromJson(jsonDecode(jsonString));
    }
    return null;
  }
}
