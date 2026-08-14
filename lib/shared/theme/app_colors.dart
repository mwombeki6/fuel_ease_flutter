import 'package:flutter/material.dart';

/// FuelEase Modern — Beautiful, glassmorphism-ready color tokens.
class AppColors {
  AppColors._();

  // ── Light Theme ──────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF0F2F5);
  static const Color border = Color(0xFFE4E7EC);
  static const Color borderStrong = Color(0xFFD0D7E0);
  static const Color textPrimary = Color(0xFF1A1D23);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color inverseText = Color(0xFFFFFFFF);

  // Brand - Modern Green
  static const Color primary = Color(0xFF059669);
  static const Color primaryLight = Color(0xFF10B981);
  static const Color primaryDark = Color(0xFF047857);
  static const Color primaryContainer = Color(0xFFD1FAE5);
  static const Color onPrimaryContainer = Color(0xFF064E3B);

  // Accent - Warm Orange
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFBBF24);
  static const Color accentDark = Color(0xFFD97706);
  static const Color accentContainer = Color(0xFFFEF3C7);
  static const Color onAccentContainer = Color(0xFF78350F);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color successContainer = Color(0xFFD1FAE5);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color errorContainer = Color(0xFFFEF2F2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);
  static const Color infoContainer = Color(0xFFDBEAFE);

  // Amber (pending/schedule tones)
  static const Color amberText = Color(0xFFA3760F);
  static const Color amberSurface = Color(0xFFFDF2E3);
  static const Color amberDark = Color(0xFFF0CB80);
  static const Color amberTextDark = Color(0xFFF0CB80);
  static const Color amberSurfaceDark = Color(0xFF332A17);

  // Map markers
  static const Color unavailableMarkerLight = Color(0xFFB9B3A3);
  static const Color unavailableMarkerDark = Color(0xFF4A463D);

  // Fuel Types
  static const Color petrolColor = Color(0xFF059669);
  static const Color dieselColor = Color(0xFFF59E0B);
  static const Color premiumColor = Color(0xFF8B5CF6);
  static const Color keroColor = Color(0xFFEC4899);

  // Glassmorphism overlays
  static const Color glassLight = Color(0xE6FFFFFF);
  static const Color glassLightStrong = Color(0xCCFFFFFF);
  static const Color glassDark = Color(0xCC1F2937);
  static const Color glassDarkStrong = Color(0xE61F2937);
  static const Color glassBorderLight = Color(0x4DFFFFFF);
  static const Color glassBorderDark = Color(0x4DFFFFFF);

  // Shadows
  static const Color shadow = Color(0x1A000000);
  static const Color shadowStrong = Color(0x33000000);
  static const Color overlay = Color(0x80000000);
  static const Color scrim = Color(0xCC000000);

  // ── Dark Theme ───────────────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceElevatedDark = Color(0xFF1E293B);
  static const Color surfaceMutedDark = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF334155);
  static const Color borderStrongDark = Color(0xFF475569);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textTertiaryDark = Color(0xFF64748B);
  static const Color inverseTextDark = Color(0xFF0F172A);

  // Dark Brand
  static const Color primaryDarkTheme = Color(0xFF34D399);
  static const Color primaryLightDark = Color(0xFF6EE7B7);
  static const Color primaryDarkDark = Color(0xFF10B981);
  static const Color primaryContainerDark = Color(0xFF064E3B);
  static const Color onPrimaryContainerDark = Color(0xFFD1FAE5);

  // Dark Accent
  static const Color accentDarkTheme = Color(0xFFFBBF24);
  static const Color accentLightDark = Color(0xFFFCD34D);
  static const Color accentDarkDark = Color(0xFFF59E0B);
  static const Color accentContainerDark = Color(0xFF78350F);
  static const Color onAccentContainerDark = Color(0xFFFEF3C7);

  // Dark Semantic
  static const Color successDark = Color(0xFF34D399);
  static const Color errorDark = Color(0xFFF87171);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color infoDark = Color(0xFF60A5FA);

  // Dark Fuel Types
  static const Color petrolColorDark = Color(0xFF34D399);
  static const Color dieselColorDark = Color(0xFFFBBF24);
  static const Color premiumColorDark = Color(0xFFA78BFA);
  static const Color keroColorDark = Color(0xFFF472B6);

  // Dark Glass
  static const Color glassDarkTheme = Color(0xCC1E293B);
  static const Color glassDarkStrongTheme = Color(0xE61E293B);
  static const Color glassBorderDarkTheme = Color(0x4DFFFFFF);

  // Dark Shadows
  static const Color shadowDark = Color(0x4D000000);
  static const Color shadowStrongDark = Color(0x66000000);
  static const Color overlayDark = Color(0x99000000);
  static const Color scrimDark = Color(0xE6000000);

  // ── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandGradientDark = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradientLight = LinearGradient(
    colors: [Color(0xE6FFFFFF), Color(0xCCFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradientDark = LinearGradient(
    colors: [Color(0xE61E293B), Color(0xCC1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandGradientHorizontal = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient surfaceGradientLight = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient surfaceGradientDark = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient accentGradientLight = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradientDark = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient fuelCardGradientLight = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF059669)],
    stops: [0.0, 0.6, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient fuelCardGradientDark = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF10B981)],
    stops: [0.0, 0.6, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassShineLight = LinearGradient(
    colors: [
      Color(0x33FFFFFF),
      Color(0x1AFFFFFF),
      Color(0x00FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient glassShineDark = LinearGradient(
    colors: [
      Color(0x33FFFFFF),
      Color(0x1AFFFFFF),
      Color(0x00FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  // ── Fuel Type Gradients ─────────────────────────────────────────────────
  static const LinearGradient petrolGradientLight = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dieselGradientLight = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumGradientLight = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient keroGradientLight = LinearGradient(
    colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient petrolGradientDark = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dieselGradientDark = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumGradientDark = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient keroGradientDark = LinearGradient(
    colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}