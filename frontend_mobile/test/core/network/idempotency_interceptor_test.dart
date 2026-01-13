import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pairing_planet2_frontend/core/network/idempotency_interceptor.dart';

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

class MockResponseInterceptorHandler extends Mock
    implements ResponseInterceptorHandler {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

void main() {
  group('IdempotencyInterceptor', () {
    late IdempotencyInterceptor interceptor;
    late MockRequestInterceptorHandler mockRequestHandler;
    late MockResponseInterceptorHandler mockResponseHandler;
    late MockErrorInterceptorHandler mockErrorHandler;

    setUp(() {
      interceptor = IdempotencyInterceptor();
      mockRequestHandler = MockRequestInterceptorHandler();
      mockResponseHandler = MockResponseInterceptorHandler();
      mockErrorHandler = MockErrorInterceptorHandler();
    });

    setUpAll(() {
      registerFallbackValue(RequestOptions(path: ''));
      registerFallbackValue(Response(requestOptions: RequestOptions(path: '')));
      registerFallbackValue(DioException(requestOptions: RequestOptions(path: '')));
    });

    group('onRequest', () {
      test('adds Idempotency-Key header to POST requests', () {
        final options = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'test'},
        );

        interceptor.onRequest(options, mockRequestHandler);

        expect(options.headers['Idempotency-Key'], isNotNull);
        expect(options.headers['Idempotency-Key'], isA<String>());
        verify(() => mockRequestHandler.next(options)).called(1);
      });

      test('adds Idempotency-Key header to PATCH requests', () {
        final options = RequestOptions(
          path: '/api/v1/logs/123',
          method: 'PATCH',
          data: {'content': 'updated'},
        );

        interceptor.onRequest(options, mockRequestHandler);

        expect(options.headers['Idempotency-Key'], isNotNull);
        verify(() => mockRequestHandler.next(options)).called(1);
      });

      test('does NOT add header to GET requests', () {
        final options = RequestOptions(
          path: '/api/v1/logs',
          method: 'GET',
        );

        interceptor.onRequest(options, mockRequestHandler);

        expect(options.headers['Idempotency-Key'], isNull);
        verify(() => mockRequestHandler.next(options)).called(1);
      });

      test('does NOT add header to DELETE requests', () {
        final options = RequestOptions(
          path: '/api/v1/logs/123',
          method: 'DELETE',
        );

        interceptor.onRequest(options, mockRequestHandler);

        expect(options.headers['Idempotency-Key'], isNull);
        verify(() => mockRequestHandler.next(options)).called(1);
      });

      test('does NOT add header to PUT requests', () {
        final options = RequestOptions(
          path: '/api/v1/logs/123',
          method: 'PUT',
          data: {'content': 'replaced'},
        );

        interceptor.onRequest(options, mockRequestHandler);

        expect(options.headers['Idempotency-Key'], isNull);
        verify(() => mockRequestHandler.next(options)).called(1);
      });

      test('does NOT add header to POST requests with FormData', () {
        final formData = FormData.fromMap({'file': 'test'});
        final options = RequestOptions(
          path: '/api/v1/images/upload',
          method: 'POST',
          data: formData,
        );

        interceptor.onRequest(options, mockRequestHandler);

        expect(options.headers['Idempotency-Key'], isNull);
        verify(() => mockRequestHandler.next(options)).called(1);
      });

      test('does NOT add header to PATCH requests with FormData', () {
        final formData = FormData.fromMap({'file': 'test'});
        final options = RequestOptions(
          path: '/api/v1/images/123',
          method: 'PATCH',
          data: formData,
        );

        interceptor.onRequest(options, mockRequestHandler);

        expect(options.headers['Idempotency-Key'], isNull);
        verify(() => mockRequestHandler.next(options)).called(1);
      });

      test('different FormData POST requests are passed through independently', () {
        final formData1 = FormData.fromMap({'file': 'image1.jpg'});
        final formData2 = FormData.fromMap({'file': 'image2.jpg'});

        final options1 = RequestOptions(
          path: '/api/v1/images/upload',
          method: 'POST',
          data: formData1,
        );
        final options2 = RequestOptions(
          path: '/api/v1/images/upload',
          method: 'POST',
          data: formData2,
        );

        interceptor.onRequest(options1, mockRequestHandler);
        interceptor.onRequest(options2, mockRequestHandler);

        // Both should pass through without idempotency keys
        expect(options1.headers['Idempotency-Key'], isNull);
        expect(options2.headers['Idempotency-Key'], isNull);
        verify(() => mockRequestHandler.next(any())).called(2);
      });

      test('reuses same key for identical requests within TTL', () {
        final options1 = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'test'},
        );
        final options2 = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'test'},
        );

        interceptor.onRequest(options1, mockRequestHandler);
        interceptor.onRequest(options2, mockRequestHandler);

        expect(
          options1.headers['Idempotency-Key'],
          equals(options2.headers['Idempotency-Key']),
        );
      });

      test('generates different keys for different request bodies', () {
        final options1 = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'first'},
        );
        final options2 = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'second'},
        );

        interceptor.onRequest(options1, mockRequestHandler);
        interceptor.onRequest(options2, mockRequestHandler);

        expect(
          options1.headers['Idempotency-Key'],
          isNot(equals(options2.headers['Idempotency-Key'])),
        );
      });

      test('generates different keys for different paths', () {
        final options1 = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'test'},
        );
        final options2 = RequestOptions(
          path: '/api/v1/recipes',
          method: 'POST',
          data: {'content': 'test'},
        );

        interceptor.onRequest(options1, mockRequestHandler);
        interceptor.onRequest(options2, mockRequestHandler);

        expect(
          options1.headers['Idempotency-Key'],
          isNot(equals(options2.headers['Idempotency-Key'])),
        );
      });

      test('handles null body correctly', () {
        final options = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: null,
        );

        interceptor.onRequest(options, mockRequestHandler);

        expect(options.headers['Idempotency-Key'], isNotNull);
      });

      test('handles string body correctly', () {
        final options = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: 'raw string body',
        );

        interceptor.onRequest(options, mockRequestHandler);

        expect(options.headers['Idempotency-Key'], isNotNull);
      });

      test('handles list body correctly', () {
        final options = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: ['item1', 'item2'],
        );

        interceptor.onRequest(options, mockRequestHandler);

        expect(options.headers['Idempotency-Key'], isNotNull);
      });

      test('idempotency key is a valid UUID format', () {
        final options = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'test'},
        );

        interceptor.onRequest(options, mockRequestHandler);

        final key = options.headers['Idempotency-Key'] as String;
        // UUID format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
        final uuidRegex = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          caseSensitive: false,
        );
        expect(uuidRegex.hasMatch(key), isTrue);
      });
    });

    group('onResponse', () {
      test('passes response through without modification', () {
        final options = RequestOptions(path: '/api/v1/logs', method: 'POST');
        final response = Response(
          requestOptions: options,
          statusCode: 200,
          data: {'id': '123'},
        );

        interceptor.onResponse(response, mockResponseHandler);

        verify(() => mockResponseHandler.next(response)).called(1);
      });

      test('key persists after successful response for TTL duration', () {
        // First request
        final options1 = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'test'},
        );
        interceptor.onRequest(options1, mockRequestHandler);
        final key1 = options1.headers['Idempotency-Key'];

        // Simulate successful response
        final response = Response(
          requestOptions: options1,
          statusCode: 201,
        );
        interceptor.onResponse(response, mockResponseHandler);

        // Second identical request should get same key (key persists)
        final options2 = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'test'},
        );
        interceptor.onRequest(options2, mockRequestHandler);
        final key2 = options2.headers['Idempotency-Key'];

        expect(key1, equals(key2));
      });
    });

    group('onError', () {
      test('clears key on 400 Bad Request error', () {
        // First request
        final options1 = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'test'},
        );
        interceptor.onRequest(options1, mockRequestHandler);
        final key1 = options1.headers['Idempotency-Key'];

        // Simulate 400 error
        final error = DioException(
          requestOptions: options1,
          response: Response(
            requestOptions: options1,
            statusCode: 400,
          ),
          type: DioExceptionType.badResponse,
        );
        interceptor.onError(error, mockErrorHandler);

        // Second request should get new key (old one cleared)
        final options2 = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'test'},
        );
        interceptor.onRequest(options2, mockRequestHandler);
        final key2 = options2.headers['Idempotency-Key'];

        expect(key1, isNot(equals(key2)));
        verify(() => mockErrorHandler.next(error)).called(1);
      });

      test('keeps key on 502 Bad Gateway error (retryable)', () {
        // First request
        final options1 = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'test'},
        );
        interceptor.onRequest(options1, mockRequestHandler);
        final key1 = options1.headers['Idempotency-Key'];

        // Simulate 502 error
        final error = DioException(
          requestOptions: options1,
          response: Response(
            requestOptions: options1,
            statusCode: 502,
          ),
          type: DioExceptionType.badResponse,
        );
        interceptor.onError(error, mockErrorHandler);

        // Second request should get same key (retryable, key kept)
        final options2 = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'test'},
        );
        interceptor.onRequest(options2, mockRequestHandler);
        final key2 = options2.headers['Idempotency-Key'];

        expect(key1, equals(key2));
      });

      test('keeps key on 503 Service Unavailable error (retryable)', () {
        final options1 = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'test'},
        );
        interceptor.onRequest(options1, mockRequestHandler);
        final key1 = options1.headers['Idempotency-Key'];

        final error = DioException(
          requestOptions: options1,
          response: Response(
            requestOptions: options1,
            statusCode: 503,
          ),
          type: DioExceptionType.badResponse,
        );
        interceptor.onError(error, mockErrorHandler);

        final options2 = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'test'},
        );
        interceptor.onRequest(options2, mockRequestHandler);
        final key2 = options2.headers['Idempotency-Key'];

        expect(key1, equals(key2));
      });

      test('keeps key on 504 Gateway Timeout error (retryable)', () {
        final options1 = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'test'},
        );
        interceptor.onRequest(options1, mockRequestHandler);
        final key1 = options1.headers['Idempotency-Key'];

        final error = DioException(
          requestOptions: options1,
          response: Response(
            requestOptions: options1,
            statusCode: 504,
          ),
          type: DioExceptionType.badResponse,
        );
        interceptor.onError(error, mockErrorHandler);

        final options2 = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'test'},
        );
        interceptor.onRequest(options2, mockRequestHandler);
        final key2 = options2.headers['Idempotency-Key'];

        expect(key1, equals(key2));
      });

      test('keeps key on connection timeout error (retryable)', () {
        final options1 = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'test'},
        );
        interceptor.onRequest(options1, mockRequestHandler);
        final key1 = options1.headers['Idempotency-Key'];

        final error = DioException(
          requestOptions: options1,
          type: DioExceptionType.connectionTimeout,
        );
        interceptor.onError(error, mockErrorHandler);

        final options2 = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'test'},
        );
        interceptor.onRequest(options2, mockRequestHandler);
        final key2 = options2.headers['Idempotency-Key'];

        expect(key1, equals(key2));
      });

      test('keeps key on receive timeout error (retryable)', () {
        final options1 = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'test'},
        );
        interceptor.onRequest(options1, mockRequestHandler);
        final key1 = options1.headers['Idempotency-Key'];

        final error = DioException(
          requestOptions: options1,
          type: DioExceptionType.receiveTimeout,
        );
        interceptor.onError(error, mockErrorHandler);

        final options2 = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'test'},
        );
        interceptor.onRequest(options2, mockRequestHandler);
        final key2 = options2.headers['Idempotency-Key'];

        expect(key1, equals(key2));
      });

      test('keeps key on send timeout error (retryable)', () {
        final options1 = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'test'},
        );
        interceptor.onRequest(options1, mockRequestHandler);
        final key1 = options1.headers['Idempotency-Key'];

        final error = DioException(
          requestOptions: options1,
          type: DioExceptionType.sendTimeout,
        );
        interceptor.onError(error, mockErrorHandler);

        final options2 = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'test'},
        );
        interceptor.onRequest(options2, mockRequestHandler);
        final key2 = options2.headers['Idempotency-Key'];

        expect(key1, equals(key2));
      });

      test('keeps key on connection error (retryable)', () {
        final options1 = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'test'},
        );
        interceptor.onRequest(options1, mockRequestHandler);
        final key1 = options1.headers['Idempotency-Key'];

        final error = DioException(
          requestOptions: options1,
          type: DioExceptionType.connectionError,
        );
        interceptor.onError(error, mockErrorHandler);

        final options2 = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'test'},
        );
        interceptor.onRequest(options2, mockRequestHandler);
        final key2 = options2.headers['Idempotency-Key'];

        expect(key1, equals(key2));
      });

      test('clears key on 404 Not Found error (non-retryable)', () {
        final options1 = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'test'},
        );
        interceptor.onRequest(options1, mockRequestHandler);
        final key1 = options1.headers['Idempotency-Key'];

        final error = DioException(
          requestOptions: options1,
          response: Response(
            requestOptions: options1,
            statusCode: 404,
          ),
          type: DioExceptionType.badResponse,
        );
        interceptor.onError(error, mockErrorHandler);

        final options2 = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'test'},
        );
        interceptor.onRequest(options2, mockRequestHandler);
        final key2 = options2.headers['Idempotency-Key'];

        expect(key1, isNot(equals(key2)));
      });

      test('clears key on 500 Internal Server Error (non-retryable)', () {
        final options1 = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'test'},
        );
        interceptor.onRequest(options1, mockRequestHandler);
        final key1 = options1.headers['Idempotency-Key'];

        final error = DioException(
          requestOptions: options1,
          response: Response(
            requestOptions: options1,
            statusCode: 500,
          ),
          type: DioExceptionType.badResponse,
        );
        interceptor.onError(error, mockErrorHandler);

        final options2 = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'test'},
        );
        interceptor.onRequest(options2, mockRequestHandler);
        final key2 = options2.headers['Idempotency-Key'];

        expect(key1, isNot(equals(key2)));
      });
    });

    group('multiple interceptor instances', () {
      test('different interceptor instances have separate key stores', () {
        final interceptor1 = IdempotencyInterceptor();
        final interceptor2 = IdempotencyInterceptor();

        final options1 = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'test'},
        );
        final options2 = RequestOptions(
          path: '/api/v1/logs',
          method: 'POST',
          data: {'content': 'test'},
        );

        interceptor1.onRequest(options1, mockRequestHandler);
        interceptor2.onRequest(options2, mockRequestHandler);

        // Different instances should generate different keys
        expect(
          options1.headers['Idempotency-Key'],
          isNot(equals(options2.headers['Idempotency-Key'])),
        );
      });
    });
  });
}
