import 'package:dio/dio.dart';
import 'package:pairing_planet2_frontend/data/models/notification/notification_list_response.dart';

class NotificationRemoteDataSource {
  final Dio _dio;

  NotificationRemoteDataSource(this._dio);

  /// Register FCM token with backend
  Future<void> registerFcmToken({
    required String fcmToken,
    required String deviceType,
    String? deviceId,
  }) async {
    await _dio.post(
      '/notifications/fcm-token',
      data: {
        'fcmToken': fcmToken,
        'deviceType': deviceType,
        if (deviceId != null) 'deviceId': deviceId,
      },
    );
  }

  /// Unregister FCM token
  Future<void> unregisterFcmToken(String token) async {
    await _dio.delete(
      '/notifications/fcm-token',
      queryParameters: {'token': token},
    );
  }

  /// Get notifications with pagination
  Future<NotificationListResponse> getNotifications({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _dio.get(
      '/notifications',
      queryParameters: {'page': page, 'size': size},
    );
    return NotificationListResponse.fromJson(response.data);
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    final response = await _dio.get('/notifications/unread-count');
    return response.data['unreadCount'] as int;
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _dio.patch('/notifications/$notificationId/read');
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    await _dio.patch('/notifications/read-all');
  }
}
