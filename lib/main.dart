import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fuel_ease_flutter/core/routing/app_router.dart';
import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/firebase_options.dart';
import 'package:fuel_ease_flutter/shared/theme/app_theme.dart';

/// Persisted theme mode. Reads from SharedPreferences on start.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// Top-level FCM background handler — must be a top-level function.
/// The app is not running in this context; don't touch UI or providers.
@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register background handler before any other Firebase calls.
  FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);

  // Request notification permission (iOS; Android 13+ also shows a dialog).
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Show foreground notifications as heads-up on iOS.
  await FirebaseMessaging.instance
      .setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  await _configureFonts();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('fe_theme');
  final initialThemeMode = switch (savedTheme) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith((ref) => initialThemeMode),
      ],
      child: const FuelEaseApp(),
    ),
  );
}

Future<void> _configureFonts() async {
  try {
    await rootBundle.load('assets/fonts/Sora-Regular.ttf');
    GoogleFonts.config.allowRuntimeFetching = false;
  } catch (_) {
    GoogleFonts.config.allowRuntimeFetching = true;
  }
}

class FuelEaseApp extends ConsumerStatefulWidget {
  const FuelEaseApp({super.key});

  @override
  ConsumerState<FuelEaseApp> createState() => _FuelEaseAppState();
}

class _FuelEaseAppState extends ConsumerState<FuelEaseApp> {
  @override
  void initState() {
    super.initState();
    _setupNotificationHandlers();
  }

  void _setupNotificationHandlers() {
    if (Firebase.apps.isEmpty) return;

    // App opened from terminated state via notification tap
    FirebaseMessaging.instance.getInitialMessage().then(_handleNotificationTap);

    // App in background, user taps notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // App in foreground — show a snackbar for non-dispense notifications
    FirebaseMessaging.onMessage.listen((message) {
      final ctx = navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      final title = message.notification?.title;
      final body = message.notification?.body;
      if (title == null && body == null) return;

      // Route to dispense screen directly for dispense events
      final type = message.data['type'] as String?;
      if (type == 'dispense_update') {
        _handleNotificationTap(message);
        return;
      }

      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              if (body != null) Text(body),
            ],
          ),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _handleNotificationTap(RemoteMessage? message) {
    if (message == null) return;
    final router = ref.read(appRouterProvider);
    final type = message.data['type'] as String?;
    final id = message.data['id'] as String?;

    switch (type) {
      case 'dispense_update':
        if (id != null) router.push(Routes.dispensingToken(id));
      case 'card_ready':
        if (id != null) router.push(Routes.cardDetails(id));
      case 'wallet_topup':
        router.push(Routes.wallet);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'FuelEase',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}