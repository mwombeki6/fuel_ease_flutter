import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fuel_ease_flutter/core/routing/app_router.dart';
import 'package:fuel_ease_flutter/shared/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _configureFonts();

  // Set preferred orientations (portrait only for mobile)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: FuelEaseApp(),
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

/// Root application widget
class FuelEaseApp extends ConsumerWidget {
  const FuelEaseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'FuelEase',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
