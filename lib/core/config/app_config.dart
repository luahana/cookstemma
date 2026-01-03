import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get baseUrl =>
      dotenv.get('BASE_URL', fallback: 'https://fallback.api.com');
  static String get apiKey => dotenv.get('API_KEY', fallback: '');
  static bool get isDev => dotenv.get('ENV', fallback: 'dev') == 'dev';
}
