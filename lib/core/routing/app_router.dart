import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fuel_ease_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fuel_ease_flutter/core/routing/routes.dart';

// Import screens
import 'package:fuel_ease_flutter/features/cards/presentation/screens/card_pending_screen.dart';
import 'package:fuel_ease_flutter/features/dispense/data/models/create_dispense_response.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/providers/live_dispense_provider.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/screens/create_dispense_screen.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/screens/dispense_complete_screen.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/screens/dispense_history_screen.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/screens/live_dispense_screen.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/screens/pin_qr_screen.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/screens/scan_qr_screen.dart';
import 'package:fuel_ease_flutter/features/auth/presentation/screens/splash_screen.dart';
import 'package:fuel_ease_flutter/features/auth/presentation/screens/welcome_screen.dart';
import 'package:fuel_ease_flutter/features/auth/presentation/screens/login_screen.dart';
import 'package:fuel_ease_flutter/features/auth/presentation/screens/register_screen.dart';
import 'package:fuel_ease_flutter/features/dashboard/presentation/screens/home_screen.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/screens/recharge_screen.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/screens/transaction_history_screen.dart';
import 'package:fuel_ease_flutter/features/cards/presentation/screens/cards_screen.dart';
import 'package:fuel_ease_flutter/features/cards/presentation/screens/card_details_screen.dart';
import 'package:fuel_ease_flutter/features/cards/presentation/screens/create_card_screen.dart';
import 'package:fuel_ease_flutter/features/stations/presentation/screens/stations_screen.dart';
import 'package:fuel_ease_flutter/features/stations/presentation/screens/station_details_screen.dart';
import 'package:fuel_ease_flutter/features/stations/presentation/screens/station_map_screen.dart';
import 'package:fuel_ease_flutter/features/profile/presentation/screens/change_password_screen.dart';
import 'package:fuel_ease_flutter/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:fuel_ease_flutter/features/profile/presentation/screens/profile_screen.dart';
import 'package:fuel_ease_flutter/core/navigation/main_navigation.dart';

/// Global navigator key — allows navigation from outside a widget context
/// (e.g., FCM notification tap handlers).
final navigatorKey = GlobalKey<NavigatorState>();

/// Smooth fade + subtle upward slide — replaces the default hard-cut on push.
Page<T> _slideFade<T>(GoRouterState state, Widget child) =>
    CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (context, animation, secondary, child) {
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );

