import 'package:dartz/dartz.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';

abstract class AuthRepository {
  Future<Either<Failure, Unit>> socialLogin(String firebaseIdToken);

  /// 토큰을 갱신합니다.
  Future<Either<Failure, Unit>> reissueToken();

  Future<Either<Failure, Unit>> logout();

  /// 로컬 토큰만 삭제합니다 (게스트 모드 진입 시 사용).
  Future<void> clearTokens();
}
