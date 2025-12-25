import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fuel_ease_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fuel_ease_flutter/core/routing/routes.dart';

// Import screens
import 'package:fuel_ease_flutter/features/auth/presentation/screens/splash_screen.dart';
import 'package:fuel_ease_flutter/features/auth/presentation/screens/welcome_screen.dart';
import 'package:fuel_ease_flutter/features/auth/presentation/screens/login_screen.dart';
import 'package:fuel_ease_flutter/features/dashboard/presentation/screens/home_screen.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/screens/recharge_screen.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/screens/transaction_history_screen.dart';
import 'package:fuel_ease_flutter/features/cards/presentation/screens/cards_screen.dart';
import 'package:fuel_ease_flutter/features/cards/presentation/screens/card_details_screen.dart';
import 'package:fuel_ease_flutter/features/cards/presentation/screens/create_card_screen.dart';
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

      // Show splash while loading auth state
      if (isLoading && state.matchedLocation != Routes.splash) {
        return Routes.splash;
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
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Register Screen - Coming Soon')),
        ),
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
            path: Routes.wallet,
            builder: (context, state) => const WalletScreen(),
          ),
          GoRoute(
            path: Routes.fuel,
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Fuel Screen - Coming Soon')),
            ),
          ),
          GoRoute(
            path: Routes.cards,
            builder: (context, state) => const CardsScreen(),
          ),
          GoRoute(
            path: Routes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
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
        path: '/cards/:id',
        builder: (context, state) {
          final cardId = state.pathParameters['id']!;
          return CardDetailsScreen(cardId: cardId);
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
