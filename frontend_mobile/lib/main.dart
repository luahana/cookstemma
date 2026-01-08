import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:isar/isar.dart';
import 'package:pairing_planet2_frontend/core/providers/isar_provider.dart';
import 'package:pairing_planet2_frontend/core/providers/locale_provider.dart';
import 'package:pairing_planet2_frontend/core/router/app_router.dart';
import 'package:pairing_planet2_frontend/core/services/toast_service.dart';
import 'package:pairing_planet2_frontend/core/theme/app_theme.dart';
import 'package:pairing_planet2_frontend/core/utils/logger.dart';
import 'package:pairing_planet2_frontend/core/workers/event_sync_manager.dart';
import 'package:pairing_planet2_frontend/firebase_options.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:pairing_planet2_frontend/core/services/fcm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // 1. 초기화 작업
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up FCM background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await GoogleSignIn.instance.initialize(
    serverClientId:
        "223256199574-lv408agbeo87e21ucvmfj0qlg836jqet.apps.googleusercontent.com",
  );

  // 2. Flutter 프레임워크 내 에러 캡처
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  // 3. 비동기 에러(나머지 에러) 캡처
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform,
  );

  await EasyLocalization.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();
  await Hive.openBox('recipe_box');
  await Hive.openBox('profile_cache_box');
  await Hive.openBox('search_history_box');

  // Initialize Isar database for event tracking
  final isar = await initializeIsar();
  talker.info('Isar database initialized');

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
/// This is needed because Phoenix.rebirth() doesn't re-run main(), so we need
/// to apply the locale from SharedPreferences after the widget tree rebuilds.
class LocaleApplier extends StatefulWidget {
  final Isar isar;

  const LocaleApplier({super.key, required this.isar});

  @override
  State<LocaleApplier> createState() => _LocaleApplierState();
}

class _LocaleApplierState extends State<LocaleApplier> {
  bool _localeApplied = false;

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
          // Use addPostFrameCallback to ensure EasyLocalization context is ready
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && context.locale != locale) {
              context.setLocale(locale);
            }
          });
        }
      }
    }

    if (mounted) {
      setState(() {
        _localeApplied = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        // Override Isar provider with initialized instance
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentLocale = context.locale;
      final formatted =
          "${currentLocale.languageCode}-${currentLocale.countryCode}";
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
          debugShowCheckedModeBanner: false,

          // 💡 다국어 처리를 위한 MaterialApp 설정 (context에서 주입)
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,

          theme: AppTheme.lightTheme,
          routerConfig: router,
        );
      },
    );
  }
}
