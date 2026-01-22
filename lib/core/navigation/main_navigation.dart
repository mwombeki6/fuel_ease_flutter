import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/core/realtime/realtime_client.dart';
import 'package:fuel_ease_flutter/features/stations/presentation/providers/station_provider.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';

/// Main navigation scaffold with bottom navigation bar
class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.read(realtimeClientProvider).connect(channels: ['public']);
    ref.listen<StationSelectionState>(
      stationSelectionProvider,
      (previous, next) {
        if (previous?.stationId != next.stationId) {
          ref.read(realtimeClientProvider).setStationSubscription(next.stationId);
        }
      },
    );
  }

  @override
  void dispose() {
    ref.read(realtimeClientProvider).disconnect();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(realtimeClientProvider).connect();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      ref.read(realtimeClientProvider).disconnect();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: const _BottomNavBar(),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    if (location.startsWith('/wallet')) {
      return 1;
    } else if (location.startsWith('/fuel')) {
      return 2;
    } else if (location.startsWith('/cards')) {
      return 3;
    } else if (location.startsWith('/profile')) {
      return 4;
    }
    return 0; // home
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go(Routes.home);
            break;
          case 1:
            context.go(Routes.wallet);
            break;
          case 2:
            context.go(Routes.fuel);
            break;
          case 3:
            context.go(Routes.cards);
            break;
          case 4:
            context.go(Routes.profile);
            break;
        }
      },
      backgroundColor: AppColors.surface,
      elevation: 8,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: 'Wallet',
        ),
        NavigationDestination(
          icon: Icon(Icons.local_gas_station_outlined),
          selectedIcon: Icon(Icons.local_gas_station),
          label: 'Fuel',
        ),
        NavigationDestination(
          icon: Icon(Icons.credit_card_outlined),
          selectedIcon: Icon(Icons.credit_card),
          label: 'Cards',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
