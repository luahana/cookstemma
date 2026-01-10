import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get baseUrl {
    final envUrl = dotenv.maybeGet('BASE_URL');

    // If .env specifies a URL, check if it's a local dev URL that needs platform adjustment
    if (envUrl != null && envUrl.isNotEmpty) {
      // If it's a local dev URL (localhost or 10.0.2.2), adjust for platform
      if (envUrl.contains('10.0.2.2') || envUrl.contains('localhost')) {
        return _adjustLocalUrl(envUrl);
      }
      return envUrl;
    }

    // Default fallback with platform awareness
    return _getDefaultLocalUrl();
  }

  static String _adjustLocalUrl(String url) {
    return adjustUrlForPlatform(url);
  }

  /// Adjusts any URL containing local dev hostnames (10.0.2.2 or localhost)
  /// to use the correct hostname for the current platform.
  /// Use this for image URLs, API URLs, or any other network resources.
  static String adjustUrlForPlatform(String url) {
    if (Platform.isIOS) {
      // iOS simulator uses localhost
      return url.replaceAll('10.0.2.2', 'localhost');
    } else if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 for host machine
      return url.replaceAll('localhost', '10.0.2.2');
    }
    return url;
  }

  static String _getDefaultLocalUrl() {
    final host = Platform.isIOS ? 'localhost' : '10.0.2.2';
    return 'http://$host:4001/api/v1';
  }

  static bool get isDev => dotenv.get('ENV', fallback: 'dev') == 'dev';
}
