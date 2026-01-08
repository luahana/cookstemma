import 'config/app_config.dart';
import 'main_common.dart';
// TODO: Generate this file using FlutterFire CLI:
// flutterfire configure --project=pairing-planet-stg \
//   --out=lib/firebase_options_stg.dart \
//   --android-package-name=com.pairingplanet.pairingplanetfrontend.stg \
//   --ios-bundle-id=com.pairingplanet.pairingplanetfrontend.stg
import 'firebase_options_stg.dart';

void main() {
  mainCommon(AppConfig.stg, DefaultFirebaseOptions.currentPlatform);
}
