import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:pairing_planet2_frontend/core/utils/logger.dart';

/// Interceptor that adds idempotency keys to POST/PATCH requests.
///
/// This prevents duplicate writes when requests are retried due to network issues.
/// The same idempotency key is reused for retries, so the server can detect duplicates.
class IdempotencyInterceptor extends Interceptor {
  /// Map of request ID -> idempotency key for pending requests
  final Map<String, String> _pendingKeys = {};

  final _uuid = const Uuid();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Only add idempotency keys to POST and PATCH requests
    if (options.method == 'POST' || options.method == 'PATCH') {
      final requestId = _generateRequestId(options);

      // Reuse existing key if this is a retry, otherwise generate new one
      final idempotencyKey = _pendingKeys[requestId] ?? _uuid.v4();
      _pendingKeys[requestId] = idempotencyKey;

      options.headers['Idempotency-Key'] = idempotencyKey;

      talker.debug('Idempotency key for ${options.method} ${options.path}: $idempotencyKey');
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Clear the key on successful response
    final requestId = _generateRequestId(response.requestOptions);
    if (_pendingKeys.containsKey(requestId)) {
      talker.debug('Clearing idempotency key for successful request: $requestId');
      _pendingKeys.remove(requestId);
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Only clear the key if the error is not retryable
    // Retryable errors: timeout, connection error, 502, 503, 504
    if (!_isRetryableError(err)) {
      final requestId = _generateRequestId(err.requestOptions);
      if (_pendingKeys.containsKey(requestId)) {
        talker.debug('Clearing idempotency key for non-retryable error: $requestId');
        _pendingKeys.remove(requestId);
      }
    } else {
      talker.debug('Keeping idempotency key for retry: ${err.requestOptions.path}');
    }

    handler.next(err);
  }

  /// Generate a unique request ID based on method, path, and body hash
  String _generateRequestId(RequestOptions options) {
    final method = options.method;
    final path = options.path;
    final bodyHash = _hashBody(options.data);
    return '$method:$path:$bodyHash';
  }

  /// Generate a hash of the request body for identification
  String _hashBody(dynamic data) {
    if (data == null) {
      return 'empty';
    }

    String bodyString;
    if (data is String) {
      bodyString = data;
    } else if (data is Map || data is List) {
      bodyString = jsonEncode(data);
    } else {
      bodyString = data.toString();
    }

    // Use MD5 for fast, short hashes (not for security, just identification)
    final bytes = utf8.encode(bodyString);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Check if the error is retryable (should keep idempotency key)
  bool _isRetryableError(DioException error) {
    // Connection/timeout errors are retryable
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return true;
    }

    // Certain HTTP status codes are retryable
    final statusCode = error.response?.statusCode;
    if (statusCode != null) {
      return statusCode == 502 || statusCode == 503 || statusCode == 504;
    }

    return false;
  }
}
