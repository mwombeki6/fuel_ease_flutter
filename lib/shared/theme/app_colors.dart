import 'package:flutter/material.dart';

/// App color palette
class AppColors {
  AppColors._();

  // Primary colors (Deep Teal)
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryDark = Color(0xFF0B5F58);
  static const Color primaryLight = Color(0xFF14B8A6);

  // Accent colors (Warm Orange)
  static const Color accent = Color(0xFFF97316);
  static const Color accentDark = Color(0xFFEA580C);
  static const Color accentLight = Color(0xFFFDBA74);

  // Semantic colors
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF0284C7);

  // Neutral colors
  static const Color background = Color(0xFFF7F4EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1ECE5);
  static const Color surfaceStrong = Color(0xFFEFE9E2);

  // Text colors
  static const Color textPrimary = Color(0xFF0B1320);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textDisabled = Color(0xFFD1D5DB);

  // Border colors
  static const Color border = Color(0xFFE7E1DA);
  static const Color borderDark = Color(0xFFD6CFC7);

  // Overlay colors
  static const Color overlay = Color(0x33000000); // 20% black
  static const Color scrim = Color(0x99000000); // 60% black
  static const Color shadow = Color(0x14000000); // 8% black

  // Status colors
  static const Color statusActive = Color(0xFF16A34A);
  static const Color statusInactive = Color(0xFF64748B);
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusError = Color(0xFFDC2626);

  // Fuel type colors (for visual differentiation)
  static const Color petrolColor = Color(0xFF0F766E);
  static const Color dieselColor = Color(0xFFF59E0B);
  static const Color premiumColor = Color(0xFF0284C7);

  // Gradient colors
  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF0B3552)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient accentGradient = LinearGradient(
    colors: [accent, accentDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient cardGradient = LinearGradient(
    colors: [surface, surfaceVariant],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Chart colors
  static const List<Color> chartColors = [
    primary,
    accent,
    warning,
    info,
    success,
    Color(0xFF0EA5E9), // Sky
  ];
}
