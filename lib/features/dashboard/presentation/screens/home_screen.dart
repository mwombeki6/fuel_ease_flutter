import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import 'package:fuel_ease_flutter/core/providers/station_live_activity_provider.dart';
import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/core/services/mapbox_geocoding_service.dart';
import 'package:fuel_ease_flutter/main.dart' show themeModeProvider;
import 'package:fuel_ease_flutter/shared/map/map_config.dart';
import 'package:fuel_ease_flutter/core/realtime/realtime_client.dart';
import 'package:fuel_ease_flutter/core/realtime/realtime_status_provider.dart';
import 'package:fuel_ease_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fuel_ease_flutter/features/stations/data/models/station_map_pin.dart';
import 'package:fuel_ease_flutter/features/stations/presentation/providers/station_map_provider.dart';
import 'package:fuel_ease_flutter/features/wallet/data/models/wallet_summary.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/widgets/transaction_list_item.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';
import 'package:fuel_ease_flutter/shared/utils/app_snackbar.dart';
import 'package:fuel_ease_flutter/shared/widgets/fe_widgets.dart';

const _defaultCenter = LatLng(-6.7924, 39.2083);
const _distCalc = Distance();

double _metersTo(LatLng a, LatLng b) =>
    _distCalc.as(LengthUnit.Meter, a, b);

