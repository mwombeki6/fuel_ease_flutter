import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/core/realtime/realtime_client.dart';
import 'package:fuel_ease_flutter/features/stations/presentation/providers/station_provider.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({required this.child, super.key});

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
    ref.listen<StationSelectionState>(
      stationSelectionProvider,
      (previous, next) {
        if (previous?.stationId != next.stationId) {
          ref.read(realtimeClientProvider).setStationSubscription(next.stationId);
        }
      },
    );

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: const _BottomNavBar(),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/map')) return 1;
    if (location.startsWith('/cards')) return 2;
    if (location.startsWith('/wallet')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    final cs = Theme.of(context).colorScheme;
    final navBg = Theme.of(context).navigationBarTheme.backgroundColor ??
        Theme.of(context).colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: navBg,
        border: Border(
          top: BorderSide(color: cs.outline.withValues(alpha: 0.4), width: 1),
        ),
      ),
      child: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go(Routes.home);
            case 1:
              context.go(Routes.map);
            case 2:
              context.go(Routes.cards);
            case 3:
              context.go(Routes.wallet);
            case 4:
              context.go(Routes.profile);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.credit_card_outlined),
            selectedIcon: Icon(Icons.credit_card_rounded),
            label: 'Cards',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
