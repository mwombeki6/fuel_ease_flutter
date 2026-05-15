import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/core/realtime/realtime_client.dart';
import 'package:fuel_ease_flutter/features/stations/presentation/providers/station_provider.dart';
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
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          widget.child,
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _FeNavBar(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating glass pill navigation bar
// ─────────────────────────────────────────────────────────────────────────────

class _FeNavBar extends StatelessWidget {
  const _FeNavBar();

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/cards')) return 1;
    if (location.startsWith('/wallet')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _navigate(BuildContext context, int index) {
    HapticFeedback.selectionClick();
    switch (index) {
      case 0:
        context.go(Routes.home);
      case 1:
        context.go(Routes.cards);
      case 2:
        context.go(Routes.wallet);
      case 3:
        context.go(Routes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 16),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Glass pill body
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark.withValues(alpha: 0.93),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.07),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _NavItem(
                      icon: Icons.map_rounded,
                      label: 'Home',
                      selected: index == 0,
                      onTap: () => _navigate(context, 0),
                    ),
                    _NavItem(
                      icon: Icons.credit_card_rounded,
                      label: 'Cards',
                      selected: index == 1,
                      onTap: () => _navigate(context, 1),
                    ),
                    // Space for center FAB
                    const SizedBox(width: 64),
                    _NavItem(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Wallet',
                      selected: index == 2,
                      onTap: () => _navigate(context, 2),
                    ),
                    _NavItem(
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      selected: index == 3,
                      onTap: () => _navigate(context, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Center Fuel Up button — floats above the pill
          Positioned(
            top: -20,
            child: _CenterFuelButton(
              onTap: () {
                HapticFeedback.mediumImpact();
                context.push(Routes.createDispensingRequest);
              },
            ),
          ),
        ],
      ),
    )
        .animate()
        .slideY(
          begin: 2,
          end: 0,
          duration: 600.ms,
          delay: 200.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(delay: 200.ms, duration: 400.ms);
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.brand.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: selected
                    ? AppColors.brand
                    : Colors.white.withValues(alpha: 0.38),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected
                    ? AppColors.brand
                    : Colors.white.withValues(alpha: 0.35),
                letterSpacing: 0.2,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterFuelButton extends StatelessWidget {
  const _CenterFuelButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandGlow,
              blurRadius: 24,
              spreadRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.local_gas_station_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.06, 1.06),
          duration: 1800.ms,
          curve: Curves.easeInOut,
        );
  }
}