String _distanceLabel(LatLng from, LatLng to) {
  final m = _metersTo(from, to);
  return m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';
}

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen — map-first customer experience
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  final _sheetController = DraggableScrollableController();

  late final AnimationController _pinPanelCtrl;
  late final Animation<Offset> _pinPanelSlide;

  String _searchQuery = '';
  StationMapPin? _selectedPin;
  StationMapPin? _displayPin;
  bool _locating = false;
  bool _hasSeenConnected = false;
  LatLng? _userPosition;
  StreamSubscription<Position>? _positionSub;
  MapStyle _mapStyle = MapStyle.night;
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
    _pinPanelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _pinPanelSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _pinPanelCtrl, curve: Curves.easeOutCubic));
    // Clear display pin once the slide-out finishes
    _pinPanelCtrl.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && mounted) {
        setState(() => _displayPin = null);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocation());
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _debounce?.cancel();
    _mapController.dispose();
    _searchController.dispose();
    _sheetController.dispose();
    _pinPanelCtrl.dispose();
    super.dispose();
  }

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
        _mapController.move(here, 13);
      }
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20,
        ),
      ).listen((p) {
        if (mounted) {
          setState(() => _userPosition = LatLng(p.latitude, p.longitude));
        }
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

  void _selectPin(StationMapPin pin) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedPin = pin;
      _displayPin = pin;
    });
    _mapController.move(LatLng(pin.lat - 0.003, pin.lng), 14);
    _pinPanelCtrl.forward();
    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        0.30,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _clearPin() {
    setState(() => _selectedPin = null);
    _pinPanelCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final pinsAsync = ref.watch(stationMapPinsProvider);
    final liveStations = ref.watch(stationLiveActivityProvider);
    final walletState = ref.watch(walletProvider);
    final availableBalance = ref.watch(availableBalanceProvider);
    final authState = ref.watch(authProvider);
    final realtimeStatus = ref.watch(realtimeStatusProvider);

    ref.listen(walletProvider, (_, next) {
      next.whenOrNull(error: (e, _) => AppSnackbar.fromError(context, e));
    });

    ref.listen(stationMapPinsProvider, (_, next) {
      next.whenOrNull(error: (e, _) => AppSnackbar.fromError(context, e));
    });

    ref.listen<RealtimeStatus>(realtimeStatusProvider, (previous, next) {
      if (!mounted) return;
      if (!_hasSeenConnected &&
          next.state == RealtimeConnectionState.connected) {
        _hasSeenConnected = true;
        return;
      }
      if (previous == null) return;
      if ((previous.state == RealtimeConnectionState.reconnecting ||
              previous.state == RealtimeConnectionState.disconnected) &&
          next.state == RealtimeConnectionState.connected) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reconnected to live feed')),
        );
      }
    });

    final firstName = authState.maybeWhen(
      authenticated: (user) => user.firstName,
      orElse: () => '',
    );

    final deviceBottom = MediaQuery.of(context).padding.bottom;
    // Approximate bottom area taken by the floating nav pill
    final navArea = deviceBottom + 16.0 + 64.0 + 20.0;

    final pins = pinsAsync.value ?? [];
    final filtered = _searchQuery.isEmpty
        ? pins
        : pins
            .where((p) =>
                p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                p.region.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                p.district.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      body: Stack(
        children: [
          // ── Layer 1: Full-screen Mapbox dark map ──────────────────────────
          _MapLayer(
            mapController: _mapController,
            markers: filtered
                .map((p) => _buildNamedMarker(
                    p, _selectedPin?.id == p.id, liveStations.contains(p.id)))
                .toList(),
            liveStations: liveStations,
            userPosition: _userPosition,
            mapStyle: _mapStyle,
            onMapTap: () {
              if (_selectedPin != null) _clearPin();
            },
          ),

          // ── Layer 2: Glass top search bar ─────────────────────────────────
          _TopSearchBar(
            firstName: firstName,
            realtimeStatus: realtimeStatus,
            searchController: _searchController,
            searchQuery: _searchQuery,
            stationCount: filtered.length,
            onSearchChanged: (q) {
              setState(() => _searchQuery = q);
              _debounce?.cancel();
              if (q.isEmpty) {
                setState(() => _suggestions = []);
                return;
              }
              // Immediate station auto-pan.
              final stationMatches = pins
                  .where((p) =>
                      p.name.toLowerCase().contains(q.toLowerCase()) ||
                      p.region.toLowerCase().contains(q.toLowerCase()) ||
                      p.district.toLowerCase().contains(q.toLowerCase()))
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
                  q,
                  proximity: _userPosition,
                );
                if (mounted) setState(() => _suggestions = results);
              });
            },
          ),

          // ── Layer 3: Map style picker ─────────────────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 80, 16, 0),
                child: MapStylePicker(
                  current: _mapStyle,
                  onChanged: (s) => setState(() => _mapStyle = s),
                ),
              ),
            ),
          ),

          // ── Layer 4: Geocoding suggestions dropdown ───────────────────────
          if (_suggestions.isNotEmpty)
            SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 72), // clear the search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
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
                          itemCount: _suggestions.length,
                          separatorBuilder: (ctx, i) => Divider(
                            height: 1,
                            indent: 48,
                            color: Theme.of(ctx)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.15),
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
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.5)),
                                    )
                                  : null,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _mapController.move(r.center, 13);
                                setState(() {
                                  _suggestions = [];
                                  _searchQuery = '';
                                });
                                _searchController.clear();
                                _debounce?.cancel();
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Layer 5: My location FAB ──────────────────────────────────────
          Positioned(
            right: 16,
            bottom: navArea + 240,
            child: _LocationFab(locating: _locating, onTap: _goToMyLocation),
          ),

          // ── Layer 4: Wallet + dashboard draggable sheet ───────────────────
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.30,
            minChildSize: 0.14,
            maxChildSize: 0.88,
            snap: true,
            snapSizes: const [0.30, 0.60, 0.88],
            builder: (ctx, scrollController) => _DashboardSheet(
              scrollController: scrollController,
              balance: availableBalance,
              walletState: walletState,
              bottomPad: navArea,
              onTopUp: () => context.push(Routes.walletRecharge),
              onHistory: () => context.push(Routes.walletTransactions),
              onFuelUp: () => context.push(Routes.createDispensingRequest),
            ),
          ),

          // ── Layer 5: Station detail panel (animated slide-up) ─────────────
          if (_displayPin != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: _pinPanelSlide,
                child: _StationDetailPanel(
                  pin: _displayPin!,
                  distance: _userPosition != null
                      ? _distanceLabel(
                          _userPosition!,
                          LatLng(_displayPin!.lat, _displayPin!.lng),
                        )
                      : null,
                  onClose: _clearPin,
                  onFuelUp: () => context.push(
                    Routes.createDispensingRequest,
                    extra: _displayPin!.id,
                  ),
                  bottomPad: navArea,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Marker _buildNamedMarker(StationMapPin pin, bool isSelected, bool isLive) {
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
              if (isLive || pin.hasSuspension) ...[
                const SizedBox(width: 4),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isLive
                        ? (isSelected ? AppColors.success : Colors.white.withValues(alpha: 0.9))
                        : AppColors.error,
                    shape: BoxShape.circle,
                    boxShadow: isLive
                        ? [BoxShadow(color: AppColors.success, blurRadius: 4)]
                        : null,
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

// ─────────────────────────────────────────────────────────────────────────────
// Map layer (Mapbox dark tiles, fallback to OSM)
// ─────────────────────────────────────────────────────────────────────────────

class _MapLayer extends StatelessWidget {
  const _MapLayer({
    required this.mapController,
    required this.markers,
    required this.onMapTap,
    required this.mapStyle,
    required this.liveStations,
    this.userPosition,
  });

  final MapController mapController;
  final List<Marker> markers;
  final VoidCallback onMapTap;
  final MapStyle mapStyle;
  final Set<String> liveStations;
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
        // Clustered station markers — collapse to count badge below zoom 12
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
        // User position — never clustered
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
// Glass top search / greeting bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopSearchBar extends StatelessWidget {
  const _TopSearchBar({
    required this.firstName,
    required this.realtimeStatus,
    required this.searchController,
    required this.searchQuery,
    required this.stationCount,
    required this.onSearchChanged,
  });

  final String firstName;
  final RealtimeStatus realtimeStatus;
  final TextEditingController searchController;
  final String searchQuery;
  final int stationCount;
  final void Function(String) onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceDark.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    // Brand icon
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.local_gas_station_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Search input
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onChanged: onSearchChanged,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: searchQuery.isEmpty
                              ? (firstName.isNotEmpty
                                  ? 'Hi ${firstName.split(' ').first} — find a station'
                                  : 'Search stations…')
                              : null,
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.38),
                            fontSize: 14,
                          ),
                          suffixIcon: searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    searchController.clear();
                                    onSearchChanged('');
                                  },
                                  child: Icon(
                                    Icons.clear_rounded,
                                    color: Colors.white.withValues(alpha: 0.5),
                                    size: 18,
                                  ),
                                )
                              : Icon(
                                  Icons.search_rounded,
                                  color: Colors.white.withValues(alpha: 0.35),
                                  size: 18,
                                ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 6),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Realtime status dot
                    _RealtimeDot(status: realtimeStatus),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .slideY(
          begin: -1,
          end: 0,
          duration: 600.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(duration: 400.ms);
  }
}

