import 'package:flutter/material.dart';

/// Pump & Go — FuelEase mobile app color tokens.
class AppColors {
  AppColors._();

  // ── Light theme ──────────────────────────────────────────────────────────
  static const Color background = Color(0xFFFAF8F4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF0EEE8);
  static const Color border = Color(0xFFEDEAE1);
  static const Color textPrimary = Color(0xFF211F1A);
  static const Color textSecondary = Color(0xFF8A8578);
  static const Color evergreen = Color(0xFF1F4D3A);
  static const Color brightGreen = Color(0xFF3FAE5C);
  static const Color amberText = Color(0xFFA3760F);
  static const Color amberSurface = Color(0xFFFDF2E3);
  static const Color errorDot = Color(0xFFD9534F);
  static const Color mapCanvas = Color(0xFFE9EDE2);
  static const Color mapRoad = Color(0xFFD3DCC3);
  static const Color mapAreaFill = Color(0xFFDFE4D5);
  static const Color mapLabel = Color(0xFF8A9179);
  static const Color unavailableMarkerLight = Color(0xFFB9B3A3);

  // ── Dark theme ───────────────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF161513);
  static const Color surfaceDark = Color(0xFF211F1C);
  static const Color surfaceMutedDark = Color(0xFF2A2825);
  static const Color borderDark = Color(0xFF3A3733);
  static const Color textPrimaryDark = Color(0xFFF2F0EA);
  static const Color textSecondaryDark = Color(0xFFA8A296);
  static const Color evergreenDark = Color(0xFF2A5C46);
  static const Color brightGreenDark = Color(0xFF4BC470);
  static const Color amberTextDark = Color(0xFFF0CB80);
  static const Color amberSurfaceDark = Color(0xFF332A17);
  static const Color errorDotDark = Color(0xFFE8837E);
  static const Color mapCanvasDark = Color(0xFF1C1A17);
  static const Color mapRoadDark = Color(0xFF28261F);
  static const Color mapLabelDark = Color(0xFF8F897C);
  static const Color mapRoadLabelDark = Color(0xFFC9C2AE);
  static const Color unavailableMarkerDark = Color(0xFF4A463D);

  // ── Semantic (kept, repointed) ──────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successDim = Color(0xFF047857);
  static const Color error = Color(0xFFEF4444);
  static const Color errorDim = Color(0xFFB91C1C);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningDim = Color(0xFFB45309);
  static const Color info = Color(0xFF06B6D4);
  static const Color infoDim = Color(0xFF0E7490);

  // ── Fuel type (kept, repointed) ─────────────────────────────────────────
  static const Color petrolColor = evergreen;
  static const Color dieselColor = warning;
  static const Color premiumColor = Color(0xFF8B5CF6);

  // ── Neutral overlays (kept, unchanged) ──────────────────────────────────
  static const Color shadow = Color(0x40000000);
  static const Color overlay = Color(0x99000000);
  static const Color scrim = Color(0xCC000000);

  // ── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    colors: [evergreen, brightGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient fuelCardGradient = LinearGradient(
    colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF0891B2)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
