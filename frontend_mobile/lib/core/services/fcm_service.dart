import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:pairing_planet2_frontend/core/utils/logger.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  talker.info('Handling background message: ${message.messageId}');
  // Background messages are automatically displayed as system notifications
}

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialize FCM and request permissions
  Future<String?> initialize() async {
    // Request permission (iOS and Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      talker.warning('User denied notification permission');
      return null;
    }

    talker.info('Notification permission: ${settings.authorizationStatus}');

    // Get FCM token
    String? token = await _messaging.getToken();
    if (token != null) {
      talker.info('FCM Token: ${token.substring(0, 20)}...');
    }

    return token;
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Get device type for backend
  String getDeviceType() {
    if (Platform.isAndroid) return 'ANDROID';
    if (Platform.isIOS) return 'IOS';
    return 'WEB';
  }

  /// Listen for token refresh
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  /// Listen for foreground messages
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  /// Listen for notification taps (app opened from notification)
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  /// Check if app was opened from a notification
  Future<RemoteMessage?> getInitialMessage() async {
    return await _messaging.getInitialMessage();
  }

  /// Delete FCM token (for logout)
  Future<void> deleteToken() async {
    await _messaging.deleteToken();
  }
}
