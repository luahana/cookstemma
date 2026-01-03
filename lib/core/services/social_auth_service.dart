import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SocialAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'https://www.googleapis.com/auth/contacts.readonly'],
  );

  // Google 로그인 실행
  Future<String?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // 사용자가 취소함

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    return googleAuth.idToken; // 💡 이 토큰을 백엔드에 전송합니다.
  }

  // Apple 로그인 실행
  Future<AuthorizationCredentialAppleID?> signInWithApple() async {
    return await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
  }
}
