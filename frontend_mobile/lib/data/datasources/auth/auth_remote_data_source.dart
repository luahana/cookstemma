import 'package:dio/dio.dart';
import '../../models/auth/auth_response_dto.dart';
import '../../models/auth/social_login_request_dto.dart'; // 💡 추가
import '../../models/auth/token_reissue_request_dto.dart'; // 💡 추가

class AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSource(this._dio);

  /// 소셜 로그인 요청
  Future<AuthResponseDto> socialLogin(SocialLoginRequestDto request) async {
    final response = await _dio.post(
      '/auth/social-login',
      data: request.toJson(), // 💡 DTO의 toJson() 사용
    );
    return AuthResponseDto.fromJson(response.data);
  }

  /// 토큰 재발급 요청
  Future<AuthResponseDto> reissueToken(TokenReissueRequestDto request) async {
    final response = await _dio.post(
      '/auth/reissue',
      data: request.toJson(), // 💡 DTO의 toJson() 사용
    );
    return AuthResponseDto.fromJson(response.data);
  }
}
