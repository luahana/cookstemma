import 'package:dio/dio.dart';
import '../services/storage_service.dart';

class AuthInterceptor extends Interceptor {
  final StorageService _storageService;
  final Dio _dio; // 토큰 갱신 시 재요청을 위해 필요

  AuthInterceptor(this._storageService, this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storageService.getAccessToken();

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 💡 401 Unauthorized 에러 발생 시 토큰 갱신 로직 실행
    if (err.response?.statusCode == 401) {
      final refreshToken = await _storageService.getRefreshToken();

      if (refreshToken != null) {
        try {
          // 1. 서버에 토큰 갱신 요청 (실제 엔드포인트에 맞게 수정)
          final response = await _dio.post(
            '/auth/refresh',
            data: {'refreshToken': refreshToken},
          );
          final newAccess = response.data['accessToken'];
          final newRefresh = response.data['refreshToken'];

          // 2. 새 토큰 저장
          await _storageService.saveTokens(newAccess, newRefresh);

          // 3. 원래 실패했던 요청 재시도
          err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
          final clonedRequest = await _dio.fetch(err.requestOptions);
          return handler.resolve(clonedRequest);
        } catch (e) {
          // 갱신 실패 시 로그아웃 처리 등 후속 조치
          await _storageService.clearTokens();
        }
      }
    }
    return handler.next(err);
  }
}
