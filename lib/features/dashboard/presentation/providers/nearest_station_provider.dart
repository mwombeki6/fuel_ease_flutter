import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:fuel_ease_flutter/features/stations/data/models/station_map_pin.dart';
import 'package:fuel_ease_flutter/features/stations/presentation/providers/station_map_provider.dart';

/// Resolved user location, set once geolocation succeeds. Null until then,
/// if permission was denied, or if location is otherwise unavailable —
/// consumers must handle the null case. The location-permission flow (see
/// `_HomeScreenState._initLocation` in `home_screen.dart`) is expected to
/// write into this provider once the redesigned Home screen adopts it;
/// this provider itself does not request permission or poll geolocator.
final userLocationProvider = StateProvider<LatLng?>((ref) => null);

/// Station ID the user explicitly tapped on the map this session.
/// Null means "no explicit selection — fall back to nearest."
final nearestOrSelectedStationProvider = StateProvider<String?>((ref) => null);

const _distanceCalculator = Distance();

double _metersBetween(LatLng a, LatLng b) =>
    _distanceCalculator.as(LengthUnit.Meter, a, b);

/// The station the Home station sheet should display: the user's tapped
/// pin if one is selected, otherwise the nearest pin to their resolved
/// location. Returns null if pins haven't loaded yet, or if location
/// hasn't resolved and nothing is explicitly selected — callers must
/// treat null as "not ready to render" rather than guessing a station.
final nearestOrSelectedStationValueProvider =
    Provider.autoDispose<StationMapPin?>((ref) {
  final pins = ref.watch(stationMapPinsProvider).valueOrNull;
  if (pins == null || pins.isEmpty) return null;

  final selectedId = ref.watch(nearestOrSelectedStationProvider);
  if (selectedId != null) {
    for (final pin in pins) {
      if (pin.id == selectedId) return pin;
    }
  }

  final userLocation = ref.watch(userLocationProvider);
  if (userLocation == null) return null;

  StationMapPin? nearest;
  double? nearestDistance;
  for (final pin in pins) {
    final distance = _metersBetween(userLocation, LatLng(pin.lat, pin.lng));
    if (nearestDistance == null || distance < nearestDistance) {
      nearest = pin;
      nearestDistance = distance;
    }
  }
  return nearest;
});
