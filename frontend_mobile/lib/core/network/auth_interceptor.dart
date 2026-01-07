import 'dart:async';
import 'package:dio/dio.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/utils/logger.dart';
import '../services/storage_service.dart';

class AuthInterceptor extends Interceptor {
  final StorageService _storageService;
  final Dio _dio; // 기존 요청용 Dio

  // 💡 갱신 전용 Dio (인터셉터 무한 루프 방지)
  late final Dio _refreshDio;

  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

  AuthInterceptor(this._storageService, this._dio) {
    _refreshDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
  }

  @override
  void onRequest(
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
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != HttpStatus.unauthorized) {
      return handler.next(err);
    }

    // 💡 갱신 요청 자체가 401이 난 경우 (리프레시 토큰 만료) 즉시 에러 처리
    if (err.requestOptions.path.contains('/auth/reissue')) {
      _isRefreshing = false;
      return handler.next(err);
    }
    if (_isRefreshing) {
      talker.info("이미 토큰 갱신 중입니다. 대기열 진입.");
      final newToken = await _refreshCompleter?.future;
      if (newToken != null) {
        return handler.resolve(await _retry(err.requestOptions));
      }
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<String?>();

    try {
      talker.info("토큰 만료 감지: 갱신 시작");
      final refreshToken = await _storageService.getRefreshToken();

      // 💡 1. 리프레시 토큰이 null인지 먼저 확인합니다.
      if (refreshToken == null || refreshToken.isEmpty) {
        talker.error("리프레시 토큰이 저장소에 없습니다. 재발급 중단.");
        _isRefreshing = false;
        // 토큰이 없으면 재발급이 불가능하므로 저장소를 비우고 종료합니다.
        await _storageService.clearTokens();
        return handler.next(err);
      }

      talker.info("서버로 전송할 리프레시 토큰: $refreshToken");

      // 💡 별도의 _refreshDio를 사용하여 인터셉터 중복 실행 방지
      final response = await _refreshDio.post(
        '/auth/reissue',
        data: {'refreshToken': refreshToken},
      );

      final newAccessToken = response.data['accessToken'];
      final newRefreshToken = response.data['refreshToken'];

      await _storageService.saveAccessToken(newAccessToken);
      await _storageService.saveRefreshToken(newRefreshToken);

      _refreshCompleter?.complete(newAccessToken);
      _isRefreshing = false;

      return handler.resolve(await _retry(err.requestOptions));
    } catch (e) {
      _refreshCompleter?.complete(null);
      _isRefreshing = false;
      // 여기서 로그아웃 이벤트를 브로드캐스트하거나 Provider를 통해 상태 변경 가능
      await _storageService.clearTokens();
      return handler.next(err);
    }
  }

  Future<Response> _retry(RequestOptions requestOptions) async {
    final token = await _storageService.getAccessToken();
    final options = Options(
      method: requestOptions.method,
      headers: {...requestOptions.headers, 'Authorization': 'Bearer $token'},
    );

    // 💡 재시도는 원래의 _dio를 사용하여 다시 전체 인터셉터 체인을 타게 함
    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
