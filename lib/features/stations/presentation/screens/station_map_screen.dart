import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/stations/data/models/station_map_pin.dart';
import 'package:fuel_ease_flutter/features/stations/presentation/providers/station_map_provider.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';
import 'package:fuel_ease_flutter/shared/theme/app_text_styles.dart';

// Default center: Dar es Salaam, Tanzania
const _defaultCenter = LatLng(-6.7924, 39.2083);
const _defaultZoom = 7.0;

class StationMapScreen extends ConsumerWidget {
  const StationMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinsAsync = ref.watch(stationMapPinsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Station Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'List view',
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: pinsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.map_outlined, size: 48, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  'Could not load map',
                  style: AppTextStyles.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(stationMapPinsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (pins) => _MapView(pins: pins),
      ),
    );
  }
}

class _MapView extends StatelessWidget {
  const _MapView({required this.pins});

  final List<StationMapPin> pins;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: _defaultCenter,
        initialZoom: _defaultZoom,
        minZoom: 5,
        maxZoom: 18,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.fuelease.app',
        ),
        MarkerLayer(
          markers: pins.map((pin) => _buildMarker(context, pin)).toList(),
        ),
      ],
    );
  }

  Marker _buildMarker(BuildContext context, StationMapPin pin) {
    final isSuspended = pin.hasSuspension;
    final isActive = pin.status == 'active';
    final color = isSuspended
        ? AppColors.error
        : isActive
            ? AppColors.primary
            : AppColors.textSecondary;

    return Marker(
      point: LatLng(pin.lat, pin.lng),
      child: GestureDetector(
        onTap: () => _showPinSheet(context, pin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_gas_station,
                color: Colors.white,
                size: 16,
              ),
            ),
            CustomPaint(
              size: const Size(8, 5),
              painter: _TrianglePainter(color: color),
            ),
          ],
        ),
      ),
    );
  }

  void _showPinSheet(BuildContext context, StationMapPin pin) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PinSheet(pin: pin),
    );
  }
}

class _PinSheet extends StatelessWidget {
  const _PinSheet({required this.pin});

  final StationMapPin pin;

  @override
  Widget build(BuildContext context) {
    final isSuspended = pin.hasSuspension;
    final statusLabel = isSuspended ? 'Suspended' : pin.status;
    final statusColor = isSuspended
        ? AppColors.error
        : pin.status == 'active'
            ? AppColors.success
            : AppColors.textSecondary;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(pin.name, style: AppTextStyles.titleMedium),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    statusLabel,
                    style: AppTextStyles.labelSmall.copyWith(color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (pin.district.isNotEmpty || pin.region.isNotEmpty)
              Text(
                [pin.district, pin.region].where((s) => s.isNotEmpty).join(', '),
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.ev_station, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${pin.activePumps} active pump${pin.activePumps != 1 ? 's' : ''}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.info_outline),
                label: const Text('View Station Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(Routes.stationDetails(pin.id));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}
