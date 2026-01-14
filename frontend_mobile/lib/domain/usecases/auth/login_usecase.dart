import 'package:dartz/dartz.dart';
import 'package:pairing_planet2_frontend/domain/repositories/auth_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/social_auth_service.dart';

class LoginUseCase {
  final AuthRepository _repository;
  final SocialAuthService _socialAuthService;

  LoginUseCase(this._repository, this._socialAuthService);

  /// 구글 로그인을 수행하는 비즈니스 로직
  Future<Either<Failure, Unit>> executeGoogleLogin() async {
    // 1. 파이어베이스로부터 ID 토큰 획득
    final String? firebaseIdToken = await _socialAuthService.signInWithGoogle();

    if (firebaseIdToken == null) {
      return Left(ServerFailure('error.googleLoginFailed'));
    }

    // 2. 백엔드 서버에 인증 요청 및 토큰 저장
    return await _repository.socialLogin(firebaseIdToken);
  }

  /// Apple 로그인을 수행하는 비즈니스 로직
  Future<Either<Failure, Unit>> executeAppleLogin() async {
    // 1. 파이어베이스로부터 ID 토큰 획득
    final String? firebaseIdToken = await _socialAuthService.signInWithApple();

    if (firebaseIdToken == null) {
      return Left(ServerFailure('error.appleLoginFailed'));
    }

    // 2. 백엔드 서버에 인증 요청 및 토큰 저장
    return await _repository.socialLogin(firebaseIdToken);
  }
}
