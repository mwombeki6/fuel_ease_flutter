import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';

/// Welcome/Onboarding screen
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // App Logo/Icon
              const Icon(
                Icons.local_gas_station,
                size: 100,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              // App Name
              const Text(
                'FuelEase',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              // Tagline
              Text(
                'Your digital fuel card solution',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              // Login Button
              FilledButton(
                onPressed: () => context.push(Routes.login),
                child: const Text('Login'),
              ),
              const SizedBox(height: 16),
              // Register Button
              OutlinedButton(
                onPressed: () => context.push(Routes.register),
                child: const Text('Create Account'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
