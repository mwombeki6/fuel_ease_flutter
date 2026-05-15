import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fuel_ease_flutter/features/auth/presentation/providers/auth_state.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';
import 'package:fuel_ease_flutter/shared/widgets/fe_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    setState(() => _errorMessage = null);
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (_, next) {
      next.maybeWhen(
        error: (message) => setState(() => _errorMessage = message),
        orElse: () {},
      );
    });

    final isLoading = authState.maybeWhen(loading: () => true, orElse: () => false);

    return Scaffold(
      backgroundColor: AppColors.midnight,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(decoration: BoxDecoration(gradient: AppColors.nightGradient)),
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 0.7,
                  colors: [AppColors.brandGlow, Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back button row
                  Row(
                    children: [
                      _GlassBackButton(onTap: () => context.pop()),
                    ],
                  ),

                  const SizedBox(height: 36),

                  Text(
                    'Welcome back',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                  )
                      .animate()
                      .slideY(begin: 0.3, end: 0, duration: 500.ms, curve: Curves.easeOutCubic)
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 8),

                  Text(
                    'Sign in to continue fueling',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 15,
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

                  const SizedBox(height: 36),

                  // Form card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.07),
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Error banner
                              AnimatedSize(
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeOutCubic,
                                child: _errorMessage != null
                                    ? _ErrorBanner(
                                        message: _errorMessage!,
                                        onDismiss: () => setState(() => _errorMessage = null),
                                      )
                                    : const SizedBox.shrink(),
                              ),

                              _DarkTextField(
                                controller: _emailController,
                                label: 'Email address',
                                hint: 'you@example.com',
                                icon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                enabled: !isLoading,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Please enter your email';
                                  if (!v.contains('@')) return 'Enter a valid email';
                                  return null;
                                },
                              ),

                              const SizedBox(height: 14),

                              _DarkTextField(
                                controller: _passwordController,
                                label: 'Password',
                                icon: Icons.lock_outline_rounded,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                enabled: !isLoading,
                                onFieldSubmitted: (_) => _handleLogin(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: Colors.white.withValues(alpha: 0.4),
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Please enter your password';
                                  if (v.length < 8) return 'Minimum 8 characters';
                                  return null;
                                },
                              ),

                              const SizedBox(height: 24),

                              GradientButton(
                                onPressed: isLoading ? null : _handleLogin,
                                label: 'Sign In',
                                isLoading: isLoading,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .slideY(begin: 0.3, end: 0, duration: 500.ms, delay: 200.ms, curve: Curves.easeOutCubic)
                      .fadeIn(duration: 400.ms, delay: 200.ms),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: isLoading ? null : () => context.push(Routes.register),
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            color: AppColors.brand,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared dark-themed widgets ──────────────────────────────────────────────

class _GlassBackButton extends StatelessWidget {
  const _GlassBackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 17, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded,
                size: 16, color: AppColors.error.withValues(alpha: 0.7)),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _DarkTextField extends StatelessWidget {
  const _DarkTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.45),
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.25),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.7)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
