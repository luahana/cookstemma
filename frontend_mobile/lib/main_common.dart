import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:isar/isar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';

import 'package:pairing_planet2_frontend/config/app_config.dart';
import 'package:pairing_planet2_frontend/core/providers/isar_provider.dart';
import 'package:pairing_planet2_frontend/core/providers/locale_provider.dart';
import 'package:pairing_planet2_frontend/core/router/app_router.dart';
import 'package:pairing_planet2_frontend/core/services/fcm_service.dart';
import 'package:pairing_planet2_frontend/core/services/toast_service.dart';
import 'package:pairing_planet2_frontend/core/theme/app_theme.dart';
import 'package:pairing_planet2_frontend/core/utils/logger.dart';
import 'package:pairing_planet2_frontend/core/workers/event_sync_manager.dart';

Future<void> mainCommon(AppConfig config, FirebaseOptions firebaseOptions) async {
  // Store config for global access
  AppConfig.current = config;

  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with environment-specific options
  await Firebase.initializeApp(options: firebaseOptions);

  // Set up FCM background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Google Sign-In with environment-specific client ID
  await GoogleSignIn.instance.initialize(
    serverClientId: config.googleServerClientId,
  );

  // Set up Crashlytics error handling
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Disable Crashlytics in debug mode
  if (kDebugMode) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  }

  // Initialize other services
  await EasyLocalization.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();
  await Hive.openBox('recipe_box');
  await Hive.openBox('profile_cache_box');
  await Hive.openBox('search_history_box');

  // Initialize Isar database for event tracking
  final isar = await initializeIsar();
  talker.info('Isar database initialized');
  talker.info('Environment: ${config.environmentName}');

  // Isar Inspector is only available in debug mode
  if (kDebugMode) {
    talker.info('Isar Inspector: Check console for URL (https://inspect.isar.dev/...)');
  }

  runApp(
    Phoenix(
      child: EasyLocalization(
        supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
        path: 'assets/translations',
        fallbackLocale: const Locale('ko', 'KR'),
        child: LocaleApplier(isar: isar),
      ),
    ),
  );
}

/// Widget that applies the saved locale after EasyLocalization is ready.
class LocaleApplier extends StatefulWidget {
  final Isar isar;

  const LocaleApplier({super.key, required this.isar});

  @override
  State<LocaleApplier> createState() => _LocaleApplierState();
}

class _LocaleApplierState extends State<LocaleApplier> {
  @override
  void initState() {
    super.initState();
    _applyLocaleFromPrefs();
  }

  Future<void> _applyLocaleFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString('app_locale');

    if (savedLocale != null && mounted) {
      final parts = savedLocale.split('-');
      if (parts.length == 2) {
        final locale = Locale(parts[0], parts[1]);
        final currentLocale = context.locale;

        if (currentLocale != locale) {
          talker.info('LocaleApplier: Changing locale from $currentLocale to $locale');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && context.locale != locale) {
              context.setLocale(locale);
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(widget.isar),
      ],
      observers: [
        TalkerRiverpodObserver(
          talker: talker,
          settings: const TalkerRiverpodLoggerSettings(
            printProviderAdded: true,
            printProviderUpdated: true,
            printProviderFailed: true,
          ),
        ),
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize event sync manager
    EventSyncManager.initialize(ref);
    EventSyncManager.startPeriodicSync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    EventSyncManager.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        EventSyncManager.onAppResume();
        break;
      case AppLifecycleState.paused:
        EventSyncManager.onAppPause();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final config = AppConfig.current;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentLocale = context.locale;
      final formatted = "${currentLocale.languageCode}-${currentLocale.countryCode}";
      ref.read(localeProvider.notifier).state = formatted;
    });

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Pairing Planet',
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          debugShowCheckedModeBanner: !config.isProd,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: AppTheme.lightTheme,
          routerConfig: router,
          builder: (context, child) {
            // Add environment banner for non-production
            if (config.bannerColor != null) {
              return Banner(
                message: config.environmentName,
                location: BannerLocation.topEnd,
                color: config.bannerColor!,
                child: child ?? const SizedBox.shrink(),
              );
            }
            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}
