import 'package:flutter/material.dart';

enum Environment { dev, stg, prod }

class AppConfig {
  final Environment environment;
  final String baseUrl;
  final String googleServerClientId;
  final String appleServiceId;
  final String firebaseAuthDomain;
  final Color? bannerColor;

  const AppConfig._({
    required this.environment,
    required this.baseUrl,
    required this.googleServerClientId,
    required this.appleServiceId,
    required this.firebaseAuthDomain,
    this.bannerColor,
  });

  static const dev = AppConfig._(
    environment: Environment.dev,
    // AWS dev environment
    baseUrl: 'http://pairing-planet-dev-alb-857509432.us-east-2.elb.amazonaws.com/api/v1',
    googleServerClientId:
        '823521388124-786gfugmb3pr2bo002bj9ggn5vju13om.apps.googleusercontent.com',
    appleServiceId: 'com.pairingplanet.firebase.dev',
    firebaseAuthDomain: 'pairing-planet-dev-5905e.firebaseapp.com',
    bannerColor: Colors.red,
  );

  static const stg = AppConfig._(
    environment: Environment.stg,
    baseUrl: 'https://api-stg.pairingplanet.com/api/v1',
    googleServerClientId:
        '590920576402-8toin0rabt6dr3jnrd2js38ghjt0dkhp.apps.googleusercontent.com',
    appleServiceId: 'com.pairingplanet.firebase.stg', // TODO: Update with actual stg Service ID
    firebaseAuthDomain: 'pairing-planet-stg.firebaseapp.com', // TODO: Verify domain
    bannerColor: Colors.orange,
  );

  static const prod = AppConfig._(
    environment: Environment.prod,
    baseUrl: 'https://api.pairingplanet.com/api/v1',
    googleServerClientId:
        '1003324647842-ejls9iuosh7vv94mstc4lhafh3a218mp.apps.googleusercontent.com',
    appleServiceId: 'com.pairingplanet.firebase.prod', // TODO: Update with actual prod Service ID
    firebaseAuthDomain: 'pairing-planet-prod.firebaseapp.com', // TODO: Verify domain
    bannerColor: null, // No banner for production
  );

  static late AppConfig current;

  bool get isDev => environment == Environment.dev;
  bool get isStg => environment == Environment.stg;
  bool get isProd => environment == Environment.prod;

  String get environmentName {
    switch (environment) {
      case Environment.dev:
        return 'Development';
      case Environment.stg:
        return 'Staging';
      case Environment.prod:
        return 'Production';
    }
  }
}
