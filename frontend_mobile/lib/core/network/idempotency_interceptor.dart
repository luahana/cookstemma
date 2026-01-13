import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:pairing_planet2_frontend/core/utils/logger.dart';

/// Entry storing an idempotency key with its creation time
class _IdempotencyEntry {
  final String key;
  final DateTime createdAt;

  _IdempotencyEntry(this.key) : createdAt = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(createdAt).inSeconds > IdempotencyInterceptor._keyTtlSeconds;
}

/// Interceptor that adds idempotency keys to POST/PATCH requests.
///
/// This prevents duplicate writes when requests are retried due to network issues
/// or rapid double-taps. The same idempotency key is reused for identical requests
/// within a 30-second window, so the server can detect and dedupe duplicates.
class IdempotencyInterceptor extends Interceptor {
  /// How long to keep idempotency keys (in seconds)
  static const _keyTtlSeconds = 30;

  /// Map of request ID -> idempotency entry (key + timestamp)
  final Map<String, _IdempotencyEntry> _entries = {};

  final _uuid = const Uuid();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Only add idempotency keys to POST and PATCH requests
    if (options.method == 'POST' || options.method == 'PATCH') {
      // Skip multipart/form-data requests (file uploads)
      // FormData.toString() doesn't include file content, causing different uploads
      // to get the same request ID and reuse the same idempotency key incorrectly.
      if (options.data is FormData) {
        handler.next(options);
        return;
      }

      // Clean up expired entries lazily
      _cleanupExpiredEntries();

      final requestId = _generateRequestId(options);

      // Reuse existing key if not expired, otherwise generate new one
      final existingEntry = _entries[requestId];
      final String idempotencyKey;

      if (existingEntry != null && !existingEntry.isExpired) {
        idempotencyKey = existingEntry.key;
      } else {
        idempotencyKey = _uuid.v4();
        _entries[requestId] = _IdempotencyEntry(idempotencyKey);
      }

      options.headers['Idempotency-Key'] = idempotencyKey;
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Don't remove the key immediately - keep it for TTL duration
    // This prevents duplicates from rapid double-taps
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Only clear the key if the error is not retryable
    // Retryable errors: timeout, connection error, 502, 503, 504
    if (!_isRetryableError(err)) {
      final requestId = _generateRequestId(err.requestOptions);
      if (_entries.containsKey(requestId)) {
        talker.debug('Clearing idempotency key for non-retryable error: $requestId');
        _entries.remove(requestId);
      }
    } else {
      talker.debug('Keeping idempotency key for retry: ${err.requestOptions.path}');
    }

    handler.next(err);
  }

  /// Remove expired entries to prevent memory leaks
  void _cleanupExpiredEntries() {
    _entries.removeWhere((_, entry) => entry.isExpired);
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
