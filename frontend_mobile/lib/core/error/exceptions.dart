/// 서버 통신 중 발생하는 예외
class ServerException implements Exception {
  final String? message;
  ServerException([this.message]);
}

/// 로컬 캐시 처리 중 발생하는 예외
class CacheException implements Exception {}
