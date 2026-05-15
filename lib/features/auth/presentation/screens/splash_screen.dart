import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.nightGradient),
        child: Stack(
          children: [
            // Ambient radial glow
            Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [AppColors.brandGlow, Colors.transparent],
                    stops: [0.0, 1.0],
                  ),
                ),
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.3, 0.3),
                  end: const Offset(1.2, 1.2),
                  duration: 1200.ms,
                  curve: Curves.easeOut,
                )
                .fadeIn(duration: 800.ms),

            // Main logo + title
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo mark
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandGlow,
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.local_gas_station_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.4, 0.4),
                        end: const Offset(1.0, 1.0),
                        duration: 700.ms,
                        curve: Curves.easeOutBack,
                      )
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 28),

                  const Text(
                    'FuelEase',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 350.ms, duration: 400.ms)
                      .slideY(
                        begin: 0.4,
                        end: 0,
                        delay: 350.ms,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic,
                      ),

                  const SizedBox(height: 8),

                  Text(
                    'Smart fueling, simplified',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 0.5,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 550.ms, duration: 400.ms),
                ],
              ),
            ),

            // Bottom progress shimmer
            Positioned(
              bottom: 56,
              left: 48,
              right: 48,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.brand),
                      minHeight: 2,
                    ),
                  ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
                  const SizedBox(height: 16),
                  Text(
                    'Loading…',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.3),
                      letterSpacing: 1.0,
                    ),
                  ).animate().fadeIn(delay: 900.ms, duration: 300.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
