import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  // 💡 보안 저장소 인스턴스 생성
  final _storage = const FlutterSecureStorage();

  // 키 값 정의
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _termsAcceptedKey = 'terms_accepted_at';
  static const _termsVersionKey = 'terms_version';
  static const _privacyAcceptedKey = 'privacy_accepted_at';
  static const _privacyVersionKey = 'privacy_version';
  static const _marketingAgreedKey = 'marketing_agreed';

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

  // --- Legal Agreement 관련 ---

  /// Current version of terms - increment when terms change
  static const currentTermsVersion = '1.0.0';
  static const currentPrivacyVersion = '1.0.0';

  /// Save legal agreement acceptance
  Future<void> saveLegalAcceptance({
    required bool marketingAgreed,
  }) async {
    final now = DateTime.now().toIso8601String();
    await _storage.write(key: _termsAcceptedKey, value: now);
    await _storage.write(key: _termsVersionKey, value: currentTermsVersion);
    await _storage.write(key: _privacyAcceptedKey, value: now);
    await _storage.write(key: _privacyVersionKey, value: currentPrivacyVersion);
    await _storage.write(key: _marketingAgreedKey, value: marketingAgreed.toString());
  }

  /// Check if user has accepted current terms and privacy policy
  Future<bool> hasAcceptedLegalTerms() async {
    final termsVersion = await _storage.read(key: _termsVersionKey);
    final privacyVersion = await _storage.read(key: _privacyVersionKey);

    // User needs to accept if:
    // 1. Never accepted before (null)
    // 2. Accepted an older version
    return termsVersion == currentTermsVersion &&
           privacyVersion == currentPrivacyVersion;
  }

  /// Get marketing agreement status
  Future<bool> getMarketingAgreed() async {
    final value = await _storage.read(key: _marketingAgreedKey);
    return value == 'true';
  }

  /// Clear legal acceptance (for testing or when user logs out)
  Future<void> clearLegalAcceptance() async {
    await _storage.delete(key: _termsAcceptedKey);
    await _storage.delete(key: _termsVersionKey);
    await _storage.delete(key: _privacyAcceptedKey);
    await _storage.delete(key: _privacyVersionKey);
    await _storage.delete(key: _marketingAgreedKey);
  }
}
