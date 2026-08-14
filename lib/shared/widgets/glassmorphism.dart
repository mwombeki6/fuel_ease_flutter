import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';

/// Glassmorphism utilities for beautiful, modern UI.
class Glassmorphism {
  Glassmorphism._();

  /// Light theme glass container
  static Widget glassLight({
    required Widget child,
    double blur = 20,
    double opacity = 0.8,
    double borderOpacity = 0.2,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? color,
    List<BoxShadow>? shadows,
    Gradient? gradient,
    Border? border,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          margin: margin,
          decoration: BoxDecoration(
            color: color ?? AppColors.glassLight,
            borderRadius: borderRadius ?? BorderRadius.circular(24),
            border: border ??
                Border.all(
                  color: Colors.white.withValues(alpha: borderOpacity),
                  width: 1,
                ),
            gradient: gradient,
            boxShadow: shadows ??
                [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.1),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                    spreadRadius: 0,
                  ),
                ],
          ),
          child: child,
        ),
      ),
    );
  }

  /// Dark theme glass container
  static Widget glassDark({
    required Widget child,
    double blur = 20,
    double opacity = 0.8,
    double borderOpacity = 0.2,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? color,
    List<BoxShadow>? shadows,
    Gradient? gradient,
    Border? border,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          margin: margin,
          decoration: BoxDecoration(
            color: color ?? AppColors.glassDark,
            borderRadius: borderRadius ?? BorderRadius.circular(24),
            border: border ??
                Border.all(
                  color: Colors.white.withValues(alpha: borderOpacity),
                  width: 1,
                ),
            gradient: gradient,
            boxShadow: shadows ??
                [
                  BoxShadow(
                    color: AppColors.shadowDark,
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.05),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                    spreadRadius: 0,
                  ),
                ],
          ),
          child: child,
        ),
      ),
    );
  }

  /// Adaptive glass container that works for both themes
  static Widget glass({
    required Widget child,
    double blur = 20,
    double opacity = 0.8,
    double borderOpacity = 0.2,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? color,
    List<BoxShadow>? shadows,
    Gradient? gradient,
    Border? border,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        if (isDark) {
          return glassDark(
            child: child,
            blur: blur,
            opacity: opacity,
            borderOpacity: borderOpacity,
            borderRadius: borderRadius,
            padding: padding,
            margin: margin,
            color: color,
            shadows: shadows,
            gradient: gradient,
            border: border,
          );
        }
        return glassLight(
          child: child,
          blur: blur,
          opacity: opacity,
          borderOpacity: borderOpacity,
          borderRadius: borderRadius,
          padding: padding,
          margin: margin,
          color: color,
          shadows: shadows,
          gradient: gradient,
          border: border,
        );
      },
    );
  }

  /// Glass card with subtle shine effect
  static Widget glassCard({
    required Widget child,
    double blur = 20,
    double borderOpacity = 0.2,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    bool shine = true,
    Gradient? shineGradient,
    Color? color,
    Gradient? gradient,
    List<BoxShadow>? shadows,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final shineGradientFinal = shineGradient ??
            (isDark
                ? AppColors.glassShineDark
                : AppColors.glassShineLight);

        final Widget card = Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius ?? BorderRadius.circular(20),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: ClipRRect(
              borderRadius: borderRadius ?? BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: Container(
                  padding: padding ?? const EdgeInsets.all(20),
                  margin: margin,
                  decoration: BoxDecoration(
                    color: color ??
                        (isDark
                            ? AppColors.glassDark
                            : AppColors.glassLight),
                    gradient: gradient,
                    borderRadius: borderRadius ?? BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: borderOpacity),
                      width: 1,
                    ),
                    boxShadow: shadows ??
                        [
                          BoxShadow(
                            color: isDark
                                ? AppColors.shadowDark
                                : AppColors.shadow,
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                            spreadRadius: -4,
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                  ),
                  child: shine
                      ? Stack(
                          children: [
                            child,
                            Positioned.fill(
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: shineGradientFinal,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : child,
                ),
              ),
            ),
          ),
        );

        return card;
      },
    );
  }

  /// Glass navigation bar
  static Widget glassNavBar({
    required List<Widget> children,
    double height = 72,
    double blur = 30,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          margin: margin ??
              EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 12 + MediaQuery.paddingOf(context).bottom,
              ),
              padding: padding ?? EdgeInsets.zero,
              height: height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.glassDarkStrong
                          : AppColors.glassLightStrong,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, -4),
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      children: children,
                    ),
                  ),
                ),
              ),
            );
      },
    );
  }

  /// Glass button
  static Widget glassButton({
    required Widget child,
    required VoidCallback onPressed,
    double blur = 20,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    Color? foregroundColor,
    Gradient? gradient,
    Duration animationDuration = const Duration(milliseconds: 150),
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onPressed();
            },
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: AnimatedContainer(
              duration: animationDuration,
              curve: Curves.easeOutCubic,
              padding: padding ??
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: borderRadius ?? BorderRadius.circular(16),
                gradient: isDark
                    ? AppColors.brandGradientDark
                    : AppColors.brandGradient,
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? AppColors.primaryDark.withValues(alpha: 0.4)
                        : AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: DefaultTextStyle(
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                child: Center(child: child),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Glass input field
  static Widget glassInput({
    required TextEditingController controller,
    String? label,
    String? hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    int? maxLines,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark.withValues(alpha: 0.8)
                    : AppColors.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                controller: controller,
                obscureText: obscureText,
                keyboardType: keyboardType,
                maxLines: maxLines ?? 1,
                style: TextStyle(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: label,
                  hintText: hint,
                  prefixIcon: prefixIcon != null
                      ? Icon(
                          prefixIcon,
                          color: Colors.white.withValues(alpha: 0.6),
                          size: 20,
                        )
                      : null,
                  suffixIcon: suffixIcon,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  hintStyle: TextStyle(
                    color: (isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiary)
                        .withValues(alpha: 0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  labelStyle: TextStyle(
                    color: (isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiary)
                        .withValues(alpha: 0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                validator: validator,
                onChanged: onChanged,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Glass bottom sheet
  static Widget glassBottomSheet({
    required Widget child,
    double borderRadius = 28,
    double blur = 30,
    bool showDragHandle = true,
    Color? backgroundColor,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor ??
                    (isDark
                        ? AppColors.glassDarkStrong
                        : AppColors.glassLightStrong),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(borderRadius)),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showDragHandle) ...[
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                  Flexible(child: child),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Glass dialog
  static Widget glassDialog({
    required Widget child,
    double borderRadius = 24,
    double blur = 30,
    EdgeInsetsGeometry? padding,
    double maxWidth = 380,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Container(
                  padding: padding ?? const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.glassDarkStrong
                        : AppColors.glassLightStrong,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Glassmorphism button variants
class GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final GlassButtonVariant variant;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool loading;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  const GlassButton({
    required this.child,
    required this.onPressed,
    super.key,
    this.variant = GlassButtonVariant.primary,
    this.padding,
    this.borderRadius = 16,
    this.loading = false,
    this.leadingIcon,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (variant) {
      case GlassButtonVariant.primary:
        return Glassmorphism.glassButton(
          onPressed: onPressed,
          child: _buildContent(context),
          gradient: isDark
              ? AppColors.brandGradientDark
              : AppColors.brandGradient,
        );
      case GlassButtonVariant.secondary:
        return Glassmorphism.glassButton(
          onPressed: onPressed,
          child: _buildContent(context),
          gradient: isDark
              ? AppColors.accentGradientDark
              : AppColors.accentGradientLight,
        );
      case GlassButtonVariant.ghost:
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                child: Center(child: child),
              ),
            ),
          ),
        );
      case GlassButtonVariant.destructive:
        return Glassmorphism.glassButton(
          onPressed: onPressed,
          child: _buildContent(context),
          gradient: LinearGradient(
            colors: [
              AppColors.error,
              AppColors.errorLight,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
    }
  }

  Widget _buildContent(BuildContext context) {
    final children = <Widget>[];

    if (leadingIcon != null) {
      children.add(Icon(leadingIcon, size: 18, color: Colors.white));
      children.add(const SizedBox(width: 8));
    }

    children.add(DefaultTextStyle(
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 16,
        fontFamily: 'Sora',
      ),
      child: child,
    ));

    if (trailingIcon != null) {
      children.add(const SizedBox(width: 8));
      children.add(Icon(trailingIcon, size: 18, color: Colors.white));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

enum GlassButtonVariant {
  primary,
  secondary,
  ghost,
  destructive,
}

/// Glass card with beautiful shine
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final bool shine;
  final Color? color;
  final Gradient? gradient;
  final List<BoxShadow>? shadows;

  const GlassCard({
    required this.child,
    super.key,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius,
    this.shine = true,
    this.color,
    this.gradient,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return Glassmorphism.glassCard(
      child: child,
      padding: padding,
      margin: margin,
      onTap: onTap,
      borderRadius: borderRadius,
      shine: shine,
      color: color,
      gradient: gradient,
    );
  }
}

/// Glass container
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? color;
  final Gradient? gradient;
  final double blur;
  final double borderOpacity;

  const GlassContainer({
    required this.child,
    super.key,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.gradient,
    this.blur = 20,
    this.borderOpacity = 0.2,
  });

  @override
  Widget build(BuildContext context) {
    return Glassmorphism.glass(
      child: child,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      color: color,
      gradient: gradient,
      blur: 20,
      borderOpacity: 0.2,
    );
  }
}
