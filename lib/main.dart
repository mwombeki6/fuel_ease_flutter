import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fuel_ease_flutter/core/routing/app_router.dart';
import 'package:fuel_ease_flutter/shared/theme/app_theme.dart';

/// Persisted theme mode. Reads from SharedPreferences on start.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _configureFonts();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
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

class FuelEaseApp extends ConsumerWidget {
  const FuelEaseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
