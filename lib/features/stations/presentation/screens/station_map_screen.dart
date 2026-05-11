import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/stations/data/models/station_map_pin.dart';
import 'package:fuel_ease_flutter/features/stations/presentation/providers/station_map_provider.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';
import 'package:fuel_ease_flutter/shared/utils/app_snackbar.dart';

const _dsm = LatLng(-6.7924, 39.2083); // Dar es Salaam fallback

class StationMapScreen extends ConsumerStatefulWidget {
  const StationMapScreen({super.key});

  @override
  ConsumerState<StationMapScreen> createState() => _StationMapScreenState();
}

class _StationMapScreenState extends ConsumerState<StationMapScreen> {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  StationMapPin? _selectedPin;
  bool _locating = false;

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _goToMyLocation() async {
    setState(() => _locating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _mapController.move(LatLng(pos.latitude, pos.longitude), 13);
    } catch (_) {
      // silently ignore location errors
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pinsAsync = ref.watch(stationMapPinsProvider);
    final cs = Theme.of(context).colorScheme;

    ref.listen(stationMapPinsProvider, (_, next) {
      next.whenOrNull(error: (e, _) => AppSnackbar.fromError(context, e));
    });

    return Scaffold(
      backgroundColor: cs.surface,
      body: pinsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: AppSnackbar.friendlyMessage(e),
          onRetry: () => ref.invalidate(stationMapPinsProvider),
        ),
        data: (pins) {
          final filtered = _searchQuery.isEmpty
              ? pins
              : pins
                  .where((p) =>
                      p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      p.region.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      p.district.toLowerCase().contains(_searchQuery.toLowerCase()))
                  .toList();

          return Stack(
            children: [
              // Full-screen map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _dsm,
                  initialZoom: 7,
                  minZoom: 5,
                  maxZoom: 18,
                  onTap: (tap, pos) => setState(() => _selectedPin = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.fuelease.app',
                  ),
                  MarkerLayer(
                    markers: filtered
                        .map((pin) => _buildMarker(pin))
                        .toList(),
                  ),
                ],
              ),

              // Floating search bar
              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search stations…',
                        prefixIcon: Icon(Icons.search_rounded,
                            color: cs.onSurface.withValues(alpha: 0.4)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                        filled: false,
                      ),
                    ),
                  ),
                ),
              ),

              // My location FAB
              Positioned(
                bottom: _selectedPin != null ? 280 : 40,
                right: 16,
                child: FloatingActionButton.small(
                  onPressed: _locating ? null : _goToMyLocation,
                  backgroundColor: cs.surface,
                  foregroundColor: cs.primary,
                  elevation: 4,
                  child: _locating
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.primary,
                          ),
                        )
                      : const Icon(Icons.my_location_rounded),
                ),
              ),

              // Station count chip
              if (filtered.isNotEmpty)
                Positioned(
                  bottom: _selectedPin != null ? 280 : 40,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      '${filtered.length} station${filtered.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),

              // Bottom sheet
              if (_selectedPin != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _StationSheet(
                    pin: _selectedPin!,
                    onClose: () => setState(() => _selectedPin = null),
                    onFuelUp: () {
                      context.push(
                        Routes.createDispensingRequest,
                        extra: _selectedPin!.id,
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Marker _buildMarker(StationMapPin pin) {
    final isSuspended = pin.hasSuspension;
    final isActive = pin.status == 'active';
    final color = isSuspended
        ? AppColors.error
        : isActive
            ? AppColors.primary
            : AppColors.statusInactive;

    return Marker(
      point: LatLng(pin.lat, pin.lng),
      width: 44,
      height: 44,
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedPin = pin);
          _mapController.move(
            LatLng(pin.lat - 0.005, pin.lng),
            _mapController.camera.zoom > 12
                ? _mapController.camera.zoom
                : 13,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            pin.activePumps.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _StationSheet extends StatelessWidget {
  const _StationSheet({
    required this.pin,
    required this.onClose,
    required this.onFuelUp,
  });

  final StationMapPin pin;
  final VoidCallback onClose;
  final VoidCallback onFuelUp;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSuspended = pin.hasSuspension;
    final statusLabel = isSuspended ? 'Suspended' : pin.status;
    final statusColor = isSuspended
        ? AppColors.error
        : pin.status == 'active'
            ? AppColors.success
            : AppColors.statusInactive;
    final canFuelUp = pin.status == 'active' && !isSuspended;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle + close
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outline.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pin.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                        ),
                        if (pin.district.isNotEmpty || pin.region.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            [pin.district, pin.region]
                                .where((s) => s.isNotEmpty)
                                .join(', '),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color:
                                      cs.onSurface.withValues(alpha: 0.5),
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      statusLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Icon(Icons.ev_station_rounded,
                      size: 16,
                      color: cs.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 6),
                  Text(
                    '${pin.activePumps} active pump${pin.activePumps != 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Fuel Up Here button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: canFuelUp ? onFuelUp : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: canFuelUp ? cs.primary : cs.outline,
                  ),
                  child: Text(
                    canFuelUp ? 'Fuel Up Here' : 'Station Unavailable',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 48,
                color: cs.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Could not load map',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
