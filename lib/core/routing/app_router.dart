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

/// Provider for GoRouter instance
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
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
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth routes
      GoRoute(
        path: Routes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Main app routes with bottom navigation
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
            path: Routes.cards,
            builder: (context, state) => const CardsScreen(),
          ),
          GoRoute(
            path: Routes.wallet,
            builder: (context, state) => const WalletScreen(),
          ),
          GoRoute(
            path: Routes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Fuel (direct access, outside shell)
      GoRoute(
        path: Routes.fuel,
        builder: (context, state) => const CreateDispenseScreen(),
      ),

      // Wallet sub-routes (outside shell to avoid bottom nav)
      GoRoute(
        path: Routes.walletRecharge,
        builder: (context, state) => const RechargeScreen(),
      ),
      GoRoute(
        path: Routes.walletTransactions,
        builder: (context, state) => const TransactionHistoryScreen(),
      ),

      // Cards sub-routes (outside shell to avoid bottom nav)
      GoRoute(
        path: Routes.createCard,
        builder: (context, state) => const CreateCardScreen(),
      ),
      GoRoute(
        path: '/cards/pending/:id',
        builder: (context, state) {
          final cardId = state.pathParameters['id']!;
          return CardPendingScreen(cardId: cardId);
        },
      ),
      GoRoute(
        path: '/cards/:id',
        builder: (context, state) {
          final cardId = state.pathParameters['id']!;
          return CardDetailsScreen(cardId: cardId);
        },
      ),

      // Dispense routes (outside shell to avoid bottom nav)
      GoRoute(
        path: Routes.createDispensingRequest,
        builder: (context, state) => CreateDispenseScreen(
          preselectedStationId: state.extra as String?,
        ),
      ),
      GoRoute(
        path: Routes.dispensingRequests,
        builder: (context, state) => const DispenseHistoryScreen(),
      ),
      GoRoute(
        path: '/fuel/requests/:id',
        builder: (context, state) {
          // Detail view — reuse history screen for now (read-only)
          return const DispenseHistoryScreen();
        },
      ),
      GoRoute(
        path: '/fuel/token/:token',
        builder: (context, state) {
          final response = state.extra as CreateDispenseResponse?;
          if (response == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid dispense token')),
            );
          }
          return PinQrScreen(
            requestId: response.request.id,
            pin: response.pin,
            qrPayload: response.qrPayload,
            stationId: response.request.stationId,
            requestedLiters: response.request.requestedLiters,
            pricePerLiterTzs: response.request.pricePerLiterTzs,
          );
        },
      ),

      GoRoute(
        path: '/fuel/live/:requestId',
        builder: (context, state) {
          final params = state.extra as LiveDispenseParams;
          return LiveDispenseScreen(params: params);
        },
      ),
      GoRoute(
        path: '/fuel/complete/:requestId',
        builder: (context, state) {
          final requestId = state.pathParameters['requestId']!;
          return DispenseCompleteScreen(requestId: requestId);
        },
      ),

      // Settings routes
      GoRoute(
        path: Routes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: Routes.changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),

      // Stations list (outside shell)
      GoRoute(
        path: Routes.stations,
        builder: (context, state) => const StationsScreen(),
      ),
      // Station map — must be registered before /stations/:id to avoid conflict
      GoRoute(
        path: Routes.stationMap,
        builder: (context, state) => const StationMapScreen(),
      ),
      GoRoute(
        path: '/stations/:id',
        builder: (context, state) {
          final stationId = state.pathParameters['id']!;
          return StationDetailsScreen(stationId: stationId);
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