class _RealtimeDot extends StatelessWidget {
  const _RealtimeDot({required this.status});
  final RealtimeStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status.state) {
      RealtimeConnectionState.connected => AppColors.success,
      RealtimeConnectionState.connecting ||
      RealtimeConnectionState.reconnecting =>
        AppColors.warning,
      RealtimeConnectionState.disconnected => AppColors.error,
    };
    return PulsingDot(color: color, size: 6, pulseSize: 16);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Location FAB (glass morphism square)
// ─────────────────────────────────────────────────────────────────────────────

class _LocationFab extends StatelessWidget {
  const _LocationFab({required this.locating, required this.onTap});
  final bool locating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: locating ? null : onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.surfaceDark.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.09),
                width: 1,
              ),
            ),
            child: Center(
              child: locating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.brand),
                      ),
                    )
                  : const Icon(
                      Icons.my_location_rounded,
                      color: AppColors.brand,
                      size: 20,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard draggable sheet
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardSheet extends StatelessWidget {
  const _DashboardSheet({
    required this.scrollController,
    required this.balance,
    required this.walletState,
    required this.bottomPad,
    required this.onTopUp,
    required this.onHistory,
    required this.onFuelUp,
  });

  final ScrollController scrollController;
  final double? balance;
  final AsyncValue<WalletSummary> walletState;
  final double bottomPad;
  final VoidCallback onTopUp;
  final VoidCallback onHistory;
  final VoidCallback onFuelUp;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.07),
                width: 1,
              ),
            ),
          ),
          child: CustomScrollView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Drag handle
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 10),
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Balance row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AVAILABLE BALANCE',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                walletState.isLoading
                                    ? const FeShimmer(
                                        child: ShimmerBox(
                                          width: 130,
                                          height: 30,
                                          radius: 8,
                                        ),
                                      )
                                    : AnimatedCounter(
                                        value: balance ?? 0,
                                        formatter: (v) =>
                                            'TZS ${NumberFormat('#,##0').format(v.toInt())}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                              ],
                            ),
                          ),
                          // Quick chips
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _QuickChip(
                                icon: Icons.add_rounded,
                                label: 'Top Up',
                                onTap: onTopUp,
                              ),
                              const SizedBox(height: 6),
                              _QuickChip(
                                icon: Icons.history_rounded,
                                label: 'History',
                                onTap: onHistory,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Fuel Up CTA
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GradientButton(
                        label: 'Fuel Up Now',
                        icon: Icons.local_gas_station_rounded,
                        onPressed: onFuelUp,
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Section header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SectionHeader(
                        title: 'Recent Transactions',
                        actionLabel: 'See all',
                        action: onHistory,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),

              // Transactions
              walletState.when(
                loading: () => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: FeShimmer(
                        child: ShimmerBox(width: null, height: 58, radius: 14),
                      ),
                    ),
                    childCount: 3,
                  ),
                ),
                error: (_, _) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                data: (summary) {
                  final txns =
                      (summary.recentTransactions ?? []).take(5).toList();
                  if (txns.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPad + 20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 40,
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No transactions yet',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final isLast = i == txns.length - 1;
                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                              12, 0, 12, isLast ? bottomPad + 20 : 0),
                          child: TransactionListItem(
                            transaction: txns[i],
                            onTap: () {},
                          ),
                        );
                      },
                      childCount: txns.length,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.brand, size: 13),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Station detail panel (slides up from bottom)
