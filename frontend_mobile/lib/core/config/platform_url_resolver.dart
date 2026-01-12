import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Resolves URLs for different platforms (iOS vs Android) during local development.
/// Handles the difference between localhost (iOS) and 10.0.2.2 (Android emulator).
class PlatformUrlResolver {
  static String get baseUrl {
    final envUrl = dotenv.maybeGet('BASE_URL');

    // If .env specifies a URL, use it directly without auto-conversion
    // This allows explicit localhost for physical devices with adb reverse
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }

    // Default fallback with platform awareness (only for emulator)
    return _getDefaultLocalUrl();
  }

  static String _adjustLocalUrl(String url) {
    return adjustUrlForPlatform(url);
  }

  /// Adjusts any URL containing local dev hostnames (10.0.2.2 or localhost)
  /// to use the correct hostname for the current platform.
  /// Use this for image URLs, API URLs, or any other network resources.
  /// Note: Real IP addresses (like 10.0.0.x) are not modified.
  /// Note: If BASE_URL is explicitly set to localhost, no conversion is done
  ///       (for physical devices with adb reverse).
  static String adjustUrlForPlatform(String url) {
    // Don't modify URLs with real IP addresses (for real device testing)
    if (_hasRealIpAddress(url)) {
      return url;
    }

    // If BASE_URL explicitly uses localhost, don't convert (adb reverse mode)
    final envUrl = dotenv.maybeGet('BASE_URL');
    if (envUrl != null && envUrl.contains('localhost')) {
      // Convert any 10.0.2.2 URLs to localhost for consistency
      return url.replaceAll('10.0.2.2', 'localhost');
    }

    if (Platform.isIOS) {
      // iOS simulator uses localhost
      return url.replaceAll('10.0.2.2', 'localhost');
    } else if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 for host machine
      return url.replaceAll('localhost', '10.0.2.2');
    }
    return url;
  }

  /// Check if URL contains a real IP address (not localhost or 10.0.2.2)
  static bool _hasRealIpAddress(String url) {
    // Match IP addresses but exclude 10.0.2.2 (Android emulator)
    final ipRegex = RegExp(r'\b(?!10\.0\.2\.2)\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b');
    return ipRegex.hasMatch(url);
  }

  static String _getDefaultLocalUrl() {
    final host = Platform.isIOS ? 'localhost' : '10.0.2.2';
    return 'http://$host:4001/api/v1';
  }

  static bool get isDev => dotenv.get('ENV', fallback: 'dev') == 'dev';
}
