import 'package:dartz/dartz.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';
import 'package:pairing_planet2_frontend/domain/repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository _repository;

  LogoutUseCase(this._repository);

  /// 로그아웃 비즈니스 로직 실행
  Future<Either<Failure, Unit>> execute() async {
    // 💡 Repository에 정의된 logout을 호출하여
    // 로컬 토큰 삭제 및 소셜 로그아웃을 한 번에 처리합니다.
    return await _repository.logout();
  }
}
