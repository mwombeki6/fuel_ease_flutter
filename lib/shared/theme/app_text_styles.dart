import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App typography styles
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _style({
    required double size,
    required FontWeight weight,
    required double height,
    double? letterSpacing,
    Color? color,
  }) {
    return GoogleFonts.sora(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  // Display styles (largest)
  static TextStyle get displayLarge => _style(
        size: 57,
        weight: FontWeight.w700,
        height: 1.12,
        letterSpacing: -0.25,
      );

  static TextStyle get displayMedium => _style(
        size: 45,
        weight: FontWeight.w700,
        height: 1.16,
      );

  static TextStyle get displaySmall => _style(
        size: 36,
        weight: FontWeight.w600,
        height: 1.22,
      );

  // Headline styles
  static TextStyle get headlineLarge => _style(
        size: 32,
        weight: FontWeight.w600,
        height: 1.25,
      );

  static TextStyle get headlineMedium => _style(
        size: 28,
        weight: FontWeight.w600,
        height: 1.29,
      );

  static TextStyle get headlineSmall => _style(
        size: 24,
        weight: FontWeight.w600,
        height: 1.33,
      );

  // Title styles
  static TextStyle get titleLarge => _style(
        size: 22,
        weight: FontWeight.w600,
        height: 1.27,
      );

  static TextStyle get titleMedium => _style(
        size: 16,
        weight: FontWeight.w600,
        height: 1.5,
        letterSpacing: 0.15,
      );

  static TextStyle get titleSmall => _style(
        size: 14,
        weight: FontWeight.w600,
        height: 1.43,
        letterSpacing: 0.1,
      );

  // Body styles
  static TextStyle get bodyLarge => _style(
        size: 16,
        weight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.4,
      );

  static TextStyle get bodyMedium => _style(
        size: 14,
        weight: FontWeight.w400,
        height: 1.43,
        letterSpacing: 0.2,
      );

  static TextStyle get bodySmall => _style(
        size: 12,
        weight: FontWeight.w400,
        height: 1.33,
        letterSpacing: 0.3,
      );

  // Label styles
  static TextStyle get labelLarge => _style(
        size: 14,
        weight: FontWeight.w600,
        height: 1.43,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMedium => _style(
        size: 12,
        weight: FontWeight.w600,
        height: 1.33,
        letterSpacing: 0.4,
      );

  static TextStyle get labelSmall => _style(
        size: 11,
        weight: FontWeight.w600,
        height: 1.45,
        letterSpacing: 0.4,
      );

  // Custom styles
  static TextStyle get buttonLarge => _style(
        size: 16,
        weight: FontWeight.w600,
        height: 1.25,
        letterSpacing: 0.4,
      );

  static TextStyle get buttonMedium => _style(
        size: 14,
        weight: FontWeight.w600,
        height: 1.43,
        letterSpacing: 0.3,
      );

  static TextStyle get caption => _style(
        size: 12,
        weight: FontWeight.w400,
        height: 1.33,
        letterSpacing: 0.3,
      );

  static TextStyle get overline => _style(
        size: 10,
        weight: FontWeight.w600,
        height: 1.6,
        letterSpacing: 1.2,
      );
}
