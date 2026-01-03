import 'package:dartz/dartz.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';

abstract class AuthRepository {
  // ... 기존 로그인 메서드

  Future<Either<Failure, bool>> loginWithGoogle(String idToken);
  Future<Either<Failure, bool>> loginWithApple({
    required String identityToken,
    required String authorizationCode,
  });
}
