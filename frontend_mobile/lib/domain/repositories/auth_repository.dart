import 'package:dartz/dartz.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';

abstract class AuthRepository {
  Future<Either<Failure, Unit>> socialLogin(String firebaseIdToken);

  /// 토큰을 갱신합니다.
  Future<Either<Failure, Unit>> reissueToken();

  Future<Either<Failure, Unit>> logout();
}
