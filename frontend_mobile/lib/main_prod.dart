import 'config/app_config.dart';
import 'main_common.dart';
// TODO: Generate this file using FlutterFire CLI:
// flutterfire configure --project=pairing-planet-prod \
//   --out=lib/firebase_options_prod.dart \
//   --android-package-name=com.pairingplanet.pairingplanetfrontend \
//   --ios-bundle-id=com.pairingplanet.pairingplanetfrontend
import 'firebase_options_prod.dart';

void main() {
  mainCommon(AppConfig.prod, DefaultFirebaseOptions.currentPlatform);
}
