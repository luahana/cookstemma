// Default entry point - uses dev environment
// For specific environments, use:
//   flutter run --flavor dev -t lib/main_dev.dart
//   flutter run --flavor stg -t lib/main_stg.dart
//   flutter run --flavor prod -t lib/main_prod.dart

import 'config/app_config.dart';
import 'firebase_options_dev.dart';
import 'main_common.dart';

void main() {
  mainCommon(AppConfig.dev, DefaultFirebaseOptions.currentPlatform);
}
