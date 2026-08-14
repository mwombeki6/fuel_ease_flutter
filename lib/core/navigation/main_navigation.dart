import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fuel_ease_flutter/core/network/connectivity_provider.dart';
import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/core/realtime/realtime_client.dart';
import 'package:fuel_ease_flutter/features/stations/presentation/providers/station_provider.dart';
import 'package:fuel_ease_flutter/shared/widgets/glassmorphism.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';

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

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(Routes.stations)) return 1;
    if (location.startsWith(Routes.walletTransactions)) return 3;
    if (location.startsWith(Routes.cards)) return 4;
    return 0;
  }

  void _handleTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        HapticFeedback.selectionClick();
        context.go(Routes.home);
      case 1:
        HapticFeedback.selectionClick();
        context.go(Routes.stations);
      case 2:
        HapticFeedback.mediumImpact();
        context.push(Routes.createDispensingRequest);
      case 3:
        HapticFeedback.selectionClick();
        context.go(Routes.walletTransactions);
      case 4:
        HapticFeedback.selectionClick();
        context.go(Routes.cards);
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

    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          widget.child,
          // Offline banner
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            top: isOnline ? -56 : MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: const _OfflineBanner(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _FeNavBar(
              currentIndex: _currentIndex(context),
              onTap: (index) => _handleTap(context, index),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Offline banner
// ─────────────────────────────────────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.warning.withValues(alpha: 0.96) : AppColors.warning,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.white, size: 15),
          SizedBox(width: 8),
          Text(
            'No internet connection',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modern Glass Navigation Bar
// ─────────────────────────────────────────────────────────────────────────────

class _FeNavBar extends StatelessWidget {
  const _FeNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex; // 0=Home,1=Stations,2=Pay,3=Activity,4=Cards
  final void Function(int index) onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: 8 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Glassmorphism.glassNavBar(
        height: 72,
        margin: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: 8 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            active: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.location_on_rounded,
            label: 'Stations',
            active: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _PayNavItem(onTap: () => onTap(2)),
          _NavItem(
            icon: Icons.schedule_rounded,
            label: 'Activity',
            active: currentIndex == 3,
            onTap: () => onTap(3),
          ),
          _NavItem(
            icon: Icons.credit_card_rounded,
            label: 'Cards',
            active: currentIndex == 4,
            onTap: () => onTap(4),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = active
        ? colorScheme.primary
        : colorScheme.onSurface.withValues(alpha: 0.6);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          decoration: active
              ? BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayNavItem extends StatelessWidget {
  const _PayNavItem({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: isDark
                      ? AppColors.brandGradientDark
                      : AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: const Icon(Icons.flash_on_rounded,
                    size: 16, color: Colors.white),
              ),
              const SizedBox(height: 3),
              Text(
                'Pay',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}