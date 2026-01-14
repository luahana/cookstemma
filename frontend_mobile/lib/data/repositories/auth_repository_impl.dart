import 'package:dartz/dartz.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';
import 'package:pairing_planet2_frontend/core/services/fcm_service.dart';
import 'package:pairing_planet2_frontend/core/services/social_auth_service.dart';
import 'package:pairing_planet2_frontend/data/datasources/auth/auth_local_data_source.dart';
import 'package:pairing_planet2_frontend/data/datasources/auth/auth_remote_data_source.dart';
import 'package:pairing_planet2_frontend/domain/repositories/auth_repository.dart';
import 'package:pairing_planet2_frontend/data/models/auth/social_login_request_dto.dart';
import 'package:pairing_planet2_frontend/data/models/auth/token_reissue_request_dto.dart';
import 'package:pairing_planet2_frontend/data/models/auth/auth_response_dto.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource; // 💡 이전에 만든 로컬 소스
  final SocialAuthService _socialAuthService; // 💡 소셜 로그아웃을 위해 추가
  final FcmService _fcmService; // 💡 FCM 토큰 삭제를 위해 추가
  final String Function() getCurrentLocale;

  AuthRepositoryImpl(
    this.remoteDataSource,
    this.localDataSource,
    this._socialAuthService,
    this._fcmService,
    this.getCurrentLocale,
  );

  @override
  Future<Either<Failure, Unit>> socialLogin(String firebaseIdToken) async {
    try {
      final String currentLocale = getCurrentLocale();

      // 💡 1. SocialLoginRequestDto 객체를 생성하여 전달합니다.
      final request = SocialLoginRequestDto(
        idToken: firebaseIdToken,
        locale: currentLocale,
      );

      // 2. 서버 통신 (결과는 AuthResponseDto 객체입니다)
      final AuthResponseDto response = await remoteDataSource.socialLogin(
        request,
      );

      // 💡 3. Map 방식이 아닌 DTO의 속성으로 접근하여 저장합니다.
      await localDataSource.saveTokens(
        response.accessToken,
        response.refreshToken,
      );

      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> reissueToken() async {
    try {
      // 💡 1. 저장소에서 현재 리프레시 토큰을 가져옵니다.
      final refreshToken = await localDataSource.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return Left(ServerFailure('error.noRefreshToken'));
      }

      // 2. TokenReissueRequestDto 객체 생성
      final request = TokenReissueRequestDto(refreshToken: refreshToken);

      // 3. 서버에 재발급 요청
      final AuthResponseDto response = await remoteDataSource.reissueToken(
        request,
      );

      // 4. 새롭게 발급된 액세스/리프레시 토큰 모두 저장 (RTR 대응)
      await localDataSource.saveTokens(
        response.accessToken,
        response.refreshToken,
      );

      return const Right(unit);
    } catch (e) {
      // 재발급 실패 시 토큰을 삭제하여 로그아웃 상태로 유도하는 것이 안전합니다.
      await localDataSource.clearAll();
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      // 1. 로컬 저장소의 모든 토큰 삭제
      await localDataSource.clearAll();

      // 2. FCM 토큰 삭제 (푸시 알림 중지)
      await _fcmService.deleteToken();

      // 3. 소셜 로그인(Firebase/Google) 세션 종료
      await _socialAuthService.signOut();

      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<void> clearTokens() async {
    await localDataSource.clearAll();
  }
}
