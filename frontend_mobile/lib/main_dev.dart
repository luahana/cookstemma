import 'config/app_config.dart';
import 'main_common.dart';
// TODO: Generate this file using FlutterFire CLI:
// flutterfire configure --project=pairing-planet-dev \
//   --out=lib/firebase_options_dev.dart \
//   --android-package-name=com.pairingplanet.pairingplanetfrontend.dev \
//   --ios-bundle-id=com.pairingplanet.pairingplanetfrontend.dev
import 'firebase_options_dev.dart';

void main() {
  mainCommon(AppConfig.dev, DefaultFirebaseOptions.currentPlatform);
}
