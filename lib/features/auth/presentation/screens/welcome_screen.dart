import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';
import 'package:fuel_ease_flutter/shared/widgets/fe_widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Night gradient background
          Container(
            color: colorScheme.surface,
          ),

          // Ambient brand glow top-center
          Positioned(
            top: -80,
            left: 0,
            right: 0,
            child: Container(
              height: 480,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 0.75,
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Bottom glow
          Positioned(
            bottom: -60,
            left: 0,
            right: 0,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.bottomCenter,
                  radius: 0.8,
                  colors: [
                    colorScheme.secondary.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),

                  // Animated logo
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.25),
                            blurRadius: 40,
                            spreadRadius: 6,
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
                          duration: 750.ms,
                          curve: Curves.easeOutBack,
                        )
                        .fadeIn(duration: 500.ms),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'FuelEase',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                  )
                      .animate()
                      .slideY(
                        begin: 0.4,
                        end: 0,
                        duration: 600.ms,
                        delay: 200.ms,
                        curve: Curves.easeOutCubic,
                      )
                      .fadeIn(duration: 500.ms, delay: 200.ms),

                  const SizedBox(height: 10),

                  Text(
                    'Your fuel, always on time.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.45),
                          letterSpacing: 0.2,
                        ),
                  ).animate().fadeIn(duration: 500.ms, delay: 450.ms),

                  const Spacer(flex: 3),

                  GradientButton(
                    onPressed: () => context.push(Routes.login),
                    label: 'Sign In',
                  )
                      .animate()
                      .slideY(
                        begin: 0.5,
                        end: 0,
                        duration: 500.ms,
                        delay: 600.ms,
                        curve: Curves.easeOutCubic,
                      )
                      .fadeIn(duration: 400.ms, delay: 600.ms),

                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: () => context.push(Routes.register),
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        'Create Account',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .slideY(
                        begin: 0.5,
                        end: 0,
                        duration: 500.ms,
                        delay: 700.ms,
                        curve: Curves.easeOutCubic,
                      )
                      .fadeIn(duration: 400.ms, delay: 700.ms),

                  const SizedBox(height: 28),

                  Text(
                    'FuelEase · v1.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 900.ms),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
