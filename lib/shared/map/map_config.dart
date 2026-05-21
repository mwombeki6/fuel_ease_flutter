import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fuel_ease_flutter/core/constants/api_constants.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';

// After uploading assets/fuel_ease_mapbox_style.json to Mapbox Studio,
// replace this placeholder with the real hosted URL.
// Studio → New style → Import → paste the JSON → Publish → copy Style URL.
// Format: mapbox://styles/{username}/{styleId}
const _kFuelEaseStyleId = 'lubex/cmpfdl5oa000c01sghayn46wh';

enum MapStyle { night, streets, satellite, fuelEase }

extension MapStyleX on MapStyle {
  String get label => switch (this) {
        MapStyle.night => 'Night',
        MapStyle.streets => 'Streets',
        MapStyle.satellite => 'Satellite',
        MapStyle.fuelEase => 'FuelEase',
      };

  IconData get icon => switch (this) {
        MapStyle.night => Icons.nightlight_round,
        MapStyle.streets => Icons.map_rounded,
        MapStyle.satellite => Icons.satellite_alt_rounded,
        MapStyle.fuelEase => Icons.local_gas_station_rounded,
      };

  Color get mapBackground => switch (this) {
        MapStyle.night => const Color(0xFF060914),
        MapStyle.streets => const Color(0xFFE8E0D8),
        MapStyle.satellite => const Color(0xFF1A1A1A),
        MapStyle.fuelEase => const Color(0xFF060914),
      };

  String tileUrl() {
    final token = ApiConstants.mapboxToken;
    return switch (this) {
      MapStyle.night =>
        'https://api.mapbox.com/styles/v1/mapbox/navigation-night-v1/tiles/{z}/{x}/{y}@2x?access_token=$token',
      MapStyle.streets =>
        'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}@2x?access_token=$token',
      MapStyle.satellite =>
        'https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v12/tiles/{z}/{x}/{y}@2x?access_token=$token',
      MapStyle.fuelEase =>
        'https://api.mapbox.com/styles/v1/$_kFuelEaseStyleId/tiles/{z}/{x}/{y}@2x?access_token=$token',
    };
  }

  bool get isCustomStyle => this == MapStyle.fuelEase;
}

// ─────────────────────────────────────────────────────────────────────────────
// Style picker pill
// ─────────────────────────────────────────────────────────────────────────────

class MapStylePicker extends StatelessWidget {
  const MapStylePicker({
    required this.current,
    required this.onChanged,
    super.key,
  });

  final MapStyle current;
  final ValueChanged<MapStyle> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: MapStyle.values.map((style) {
          final selected = style == current;
          return GestureDetector(
            onTap: () => onChanged(style),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                horizontal: selected ? 10 : 8,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? (style == MapStyle.fuelEase
                        ? const Color(0xFF2563EB)
                        : AppColors.primary)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(style.icon,
                      size: 13,
                      color: selected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.6)),
                  if (selected) ...[
                    const SizedBox(width: 5),
                    Text(
                      style.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cluster badge — shown when multiple station markers are grouped
// ─────────────────────────────────────────────────────────────────────────────

class StationClusterMarker extends StatelessWidget {
  const StationClusterMarker({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    final size = count < 10 ? 44.0 : count < 100 ? 50.0 : 58.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.5),
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          count < 100 ? '$count' : '99+',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: count < 10 ? 15 : 12,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live dispense pulse — overlaid on actively dispensing station markers
// ─────────────────────────────────────────────────────────────────────────────

class LiveDispensePulse extends StatelessWidget {
  const LiveDispensePulse({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer pulsing ring
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withValues(alpha: 0.2),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(0.6, 0.6),
              end: const Offset(1.4, 1.4),
              duration: 1400.ms,
              curve: Curves.easeInOut,
            )
            .fade(begin: 0.7, end: 0.0),
        // Inner stable dot
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success,
            boxShadow: [
              BoxShadow(
                color: AppColors.success,
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
