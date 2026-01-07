import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get baseUrl =>
      dotenv.get('BASE_URL', fallback: 'http://10.0.2.2:4001/api/v1');
  static bool get isDev => dotenv.get('ENV', fallback: 'dev') == 'dev';
}
