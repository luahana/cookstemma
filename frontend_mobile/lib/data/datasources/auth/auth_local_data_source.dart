import 'package:pairing_planet2_frontend/core/services/storage_service.dart';

class AuthLocalDataSource {
  final StorageService _storage;

  AuthLocalDataSource(this._storage);

  /// 💡 액세스 토큰과 리프레시 토큰을 한 번에 저장합니다.
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.saveAccessToken(accessToken);
    await _storage.saveRefreshToken(refreshToken);
  }

  /// 💡 저장된 액세스 토큰을 가져옵니다.
  Future<String?> getAccessToken() async {
    return await _storage.getAccessToken();
  }

  /// 💡 저장된 리프레시 토큰을 가져옵니다.
  Future<String?> getRefreshToken() async {
    return await _storage.getRefreshToken();
  }

  /// 💡 모든 인증 정보를 삭제합니다 (로그아웃 시 사용).
  Future<void> clearAll() async {
    await _storage.clearTokens();
  }
}
