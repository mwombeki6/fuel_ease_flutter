import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Light mode ──────────────────────────────────────────────────────────

  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primarySoft = Color(0xFFEFF6FF);

  static const Color accent = Color(0xFF0EA5E9);

  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color surfaceStrong = Color(0xFFE2E8F0);

  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFFCBD5E1);

  // ── Dark mode ────────────────────────────────────────────────────────────

  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceVariantDark = Color(0xFF263348);
  static const Color borderDark = Color(0xFF334155);

  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textTertiaryDark = Color(0xFF64748B);

  static const Color primaryDarkMode = Color(0xFF3B82F6);
  static const Color primarySoftDark = Color(0xFF1E3A5F);

  // ── Semantic ─────────────────────────────────────────────────────────────

  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);
  static const Color info = Color(0xFF0EA5E9);

  static const Color statusActive = Color(0xFF16A34A);
  static const Color statusInactive = Color(0xFF64748B);
  static const Color statusPending = Color(0xFFD97706);
  static const Color statusError = Color(0xFFDC2626);

  // ── Fuel types ───────────────────────────────────────────────────────────

  static const Color petrolColor = Color(0xFF2563EB);
  static const Color dieselColor = Color(0xFFD97706);
  static const Color premiumColor = Color(0xFF0EA5E9);

  // ── Overlay ──────────────────────────────────────────────────────────────

  static const Color overlay = Color(0x33000000);
  static const Color scrim = Color(0x99000000);
  static const Color shadow = Color(0x14000000);

  // ── Charts ───────────────────────────────────────────────────────────────

  static const List<Color> chartColors = [
    primary,
    accent,
    warning,
    info,
    success,
    Color(0xFF8B5CF6),
  ];
}
