import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/core/services/mapbox_geocoding_service.dart';
import 'package:fuel_ease_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fuel_ease_flutter/features/dashboard/presentation/providers/nearest_station_provider.dart';
import 'package:fuel_ease_flutter/features/dashboard/presentation/providers/pending_actions_provider.dart';
import 'package:fuel_ease_flutter/features/dashboard/presentation/widgets/header_wallet_chip.dart';
import 'package:fuel_ease_flutter/features/dashboard/presentation/widgets/station_sheet.dart';
import 'package:fuel_ease_flutter/features/stations/data/models/station_map_pin.dart';
import 'package:fuel_ease_flutter/features/stations/presentation/providers/station_map_provider.dart';
import 'package:fuel_ease_flutter/main.dart' show themeModeProvider;
import 'package:fuel_ease_flutter/shared/map/map_config.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';
import 'package:fuel_ease_flutter/shared/utils/app_snackbar.dart';
import 'package:fuel_ease_flutter/shared/widgets/fe_widgets.dart';

const _defaultCenter = LatLng(-6.7924, 39.2083);

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen — full-screen map-first customer experience ("Pump & Go")
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _mapController = MapController();
  final _searchController = TextEditingController();

  String _searchQuery = '';
  bool _locating = false;
  LatLng? _userPosition;
  StreamSubscription<Position>? _positionSub;
  List<GeocodingResult> _suggestions = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
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

  // Ported from the pre-rebuild home_screen.dart's `_initLocation` — same
  // Geolocator permission flow and position stream, now also writing the
  // resolved LatLng into `userLocationProvider` so
  // `nearestOrSelectedStationValueProvider` (and `StationSheet`, which
  // watches it) can resolve the nearest station.
  Future<void> _initLocation() async {
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final here = LatLng(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() => _userPosition = here);
        ref.read(userLocationProvider.notifier).state = here;
        _mapController.move(here, 13);
      }
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20,
        ),
      ).listen((p) {
        if (!mounted) return;
        final updated = LatLng(p.latitude, p.longitude);
        setState(() => _userPosition = updated);
        ref.read(userLocationProvider.notifier).state = updated;
      });
    } catch (_) {
      // Falls back to Dar es Salaam if location is unavailable.
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

  // Ported from the pre-rebuild home_screen.dart's `_selectPin` — same
  // haptic + camera-follow behavior, now writing the tapped station's id
  // into `nearestOrSelectedStationProvider` instead of local State so
  // `StationSheet` can pick it up.
  void _selectPin(StationMapPin pin) {
    HapticFeedback.mediumImpact();
    ref.read(nearestOrSelectedStationProvider.notifier).state = pin.id;
    _mapController.move(LatLng(pin.lat - 0.003, pin.lng), 14);
  }

  void _clearSelection() {
    ref.read(nearestOrSelectedStationProvider.notifier).state = null;
  }

  void _onSearchChanged(String query, List<StationMapPin> pins) {
    setState(() => _searchQuery = query);
    _debounce?.cancel();
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    // Immediate station auto-pan.
    final stationMatches = pins
        .where((p) =>
            p.name.toLowerCase().contains(query.toLowerCase()) ||
            p.region.toLowerCase().contains(query.toLowerCase()) ||
            p.district.toLowerCase().contains(query.toLowerCase()))
        .toList();
    if (stationMatches.length == 1) {
      _mapController.move(
        LatLng(stationMatches.first.lat, stationMatches.first.lng),
        14,
      );
    }
    // Debounced geocoding.
    _debounce = Timer(const Duration(milliseconds: 420), () async {
      final results = await MapboxGeocodingService.suggest(
        query,
        proximity: _userPosition,
      );
      if (mounted) setState(() => _suggestions = results);
    });
  }

  void _onSuggestionTap(GeocodingResult result) {
    HapticFeedback.selectionClick();
    _mapController.move(result.center, 13);
    setState(() {
      _suggestions = [];
      _searchQuery = '';
    });
    _searchController.clear();
    _debounce?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final themeMode = ref.watch(themeModeProvider);
    final pinsAsync = ref.watch(stationMapPinsProvider);
    final selectedStationId = ref.watch(nearestOrSelectedStationProvider);
    final pendingAction = ref.watch(pendingActionsProvider);

    ref.listen(stationMapPinsProvider, (_, next) {
      next.whenOrNull(error: (e, _) => AppSnackbar.fromError(context, e));
    });

    // One map style per theme (per spec — the day/night/satellite/fuelEase
    // MapStylePicker is removed from Home; MapStyle itself is kept since
    // station_map_screen.dart, out of scope here, still uses it).
    final isLightMap = themeMode == ThemeMode.light ||
        (themeMode == ThemeMode.system && brightness == Brightness.light);
    final mapStyle = isLightMap ? MapStyle.streets : MapStyle.night;

    final pins = pinsAsync.value ?? const <StationMapPin>[];
    final filtered = _searchQuery.isEmpty
        ? pins
        : pins
            .where((p) =>
                p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                p.region.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                p.district.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _HomeHeader(colorScheme: colorScheme),
            if (pendingAction != null)
              _PendingActionBanner(
                action: pendingAction,
                colorScheme: colorScheme,
              ),
            Expanded(
              child: Stack(
                children: [
                  _MapLayer(
                    mapController: _mapController,
                    markers: filtered
                        .map((p) => _buildStationMarker(
                              p,
                              selectedStationId == p.id,
                              colorScheme,
                              brightness,
                            ))
                        .toList(),
                    userPosition: _userPosition,
                    mapStyle: mapStyle,
                    onMapTap: () {
                      if (selectedStationId != null) _clearSelection();
                    },
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: _TopSearchBar(
                      searchController: _searchController,
                      searchQuery: _searchQuery,
                      onSearchChanged: (q) => _onSearchChanged(q, pins),
                    ),
                  ),
                  if (_suggestions.isNotEmpty)
                    Positioned(
                      top: 64,
                      left: 12,
                      right: 12,
                      child: _SuggestionsList(
                        suggestions: _suggestions,
                        onTap: _onSuggestionTap,
                      ),
                    ),
                  Positioned(
                    right: 12,
                    bottom: 172,
                    child: _LocationFab(
                      locating: _locating,
                      onTap: _goToMyLocation,
                    ),
                  ),
                  const Align(
                    alignment: Alignment.bottomCenter,
                    child: StationSheet(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Ported from the pre-rebuild home_screen.dart's `_buildNamedMarker`,
  // restyled per Section 1/4 of the redesign spec: markers now use exactly
  // four semantic states (available / selected / unavailable / cluster).
  // The old separate "live dispensing" pulse (`stationLiveActivityProvider`)
  // and the red "suspended" hue are dropped — the spec's Section 4 marker
  // semantics enumerate only those four states, and `StationSheet` (Task 7)
  // already collapses "suspended" and "inactive" into a single "Closed"
  // state, so pin coloring now mirrors that same simplification instead of
  // introducing a fifth un-scoped state.
  Marker _buildStationMarker(
    StationMapPin pin,
    bool isSelected,
    ColorScheme colorScheme,
    Brightness brightness,
  ) {
    final isUnavailable = pin.status != 'active' || pin.hasSuspension;
    final mutedColor = brightness == Brightness.dark
        ? AppColors.unavailableMarkerDark
        : AppColors.unavailableMarkerLight;
    // Light theme: available = evergreen (colorScheme.primary), selected =
    // brightGreen (colorScheme.secondary). Dark theme: brightGreenDark does
    // "double duty" for both per the design spec (evergreenDark is reserved,
    // not used on Home this delivery) — selection is shown via the
    // fill/border inversion below instead of a second hue.
    final selectedColor =
        brightness == Brightness.dark ? colorScheme.primary : colorScheme.secondary;
    final color = isUnavailable
        ? mutedColor
        : (isSelected ? selectedColor : colorScheme.primary);

    final name =
        pin.name.length > 18 ? '${pin.name.substring(0, 16)}…' : pin.name;
    final estWidth = (name.length * 7.2 + 50.0).clamp(70.0, 180.0);

    return Marker(
      point: LatLng(pin.lat, pin.lng),
      width: estWidth,
      height: 40,
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        onTap: () => _selectPin(pin),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : Colors.white.withValues(alpha: 0.3),
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isSelected ? 0.7 : 0.4),
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
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header — greeting/location on the left, wallet chip + profile on the right
// ─────────────────────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(child: _GreetingBlock()),
          Row(
            children: [
              const HeaderWalletChip(),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                // No notifications feed/screen exists anywhere in the app yet
                // (checked lib/core/routing/routes.dart, app_router.dart, and
                // lib/features/**): the only related UI is the private
                // `_NotificationsSheet` in profile_screen.dart, which is a
                // notification *preferences* toggle sheet, not a feed to
                // route to. Surface an honest placeholder instead of routing
                // to the wrong destination or inventing a new screen.
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No new notifications')),
                  );
                },
                tooltip: 'Notifications',
              ),
              IconButton(
                icon: const Icon(Icons.person_outline_rounded),
                onPressed: () => context.push(Routes.profile),
                tooltip: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GreetingBlock extends ConsumerWidget {
  const _GreetingBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    // Ported from the pre-rebuild home_screen.dart's `build()` (the
    // `firstName` expression watching `authProvider`, previously used only
    // for the search bar's hint text). Combined here with a time-of-day
    // greeting per the redesign spec ("Good evening, {firstName}").
    final authState = ref.watch(authProvider);
    final firstName = authState.maybeWhen(
      authenticated: (user) => user.firstName,
      orElse: () => '',
    );
    final hour = DateTime.now().hour;
    final timeOfDay = hour < 12
        ? 'morning'
        : hour < 17
            ? 'afternoon'
            : 'evening';
    final greetingText = firstName.isNotEmpty
        ? 'Good $timeOfDay, ${firstName.split(' ').first}'
        : 'Good $timeOfDay';

    // No area-name text: the current codebase has no reverse-geocoding of
    // the user's resolved LatLng into a place name — `MapboxGeocodingService`
    // only exposes forward search (`suggest`), and no other screen resolves
    // one either (checked `station_details_screen.dart`,
    // `station_map_screen.dart`). Rather than fabricate a heuristic (e.g.
    // showing the nearest station's district, which is not the same thing
    // as the user's own area), this is left null — the block below already
    // handles that by omitting the location row entirely.
    const String? areaNameText = null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (areaNameText != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_rounded,
                  size: 10, color: colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                areaNameText,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        Text(
          greetingText,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _PendingActionBanner extends StatelessWidget {
  const _PendingActionBanner({required this.action, required this.colorScheme});
  final PendingAction action;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => context.push(action.route),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.amberSurfaceDark : AppColors.amberSurface,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                action.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.amberTextDark : AppColors.amberText,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.push(action.route),
              child: const Text('View'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map layer (kept functionally as-is — FlutterMap + clustering + user dot)
// ─────────────────────────────────────────────────────────────────────────────

class _MapLayer extends StatelessWidget {
  const _MapLayer({
    required this.mapController,
    required this.markers,
    required this.onMapTap,
    required this.mapStyle,
    this.userPosition,
  });

  final MapController mapController;
  final List<Marker> markers;
  final VoidCallback onMapTap;
  final MapStyle mapStyle;
  final LatLng? userPosition;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: _defaultCenter,
        initialZoom: 7,
        minZoom: 5,
        maxZoom: 18,
        backgroundColor: mapStyle.mapBackground,
        onTap: (tapPos, point) => onMapTap(),
      ),
      children: [
        TileLayer(
          urlTemplate: mapStyle.tileUrl(),
          tileSize: 512,
          zoomOffset: -1,
          keepBuffer: 3,
          panBuffer: 1,
          userAgentPackageName: 'com.fuelease.app',
        ),
        // Clustered station markers — collapse to count badge below zoom 12.
        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            maxClusterRadius: 80,
            size: const Size(52, 52),
            alignment: Alignment.center,
            markers: markers,
            builder: (context, clusterMarkers) => StationClusterMarker(
              count: clusterMarkers.length,
            ),
          ),
        ),
        // User position — never clustered.
        if (userPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: userPosition!,
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: const UserLocationMarker(),
              ),
            ],
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating search bar — restyled: opaque surface + shadow, no glass blur
// ─────────────────────────────────────────────────────────────────────────────

class _TopSearchBar extends StatelessWidget {
  const _TopSearchBar({
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: AppColors.borderDark) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: colorScheme.onSurface.withValues(alpha: 0.4),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search stations, areas…',
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                searchController.clear();
                onSearchChanged('');
              },
              child: Icon(
                Icons.clear_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
                size: 18,
              ),
            ),
        ],
      ),
    )
        .animate()
        .slideY(begin: -1, end: 0, duration: 500.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 350.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Geocoding suggestions dropdown
// ─────────────────────────────────────────────────────────────────────────────

class _SuggestionsList extends StatelessWidget {
  const _SuggestionsList({required this.suggestions, required this.onTap});

  final List<GeocodingResult> suggestions;
  final ValueChanged<GeocodingResult> onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 6),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: suggestions.length,
          separatorBuilder: (ctx, i) => Divider(
            height: 1,
            indent: 48,
            color: colorScheme.outline.withValues(alpha: 0.15),
          ),
          itemBuilder: (context, i) {
            final r = suggestions[i];
            return ListTile(
              dense: true,
              leading: Icon(
                r.iconType == IconType.poi
                    ? Icons.place_rounded
                    : r.iconType == IconType.address
                        ? Icons.home_rounded
                        : Icons.location_city_rounded,
                color: colorScheme.primary,
                size: 18,
              ),
              title: Text(
                r.name,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: r.fullName.isNotEmpty
                  ? Text(
                      r.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    )
                  : null,
              onTap: () => onTap(r),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recenter control — restyled: opaque surface + shadow, no glass blur
// ─────────────────────────────────────────────────────────────────────────────

class _LocationFab extends StatelessWidget {
  const _LocationFab({required this.locating, required this.onTap});
  final bool locating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: locating ? null : onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: isDark ? Border.all(color: AppColors.borderDark) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: locating
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                )
              : Icon(
                  Icons.my_location_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
        ),
      ),
    );
  }
}
