import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:pairing_planet2_frontend/core/utils/logger.dart';

// 💡 SocialAuthService를 Provider로 등록
final socialAuthServiceProvider = Provider((ref) => SocialAuthService());

class SocialAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 💡 v7.x에서는 명시적인 scope를 포함하거나 기본 생성자 호출 후 pub get을 다시 확인해야 합니다.
  // 만약 여전히 에러가 난다면 GoogleSignIn.standard()를 시도해 보세요.
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// 1. 구글 로그인 및 Firebase 인증
  Future<String?> signInWithGoogle() async {
    try {
      talker.info("Google 로그인 시도 중...");

      // 1. signIn() 대신 authenticate() 사용
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // 2. ID Token은 authentication에서 직접 가져옴
      final String? idToken = googleUser.authentication.idToken;

      // 3. Access Token은 authorizationClient를 통해 요청
      // scopes는 앱에 필요한 권한에 맞춰 설정하세요.
      final clientAuth = await googleUser.authorizationClient.authorizeScopes([
        'email',
        'profile',
      ]);
      final String accessToken = clientAuth.accessToken;

      // 4. Firebase 자격 증명 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return await userCredential.user?.getIdToken();
    } catch (e, stack) {
      talker.handle(e, stack, "Google 로그인 실패");
      return null;
    }
  }

  /// 2. 애플 로그인 및 Firebase 인증
  /// iOS: 네이티브 Apple Sign-In 사용 (sign_in_with_apple 패키지)
  /// Android: Firebase signInWithProvider 사용 (세션 상태 문제 방지)
  Future<String?> signInWithApple() async {
    try {
      talker.info("Apple 로그인 시작... Platform: ${Platform.operatingSystem}");

      final UserCredential userCredential;

      if (Platform.isAndroid) {
        // Android: Firebase의 signInWithProvider 사용
        // sign_in_with_apple 패키지의 웹 플로우는 세션 상태 문제가 있음
        final provider = OAuthProvider('apple.com');
        provider.addScope('email');
        provider.addScope('name');

        talker.info("Android Apple Sign-In - Using Firebase signInWithProvider");
        userCredential = await _auth.signInWithProvider(provider);
      } else {
        // iOS: 네이티브 플로우 (sign_in_with_apple 패키지)
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );

        final OAuthCredential credential = OAuthProvider('apple.com').credential(
          idToken: appleCredential.identityToken,
          accessToken: appleCredential.authorizationCode,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      final String? idToken = await userCredential.user?.getIdToken();

      talker.info("Apple 로그인 성공 및 Firebase 토큰 발급 완료");
      return idToken;
    } catch (e, stack) {
      talker.handle(e, stack, "Apple 로그인 실패");
      return null;
    }
  }

  /// 3. 로그아웃
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      talker.info("소셜 로그아웃 완료");
    } catch (e) {
      talker.error("로그아웃 실패: $e");
    }
  }
}
