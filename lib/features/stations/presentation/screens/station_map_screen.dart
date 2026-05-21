import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:fuel_ease_flutter/core/providers/station_live_activity_provider.dart';
import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/core/services/mapbox_directions_service.dart';
import 'package:fuel_ease_flutter/core/services/mapbox_geocoding_service.dart';
import 'package:fuel_ease_flutter/features/stations/data/models/station_map_pin.dart';
import 'package:fuel_ease_flutter/features/stations/presentation/providers/station_map_provider.dart';
import 'package:fuel_ease_flutter/main.dart' show themeModeProvider;
import 'package:fuel_ease_flutter/shared/map/map_config.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';
import 'package:fuel_ease_flutter/shared/utils/app_snackbar.dart';
import 'package:fuel_ease_flutter/shared/widgets/fe_widgets.dart';

const _dsm = LatLng(-6.7924, 39.2083);
const _distCalc = Distance();

double _metersTo(LatLng a, LatLng b) =>
    _distCalc.as(LengthUnit.Meter, a, b);

String _distanceLabel(LatLng from, StationMapPin pin) {
  final m = _metersTo(from, LatLng(pin.lat, pin.lng));
  return m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';
}

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
  LatLng? _userPosition;
  StreamSubscription<Position>? _positionSub;

  MapStyle _mapStyle = MapStyle.night;
  List<LatLng>? _routePoints;
  RouteResult? _routeInfo;
  bool _loadingRoute = false;
  bool _showNearby = false;

  List<GeocodingResult> _suggestions = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final themeMode = ref.read(themeModeProvider);
    if (themeMode == ThemeMode.light) {
      _mapStyle = MapStyle.streets;
    } else if (themeMode == ThemeMode.system) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      if (brightness == Brightness.light) _mapStyle = MapStyle.streets;
    }
    // Defer until after first frame so MapController is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocation());
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _debounce?.cancel();
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final here = LatLng(pos.latitude, pos.longitude);

      if (mounted) {
        setState(() => _userPosition = here);
        _mapController.move(here, 13);
      }

      // Continuous updates — redraws marker as device moves.
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20, // update every 20 m
        ),
      ).listen((p) {
        if (mounted) {
          setState(() => _userPosition = LatLng(p.latitude, p.longitude));
        }
      });
    } catch (_) {
      // Falls back to Dar es Salaam silently if location is unavailable.
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _goToMyLocation() async {
    if (_userPosition != null) {
      _mapController.move(_userPosition!, 14);
      return;
    }
    await _initLocation();
  }

  Future<void> _fetchRoute(StationMapPin pin) async {
    if (_userPosition == null) return;
    setState(() => _loadingRoute = true);
    final result = await MapboxDirectionsService.fetchRoute(
      _userPosition!,
      LatLng(pin.lat, pin.lng),
    );
    if (!mounted) return;
    if (result == null) {
      AppSnackbar.fromError(context, Exception('Could not calculate route'));
    }
    setState(() {
      _routePoints = result?.points;
      _routeInfo = result;
      _loadingRoute = false;
    });
  }

  void _clearRoute() => setState(() {
        _routePoints = null;
        _routeInfo = null;
      });

  List<StationMapPin> _getNearby(List<StationMapPin> all) {
    if (_userPosition == null) return [];
    final sorted = List<StationMapPin>.from(all)
      ..sort((a, b) =>
          _metersTo(_userPosition!, LatLng(a.lat, a.lng))
              .compareTo(_metersTo(_userPosition!, LatLng(b.lat, b.lng))));
    return sorted.take(5).toList();
  }

  void _selectFromNearby(StationMapPin pin) {
    setState(() {
      _showNearby = false;
      _selectedPin = pin;
    });
    _mapController.move(
      LatLng(pin.lat - 0.005, pin.lng),
      _mapController.camera.zoom > 12 ? _mapController.camera.zoom : 13,
    );
  }

  void _onSearchChanged(String v, List<StationMapPin> allPins) {
    setState(() => _searchQuery = v);

    _debounce?.cancel();
    if (v.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    // Immediate station auto-pan when exactly one result remains.
    final stationMatches = allPins
        .where((p) =>
            p.name.toLowerCase().contains(v.toLowerCase()) ||
            p.region.toLowerCase().contains(v.toLowerCase()) ||
            p.district.toLowerCase().contains(v.toLowerCase()))
        .toList();
    if (stationMatches.length == 1) {
      _mapController.move(
        LatLng(stationMatches.first.lat, stationMatches.first.lng),
        14,
      );
    }

    // Debounce geocoding — only fires when the user pauses typing.
    _debounce = Timer(const Duration(milliseconds: 420), () async {
      final results = await MapboxGeocodingService.suggest(
        v,
        proximity: _userPosition,
      );
      if (mounted) setState(() => _suggestions = results);
    });
  }

  void _onSuggestionTapped(GeocodingResult result) {
    HapticFeedback.selectionClick();
    _mapController.move(result.center, 13);
    setState(() {
      _suggestions = [];
      _searchQuery = '';
    });
    _searchController.clear();
    _debounce?.cancel();
  }

  List<StationMapPin> _applyFilters(List<StationMapPin> pins) {
    var result = _searchQuery.isEmpty
        ? List<StationMapPin>.from(pins)
        : pins
            .where((p) =>
                p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                p.region.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                p.district.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    if (_userPosition != null) {
      result.sort((a, b) =>
          _metersTo(_userPosition!, LatLng(a.lat, a.lng))
              .compareTo(_metersTo(_userPosition!, LatLng(b.lat, b.lng))));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final pinsAsync = ref.watch(stationMapPinsProvider);
    final liveStations = ref.watch(stationLiveActivityProvider);
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
          final filtered = _applyFilters(pins);

          // Build station markers — cluster groups collapse at low zoom
          final stationMarkers = filtered
              .map((p) => _buildMarker(p, liveStations.contains(p.id)))
              .toList();

          // Live pulse overlay markers — placed slightly above each live pin
          final liveMarkers = filtered
              .where((p) => liveStations.contains(p.id))
              .map((p) => Marker(
                    point: LatLng(p.lat, p.lng),
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: const LiveDispensePulse(),
                  ))
              .toList();

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _dsm,
                  initialZoom: 7,
                  minZoom: 5,
                  maxZoom: 18,
                  backgroundColor: _mapStyle.mapBackground,
                  onTap: (tapPos, point) {
                    setState(() {
                      _selectedPin = null;
                      _suggestions = [];
                      _showNearby = false;
                    });
                    _clearRoute();
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: _mapStyle.tileUrl(),
                    tileSize: 512,
                    zoomOffset: -1,
                    keepBuffer: 3,
                    panBuffer: 1,
                    userAgentPackageName: 'com.fuelease.app',
                  ),
                  if (_routePoints != null)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints!,
                          color: AppColors.primary,
                          strokeWidth: 5,
                          borderStrokeWidth: 2,
                          borderColor: Colors.white.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  // Live pulse rings — drawn below station labels
                  if (liveMarkers.isNotEmpty)
                    MarkerLayer(markers: liveMarkers),
                  // Clustered station markers — collapse below zoom 12
                  MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: 80,
                      size: const Size(52, 52),
                      alignment: Alignment.center,
                      markers: stationMarkers,
                      builder: (context, markers) => StationClusterMarker(
                        count: markers.length,
                      ),
                    ),
                  ),
                  // User location — never clustered
                  if (_userPosition != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _userPosition!,
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          child: const UserLocationMarker(),
                        ),
                      ],
                    ),
                ],
              ),

              // Floating search bar + geocoding suggestions
              SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                          onChanged: (v) => _onSearchChanged(v, filtered),
                          decoration: InputDecoration(
                            hintText: 'Search stations or places…',
                            prefixIcon: Icon(Icons.search_rounded,
                                color: cs.onSurface.withValues(alpha: 0.4)),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('', filtered);
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 14),
                            filled: false,
                          ),
                        ),
                      ),
                    ),
                    if (_suggestions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _suggestions.length,
                            separatorBuilder: (ctx, i) => Divider(
                              height: 1,
                              indent: 48,
                              color: cs.outline.withValues(alpha: 0.15),
                            ),
                            itemBuilder: (_, i) {
                              final r = _suggestions[i];
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  r.iconType == IconType.poi
                                      ? Icons.place_rounded
                                      : r.iconType == IconType.address
                                          ? Icons.home_rounded
                                          : Icons.location_city_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                                title: Text(
                                  r.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                subtitle: r.fullName.isNotEmpty
                                    ? Text(
                                        r.fullName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                color: cs.onSurface
                                                    .withValues(alpha: 0.5)),
                                      )
                                    : null,
                                onTap: () => _onSuggestionTapped(r),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Map style picker — top right
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 76, 16, 0),
                    child: MapStylePicker(
                      current: _mapStyle,
                      onChanged: (s) => setState(() => _mapStyle = s),
                    ),
                  ),
                ),
              ),

              // My location FAB — filled when position is known
              Positioned(
                bottom: (_selectedPin != null || _showNearby) ? 300 : 40,
                right: 16,
                child: FloatingActionButton.small(
                  onPressed: _locating ? null : _goToMyLocation,
                  backgroundColor: cs.surface,
                  foregroundColor: _userPosition != null
                      ? AppColors.primary
                      : cs.onSurface.withValues(alpha: 0.5),
                  elevation: 4,
                  child: _locating
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : Icon(_userPosition != null
                          ? Icons.my_location_rounded
                          : Icons.location_searching_rounded),
                ),
              ),

              // Bottom-left controls: count chip + "Nearby" button
              Positioned(
                bottom: (_selectedPin != null || _showNearby) ? 300 : 40,
                left: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_userPosition != null && !_showNearby) ...[
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _showNearby = true);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.near_me_rounded,
                                  size: 13, color: Colors.white),
                              const SizedBox(width: 5),
                              Text(
                                'Nearby',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (filtered.isNotEmpty)
                      Container(
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_gas_station_rounded,
                                size: 14,
                                color: cs.onSurface.withValues(alpha: 0.5)),
                            const SizedBox(width: 5),
                            Text(
                              '${filtered.length} station${filtered.length == 1 ? '' : 's'}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Nearby stations sheet
              if (_showNearby)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _NearbySheet(
                    nearby: _getNearby(pins),
                    userPosition: _userPosition!,
                    onSelect: _selectFromNearby,
                    onClose: () => setState(() => _showNearby = false),
                  ),
                ),

              // Selected station bottom sheet
              if (_selectedPin != null && !_showNearby)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _StationSheet(
                    pin: _selectedPin!,
                    distance: _userPosition != null
                        ? _distanceLabel(_userPosition!, _selectedPin!)
                        : null,
                    routeInfo: _routeInfo,
                    loadingRoute: _loadingRoute,
                    onShowRoute: _userPosition != null
                        ? () => _fetchRoute(_selectedPin!)
                        : null,
                    onClose: () {
                      setState(() => _selectedPin = null);
                      _clearRoute();
                    },
                    onFuelUp: () => context.push(
                      Routes.createDispensingRequest,
                      extra: _selectedPin!.id,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Marker _buildMarker(StationMapPin pin, [bool isLive = false]) {
    final isSelected = _selectedPin?.id == pin.id;
    final color = pin.hasSuspension
        ? AppColors.error
        : isLive
            ? AppColors.success
            : pin.status == 'active'
                ? AppColors.brand
                : AppColors.statusInactive;

    final name =
        pin.name.length > 18 ? '${pin.name.substring(0, 16)}…' : pin.name;
    final estWidth = (name.length * 7.2 + 50.0).clamp(70.0, 180.0);

    return Marker(
      point: LatLng(pin.lat, pin.lng),
      width: estWidth,
      height: 40,
      alignment: Alignment.bottomCenter,
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? color
                  : Colors.white.withValues(alpha: 0.3),
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    color.withValues(alpha: isSelected ? 0.7 : 0.4),
                blurRadius: isSelected ? 20 : 8,
                spreadRadius: isSelected ? 2 : 0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_gas_station_rounded,
                color: isSelected ? color : Colors.white,
                size: 11,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? color : Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              if (isLive) ...[
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppColors.success
                        : Colors.white.withValues(alpha: 0.9),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.success, blurRadius: 4),
                    ],
                  ),
                ),
              ],
            ],
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
    this.distance,
    this.routeInfo,
    this.loadingRoute = false,
    this.onShowRoute,
  });

  final StationMapPin pin;
  final VoidCallback onClose;
  final VoidCallback onFuelUp;
  final String? distance;
  final RouteResult? routeInfo;
  final bool loadingRoute;
  final VoidCallback? onShowRoute;

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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outline.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
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
                        if (pin.district.isNotEmpty ||
                            pin.region.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            [pin.district, pin.region]
                                .where((s) => s.isNotEmpty)
                                .join(', '),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: cs.onSurface
                                        .withValues(alpha: 0.5)),
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
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
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
                  if (distance != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.near_me_rounded,
                        size: 14,
                        color: cs.onSurface.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Text(
                      distance!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Route row
              if (loadingRoute)
                Row(
                  children: [
                    SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Calculating route…',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                    ),
                  ],
                )
              else if (routeInfo != null)
                Row(
                  children: [
                    Icon(Icons.directions_car_rounded,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      '${routeInfo!.distanceKm.toStringAsFixed(1)} km · ${routeInfo!.durationMin} min',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onShowRoute,
                      child: Text(
                        'Recalculate',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.4),
                              decoration: TextDecoration.underline,
                            ),
                      ),
                    ),
                  ],
                )
              else if (onShowRoute != null)
                GestureDetector(
                  onTap: onShowRoute,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.directions_rounded,
                          size: 14,
                          color: AppColors.primary.withValues(alpha: 0.8)),
                      const SizedBox(width: 5),
                      Text(
                        'Show route',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

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

class _NearbySheet extends StatelessWidget {
  const _NearbySheet({
    required this.nearby,
    required this.userPosition,
    required this.onSelect,
    required this.onClose,
  });

  final List<StationMapPin> nearby;
  final LatLng userPosition;
  final ValueChanged<StationMapPin> onSelect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.near_me_rounded,
                        color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nearby Stations',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${nearby.length} closest to your location',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.45),
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: Icon(Icons.close_rounded,
                        color: cs.onSurface.withValues(alpha: 0.4), size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Divider(height: 1, color: cs.outline.withValues(alpha: 0.12)),

            // Station list
            ListView.separated(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 16),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: nearby.isEmpty ? 1 : nearby.length,
              separatorBuilder: (_, i) => Divider(
                height: 1,
                indent: 68,
                color: cs.outline.withValues(alpha: 0.1),
              ),
              itemBuilder: (context, i) {
                if (nearby.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No stations found near you',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                    ),
                  );
                }

                final pin = nearby[i];
                final isSuspended = pin.hasSuspension;
                final statusColor = isSuspended
                    ? AppColors.error
                    : pin.status == 'active'
                        ? AppColors.success
                        : AppColors.statusInactive;
                final statusLabel =
                    isSuspended ? 'Suspended' : pin.status;
                final distM = _metersTo(userPosition, LatLng(pin.lat, pin.lng));
                final distLabel = distM < 1000
                    ? '${distM.round()} m'
                    : '${(distM / 1000).toStringAsFixed(1)} km';

                return InkWell(
                  onTap: () => onSelect(pin),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        // Rank + color dot
                        SizedBox(
                          width: 36,
                          child: Column(
                            children: [
                              Text(
                                '${i + 1}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: cs.onSurface.withValues(alpha: 0.35),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pin.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.ev_station_rounded,
                                      size: 11,
                                      color:
                                          cs.onSurface.withValues(alpha: 0.4)),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${pin.activePumps} pump${pin.activePumps != 1 ? 's' : ''}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontSize: 11,
                                          color: cs.onSurface
                                              .withValues(alpha: 0.45),
                                        ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            fontSize: 9,
                                            color: statusColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Distance + chevron
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              distLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Icon(Icons.chevron_right_rounded,
                                size: 16,
                                color: cs.onSurface.withValues(alpha: 0.25)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
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
            Icon(Icons.map_outlined,
                size: 48, color: cs.onSurface.withValues(alpha: 0.3)),
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
