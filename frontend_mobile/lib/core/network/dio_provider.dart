import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/core/config/app_config.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/network/auth_interceptor.dart';
import 'package:pairing_planet2_frontend/core/network/idempotency_interceptor.dart';
import 'package:pairing_planet2_frontend/core/providers/locale_provider.dart';
import 'package:pairing_planet2_frontend/core/services/storage_service.dart';
import 'package:pairing_planet2_frontend/core/services/toast_service.dart';
import 'package:pairing_planet2_frontend/core/utils/logger.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

// 💡 StorageService도 Provider로 관리하는 것이 좋습니다.
final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(),
);

final dioProvider = Provider<Dio>((ref) {
  final storageService = ref.read(storageServiceProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      contentType: 'application/json',
    ),
  );

  // 1. 로깅 인터셉터 (가장 바깥쪽에서 모든 흐름을 기록)
  dio.interceptors.add(
    TalkerDioLogger(
      talker: talker, // 💡 core/utils/logger.dart의 전역 talker 사용
      settings: const TalkerDioLoggerSettings(
        printRequestHeaders: true,
        printResponseHeaders: false,
        printResponseMessage: true,
        printRequestData: true,
        printResponseData: true,
      ),
    ),
  );

  // 2. 공통 헤더 주입 (인증보다 먼저 실행되어야 함)
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // 💡 현재 앱의 언어 코드를 가져와 헤더에 삽입 (예: 'ko', 'en')
        // context가 없는 환경이라면 별도의 LanguageService를 만들어 관리해야 합니다.
        final currentLocale = ref.read(localeProvider);
        options.headers['Accept-Language'] = currentLocale;

        return handler.next(options);
      },
    ),
  );

  // 3. 인증 인터셉터 (401 발생 시 토큰 갱신 후 재시도)
  dio.interceptors.add(AuthInterceptor(storageService, dio));

  // 4. 멱등성 인터셉터 (POST/PATCH 요청에 고유 키 추가)
  // 💡 재시도 인터셉터보다 먼저 실행되어야 동일한 키로 재시도됨
  dio.interceptors.add(IdempotencyInterceptor());

  // 5. 네트워크 재시도 인터셉터
  // 💡 멱등성 인터셉터가 키를 보존하므로 재시도 시 동일한 키 사용
  dio.interceptors.add(
    RetryInterceptor(
      dio: dio,
      logPrint: (message) => talker.info(message), // 💡 print 대신 talker로 출력
      retries: 3,
      retryDelays: const [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 4),
      ],
      retryableExtraStatuses: {
        status502BadGateway,
        status503ServiceUnavailable,
        status504GatewayTimeout,
      },
    ),
  );

  // 6. 최하단: 사용자 알림 및 로그 (최종 결과에 대해 Toast 출력)
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (DioException e, handler) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError) {
          ToastService.showError("네트워크 연결이 불안정합니다.");
        } else if (e.response?.statusCode == HttpStatus.serverError) {
          FirebaseCrashlytics.instance.log(
            "Server Error 500: ${e.requestOptions.path}",
          );
          ToastService.showError("서버 내부 오류가 발생했습니다.");
        }
        return handler.next(e);
      },
    ),
  );

  return dio;
});
