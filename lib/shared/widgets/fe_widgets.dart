import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AnimatedCounter — smoothly interpolates numeric display
// ─────────────────────────────────────────────────────────────────────────────

class AnimatedCounter extends StatefulWidget {
  const AnimatedCounter({
    required this.value,
    required this.formatter,
    super.key,
    this.style,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
  });

  final double value;
  final String Function(double) formatter;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _from = 0;
  double _to = 0;

  @override
  void initState() {
    super.initState();
    _to = widget.value;
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = Tween<double>(begin: _from, end: _to)
        .animate(CurvedAnimation(parent: _ctrl, curve: widget.curve));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _from = _anim.value;
      _to = widget.value;
      _anim = Tween<double>(begin: _from, end: _to)
          .animate(CurvedAnimation(parent: _ctrl, curve: widget.curve));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, _) => Text(
          widget.formatter(_anim.value),
          style: widget.style,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// GlassCard — frosted glass effect
// ─────────────────────────────────────────────────────────────────────────────

class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(20),
    this.blur = 12,
    this.opacity = 0.08,
    this.borderOpacity = 0.12,
    this.borderRadius = 20,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double blur;
  final double opacity;
  final double borderOpacity;
  final double borderRadius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = color ?? (isDark ? Colors.white : Colors.black);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: baseColor.withValues(alpha: borderOpacity),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GradientCard — card with gradient background + optional glow
// ─────────────────────────────────────────────────────────────────────────────

class GradientCard extends StatelessWidget {
  const GradientCard({
    required this.child,
    super.key,
    this.gradient = AppColors.brandGradient,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 20,
    this.glowColor,
    this.glowBlur = 24,
    this.glowSpread = 0,
  });

  final Widget child;
  final Gradient gradient;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? glowColor;
  final double glowBlur;
  final double glowSpread;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: glowColor != null
            ? [
                BoxShadow(
                  color: glowColor!,
                  blurRadius: glowBlur,
                  spreadRadius: glowSpread,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PulsingDot — animated status indicator
// ─────────────────────────────────────────────────────────────────────────────

class PulsingDot extends StatelessWidget {
  const PulsingDot({
    super.key,
    this.color = AppColors.success,
    this.size = 8,
    this.pulseSize = 20,
  });

  final Color color;
  final double size;
  final double pulseSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: pulseSize,
      height: pulseSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: pulseSize,
            height: pulseSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.2),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.2, 1.2),
                duration: 1200.ms,
                curve: Curves.easeOut,
              )
              .then()
              .fadeOut(duration: 600.ms),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FeShimmer — standardized shimmer loading placeholder
// ─────────────────────────────────────────────────────────────────────────────

class FeShimmer extends StatelessWidget {
  const FeShimmer({
    required this.child,
    super.key,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!enabled) return child;

    return Shimmer.fromColors(
      baseColor: isDark
          ? AppColors.surfaceVariantDark
          : AppColors.surfaceVariant,
      highlightColor: isDark
          ? AppColors.surfaceElevatedDark
          : AppColors.surface,
      child: child,
    );
  }
}

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    required this.width,
    required this.height,
    super.key,
    this.radius = 12,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GradientButton — primary CTA with gradient + glow
// ─────────────────────────────────────────────────────────────────────────────

class GradientButton extends StatelessWidget {
  const GradientButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.isLoading = false,
    this.gradient = AppColors.brandGradient,
    this.height = 56,
    this.radius = 16,
    this.glow = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final Gradient gradient;
  final double height;
  final double radius;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.5,
        duration: 200.ms,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            gradient: enabled ? gradient : null,
            color: enabled ? null : AppColors.textDisabled,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: (enabled && glow)
                ? [
                    BoxShadow(
                      color: AppColors.brandGlow,
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StatusBadge — pill chip for status
// ─────────────────────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FeTextField — styled text input consistent across screens
// ─────────────────────────────────────────────────────────────────────────────

class FeTextField extends StatelessWidget {
  const FeTextField({
    required this.controller,
    required this.label,
    super.key,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofillHints,
    this.enabled = true,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final bool enabled;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      autofillHints: autofillHints,
      enabled: enabled,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 20)
            : null,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UserLocationMarker — pulsing "you are here" dot for flutter_map markers
// ─────────────────────────────────────────────────────────────────────────────

class UserLocationMarker extends StatelessWidget {
  const UserLocationMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.25),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scale(
                begin: const Offset(0.3, 0.3),
                end: const Offset(1.2, 1.2),
                duration: 1600.ms,
                curve: Curves.easeOut,
              )
              .then()
              .fadeOut(duration: 500.ms),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SectionHeader — consistent section label
// ─────────────────────────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    super.key,
    this.action,
    this.actionLabel,
  });

  final String title;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
            letterSpacing: 0.1,
          ),
        ),
        if (action != null && actionLabel != null)
          GestureDetector(
            onTap: action,
            child: Text(
              actionLabel!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
          ),
      ],
    );
  }
}