// ─────────────────────────────────────────────────────────────────────────────

class _StationDetailPanel extends StatelessWidget {
  const _StationDetailPanel({
    required this.pin,
    required this.onClose,
    required this.onFuelUp,
    required this.bottomPad,
    this.distance,
  });

  final StationMapPin pin;
  final VoidCallback onClose;
  final VoidCallback onFuelUp;
  final double bottomPad;
  final String? distance;

  @override
  Widget build(BuildContext context) {
    final isSuspended = pin.hasSuspension;
    final isActive = pin.status == 'active' && !isSuspended;
    final statusColor = isSuspended
        ? AppColors.error
        : pin.status == 'active'
            ? AppColors.success
            : AppColors.statusInactive;
    final statusLabel = isSuspended
        ? 'Suspended'
        : pin.status == 'active'
            ? 'Active'
            : 'Inactive';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad + 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevatedDark.withValues(alpha: 0.97),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle + close
              Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Station header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor.withValues(alpha: 0.25),
                          statusColor.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.local_gas_station_rounded,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pin.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        if (pin.district.isNotEmpty || pin.region.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              [pin.district, pin.region]
                                  .where((s) => s.isNotEmpty)
                                  .join(', '),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.48),
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  StatusBadge(label: statusLabel, color: statusColor),
                ],
              ),

              const SizedBox(height: 18),

              // Stats chips
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.ev_station_rounded,
                    label:
                        '${pin.activePumps} pump${pin.activePumps != 1 ? 's' : ''} active',
                    color: AppColors.brand,
                  ),
                  if (distance != null) ...[
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.near_me_rounded,
                      label: distance!,
                      color: AppColors.primary,
                    ),
                  ],
                  if (isSuspended) ...[
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.block_rounded,
                      label: 'Suspended',
                      color: AppColors.error,
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 22),

              // CTA
              GradientButton(
                label: isActive ? 'Fuel Up Here' : 'Station Unavailable',
                icon: isActive ? Icons.local_gas_station_rounded : null,
                onPressed: isActive ? onFuelUp : null,
                glow: isActive,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