/// Provider for GoRouter instance
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: Routes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isAuthenticated = authState.maybeWhen(
        authenticated: (_) => true,
        orElse: () => false,
      );

      final isLoading = authState.maybeWhen(
        loading: () => true,
        initial: () => true,
        orElse: () => false,
      );

      final isGoingToAuth = state.matchedLocation.startsWith('/welcome') ||
          state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register');

      // Only redirect to splash during initial app load — auth screens (login/register)
      // manage their own loading spinners and must not be displaced mid-submission.
      if (isLoading && !isGoingToAuth && state.matchedLocation != Routes.splash) {
        return Routes.splash;
      }

      // Loading finished but still on splash — decide based on auth
      if (!isLoading && state.matchedLocation == Routes.splash) {
        return isAuthenticated ? Routes.home : Routes.welcome;
      }

      // If not authenticated and not going to auth, redirect to welcome
      if (!isAuthenticated && !isLoading && !isGoingToAuth) {
        return Routes.welcome;
      }

      // If authenticated and going to auth, redirect to home
      if (isAuthenticated && isGoingToAuth) {
        return Routes.home;
      }

      // No redirect needed
      return null;
    },
    routes: [
      // Splash screen
      GoRoute(
        path: Routes.splash,
        pageBuilder: (context, state) => _slideFade(state, const SplashScreen()),
      ),

      // Auth routes
      GoRoute(
        path: Routes.welcome,
        pageBuilder: (context, state) => _slideFade(state, const WelcomeScreen()),
      ),
      GoRoute(
        path: Routes.login,
        pageBuilder: (context, state) => _slideFade(state, const LoginScreen()),
      ),
      GoRoute(
        path: Routes.register,
        pageBuilder: (context, state) => _slideFade(state, const RegisterScreen()),
      ),

      // Main app routes with bottom navigation
      // Shell tabs: Home, Stations, Activity (wallet transactions), Cards.
      // Wallet and Profile are standalone push destinations (see below), not
      // shell tabs — per Task 8's 4-tab nav bar.
      ShellRoute(
        builder: (context, state, child) => MainNavigation(child: child),
        routes: [
          GoRoute(
            path: Routes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: Routes.map,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: Routes.stations,
            builder: (context, state) => const StationsScreen(),
          ),
          GoRoute(
            path: Routes.walletTransactions,
            builder: (context, state) => const TransactionHistoryScreen(),
          ),
          GoRoute(
            path: Routes.cards,
            builder: (context, state) => const CardsScreen(),
          ),
        ],
      ),

      // Fuel (direct access, outside shell)
      GoRoute(
        path: Routes.fuel,
        pageBuilder: (context, state) =>
            _slideFade(state, const CreateDispenseScreen()),
      ),

      // Wallet routes (standalone — Wallet is a push destination, not a
      // shell tab; walletTransactions/"Activity" lives in the shell above)
      GoRoute(
        path: Routes.wallet,
        pageBuilder: (context, state) =>
            _slideFade(state, const WalletScreen()),
      ),
      GoRoute(
        path: Routes.walletRecharge,
        pageBuilder: (context, state) =>
            _slideFade(state, const RechargeScreen()),
      ),

      // Cards sub-routes
      GoRoute(
        path: Routes.createCard,
        pageBuilder: (context, state) =>
            _slideFade(state, const CreateCardScreen()),
      ),
      GoRoute(
        path: '/cards/pending/:id',
        pageBuilder: (context, state) {
          final cardId = state.pathParameters['id']!;
          return _slideFade(state, CardPendingScreen(cardId: cardId));
        },
      ),
      GoRoute(
        path: '/cards/:id',
        pageBuilder: (context, state) {
          final cardId = state.pathParameters['id']!;
          return _slideFade(state, CardDetailsScreen(cardId: cardId));
        },
      ),

      // Dispense routes
      GoRoute(
        path: Routes.createDispensingRequest,
        pageBuilder: (context, state) => _slideFade(
          state,
          CreateDispenseScreen(preselectedStationId: state.extra as String?),
        ),
      ),
      GoRoute(
        path: Routes.scanQR,
        pageBuilder: (context, state) =>
            _slideFade(state, const ScanQrScreen()),
      ),
      GoRoute(
        path: Routes.dispensingRequests,
        pageBuilder: (context, state) =>
            _slideFade(state, const DispenseHistoryScreen()),
      ),
      GoRoute(
        path: '/fuel/requests/:id',
        pageBuilder: (context, state) =>
            _slideFade(state, const DispenseHistoryScreen()),
      ),
      GoRoute(
        path: '/fuel/token/:token',
        pageBuilder: (context, state) {
          final response = state.extra as CreateDispenseResponse?;
          if (response == null) {
            return _slideFade(
              state,
              const Scaffold(
                  body: Center(child: Text('Invalid dispense token'))),
            );
          }
          return _slideFade(
            state,
            PinQrScreen(
              requestId: response.request.id,
              pin: response.pin,
              qrPayload: response.qrPayload,
              stationId: response.request.stationId,
              requestedLiters: response.request.requestedLiters,
              pricePerLiterTzs: response.request.pricePerLiterTzs,
            ),
          );
        },
      ),
      GoRoute(
        path: '/fuel/live/:requestId',
        pageBuilder: (context, state) {
          final params = state.extra as LiveDispenseParams;
          return _slideFade(state, LiveDispenseScreen(params: params));
        },
      ),
      GoRoute(
        path: '/fuel/complete/:requestId',
        pageBuilder: (context, state) {
          final requestId = state.pathParameters['requestId']!;
          return _slideFade(
              state, DispenseCompleteScreen(requestId: requestId));
        },
      ),

      // Profile (standalone — push destination, not a shell tab)
      GoRoute(
        path: Routes.profile,
        pageBuilder: (context, state) =>
            _slideFade(state, const ProfileScreen()),
      ),

      // Settings routes
      GoRoute(
        path: Routes.editProfile,
        pageBuilder: (context, state) =>
            _slideFade(state, const EditProfileScreen()),
      ),
      GoRoute(
        path: Routes.changePassword,
        pageBuilder: (context, state) =>
            _slideFade(state, const ChangePasswordScreen()),
      ),

      // Stations sub-routes (Routes.stations itself lives in the shell above)
      GoRoute(
        path: Routes.stationMap,
        pageBuilder: (context, state) =>
            _slideFade(state, const StationMapScreen()),
      ),
      GoRoute(
        path: '/stations/:id',
        pageBuilder: (context, state) {
          final stationId = state.pathParameters['id']!;
          return _slideFade(state, StationDetailsScreen(stationId: stationId));
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
});
