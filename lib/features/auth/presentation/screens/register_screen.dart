import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/features/auth/data/models/register_payload.dart';
import 'package:fuel_ease_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fuel_ease_flutter/features/auth/presentation/providers/auth_state.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';
import 'package:fuel_ease_flutter/shared/widgets/fe_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  int _step = 0;

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_formKey1.currentState?.validate() ?? false) {
      setState(() => _step = 1);
    }
  }

  void _handleRegister() {
    setState(() => _errorMessage = null);
    if (!(_formKey2.currentState?.validate() ?? false)) return;

    ref.read(authProvider.notifier).register(
          RegisterPayload(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            phoneNumber: _phoneController.text.trim(),
          ),
        );
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
            top: -80,
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
                  // Back navigation row
                  Row(
                    children: [
                      _GlassBackButton(
                        onTap: () {
                          if (_step == 1) {
                            setState(() {
                              _step = 0;
                              _errorMessage = null;
                            });
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _GradientStepIndicator(
                          currentStep: _step,
                          totalSteps: 2,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Form glass card
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
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.08, 0),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: _step == 0
                              ? _Step1(
                                  key: const ValueKey(0),
                                  formKey: _formKey1,
                                  firstNameController: _firstNameController,
                                  lastNameController: _lastNameController,
                                  isLoading: isLoading,
                                  onNext: _nextStep,
                                )
                              : _Step2(
                                  key: const ValueKey(1),
                                  formKey: _formKey2,
                                  emailController: _emailController,
                                  phoneController: _phoneController,
                                  passwordController: _passwordController,
                                  confirmController: _confirmPasswordController,
                                  isLoading: isLoading,
                                  obscurePassword: _obscurePassword,
                                  obscureConfirm: _obscureConfirm,
                                  errorMessage: _errorMessage,
                                  onTogglePassword: () =>
                                      setState(() => _obscurePassword = !_obscurePassword),
                                  onToggleConfirm: () =>
                                      setState(() => _obscureConfirm = !_obscureConfirm),
                                  onSubmit: _handleRegister,
                                ),
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .slideY(
                        begin: 0.3,
                        end: 0,
                        duration: 500.ms,
                        delay: 150.ms,
                        curve: Curves.easeOutCubic,
                      )
                      .fadeIn(duration: 400.ms, delay: 150.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Gradient step indicator ────────────────────────────────────────────────

class _GradientStepIndicator extends StatelessWidget {
  const _GradientStepIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final active = i == currentStep;
        final done = i < currentStep;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              gradient: (active || done) ? AppColors.brandGradient : null,
              color: (active || done)
                  ? null
                  : Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

// ── Step 1: Name ───────────────────────────────────────────────────────────

class _Step1 extends StatelessWidget {
  const _Step1({
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.isLoading,
    required this.onNext,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final bool isLoading;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tell us your name',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Step 1 of 2',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.38),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 28),
          _DarkTextField(
            controller: firstNameController,
            label: 'First Name',
            icon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          _DarkTextField(
            controller: lastNameController,
            label: 'Last Name',
            icon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.done,
            enabled: !isLoading,
            onFieldSubmitted: (_) => onNext(),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 28),
          GradientButton(
            onPressed: isLoading ? null : onNext,
            label: 'Continue',
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}

// ── Step 2: Account details ────────────────────────────────────────────────

class _Step2 extends StatelessWidget {
  const _Step2({
    required this.formKey,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmController,
    required this.isLoading,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.errorMessage,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onSubmit,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool isLoading;
  final bool obscurePassword;
  final bool obscureConfirm;
  final String? errorMessage;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Account details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Step 2 of 2',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.38),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),

          if (errorMessage != null) ...[
            _ErrorBanner(
              message: errorMessage!,
              onDismiss: () {},
            ),
          ],

          _DarkTextField(
            controller: emailController,
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
            controller: phoneController,
            label: 'Phone Number',
            hint: '0712345678',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Phone number is required';
              final digits = v.trim().replaceAll(RegExp(r'\D'), '');
              if (digits.length < 10) return 'Enter a valid phone number';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _DarkTextField(
            controller: passwordController,
            label: 'Password',
            icon: Icons.lock_outline_rounded,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Colors.white.withValues(alpha: 0.4),
                size: 20,
              ),
              onPressed: onTogglePassword,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter a password';
              if (v.length < 8) return 'Minimum 8 characters';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _DarkTextField(
            controller: confirmController,
            label: 'Confirm Password',
            icon: Icons.lock_outline_rounded,
            obscureText: obscureConfirm,
            textInputAction: TextInputAction.done,
            enabled: !isLoading,
            onFieldSubmitted: (_) => onSubmit(),
            suffixIcon: IconButton(
              icon: Icon(
                obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Colors.white.withValues(alpha: 0.4),
                size: 20,
              ),
              onPressed: onToggleConfirm,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 28),
          GradientButton(
            onPressed: isLoading ? null : onSubmit,
            label: 'Create Account',
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}

// ── Shared auth widgets ────────────────────────────────────────────────────

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
        labelStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 14),
        hintStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 14),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
