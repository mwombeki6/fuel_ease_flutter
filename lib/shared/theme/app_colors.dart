import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color brand = Color(0xFF2563EB);
  static const Color brandDark = Color(0xFF1D4ED8);
  static const Color brandLight = Color(0xFF3B82F6);
  static const Color brandCyan = Color(0xFF06B6D4);
  static const Color brandGlow = Color(0x402563EB);

  // Legacy aliases (keep for backward compat)
  static const Color primary = brand;
  static const Color primaryDark = brandDark;
  static const Color primaryLight = brandLight;
  static const Color primarySoft = Color(0xFFEFF6FF);
  static const Color primaryDarkMode = brandLight;
  static const Color primarySoftDark = Color(0xFF1E3A5F);
  static const Color accent = brandCyan;

  // ── Dark backgrounds (primary theme) ────────────────────────────────────
  static const Color midnight = Color(0xFF060914);
  static const Color navy = Color(0xFF0A0E21);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF141B2D);
  static const Color surfaceElevatedDark = Color(0xFF1A2440);
  static const Color surfaceVariantDark = Color(0xFF1E2B45);
  static const Color borderDark = Color(0xFF1E3A5F);
  static const Color borderSubtleDark = Color(0xFF0F2040);

  // ── Milk (warm light) backgrounds ────────────────────────────────────────
  static const Color background = Color(0xFFFAF8F2);         // warm cream
  static const Color surface = Color(0xFFFDFCF8);            // near-white warm
  static const Color surfaceVariant = Color(0xFFF0EBE0);     // light tan
  static const Color surfaceStrong = Color(0xFFE5DFD2);      // warm beige
  static const Color border = Color(0xFFD8D2C4);             // warm border
  static const Color borderStrong = Color(0xFFC4BDB0);       // stronger warm border

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFFCBD5E1);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textTertiaryDark = Color(0xFF4B6280);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successDim = Color(0x2010B981);
  static const Color error = Color(0xFFEF4444);
  static const Color errorDim = Color(0x20EF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningDim = Color(0x20F59E0B);
  static const Color info = Color(0xFF06B6D4);
  static const Color infoDim = Color(0x2006B6D4);

  // Legacy semantic
  static const Color statusActive = success;
  static const Color statusInactive = Color(0xFF64748B);
  static const Color statusPending = warning;
  static const Color statusError = error;

  // ── Fuel type colors ──────────────────────────────────────────────────────
  static const Color petrolColor = brand;
  static const Color dieselColor = warning;
  static const Color premiumColor = Color(0xFF8B5CF6);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const Gradient brandGradient = LinearGradient(
    colors: [brand, brandCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient nightGradient = LinearGradient(
    colors: [midnight, navy, backgroundDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Gradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A2440), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient successGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient fuelCardGradient = LinearGradient(
    colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF0891B2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  // ── Glass ────────────────────────────────────────────────────────────────
  static const Color glassDark = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x1AFFFFFF);
  static const Color glassLight = Color(0x0D000000);

  // ── Overlay ──────────────────────────────────────────────────────────────
  static const Color overlay = Color(0x99000000);
  static const Color scrim = Color(0xCC000000);
  static const Color shadow = Color(0x40000000);
  static const Color brandShadow = Color(0x402563EB);

  // ── Charts ────────────────────────────────────────────────────────────────
  static const List<Color> chartColors = [
    brand, brandCyan, warning, success, premiumColor, Color(0xFFEC4899),
  ];
}
