import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  // 💡 보안 저장소 인스턴스 생성
  final _storage = const FlutterSecureStorage();

  // 키 값 정의
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  // --- Access Token 관련 ---

  /// 액세스 토큰 저장
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  /// 액세스 토큰 불러오기
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  // --- Refresh Token 관련 ---

  /// 리프레시 토큰 저장
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  /// 리프레시 토큰 불러오기
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // --- 공통 기능 ---

  /// 모든 토큰 삭제 (로그아웃 시 사용)
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
