import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:fuel_ease_flutter/features/dashboard/presentation/providers/nearest_station_provider.dart';
import 'package:fuel_ease_flutter/features/stations/data/models/station_map_pin.dart';
import 'package:fuel_ease_flutter/features/stations/presentation/providers/station_map_provider.dart';

StationMapPin _pin(String id, double lat, double lng) => StationMapPin(
      id: id,
      name: 'Station $id',
      lat: lat,
      lng: lng,
      status: 'active',
      region: 'Dar es Salaam',
      district: 'Kinondoni',
      activePumps: 4,
      hasSuspension: false,
    );

void main() {
  final userLocation = const LatLng(-6.7924, 39.2083);
  final near = _pin('near', -6.7930, 39.2090); // ~0.1km away
  final far = _pin('far', -6.9000, 39.3000); // ~15km away

  test('resolves to the nearest pin when nothing is selected', () async {
    final container = ProviderContainer(
      overrides: [
        stationMapPinsProvider.overrideWith((ref) async => [far, near]),
        userLocationProvider.overrideWith((ref) => userLocation),
      ],
    );
    addTearDown(container.dispose);

    // Let the overridden FutureProvider resolve before reading the
    // derived provider that depends on its value.
    await container.read(stationMapPinsProvider.future);

    final result = container.read(nearestOrSelectedStationValueProvider);
    expect(result?.id, 'near');
  });

  test('resolves to the selected pin even if a nearer one exists', () async {
    final container = ProviderContainer(
      overrides: [
        stationMapPinsProvider.overrideWith((ref) async => [far, near]),
        userLocationProvider.overrideWith((ref) => userLocation),
      ],
    );
    addTearDown(container.dispose);

    await container.read(stationMapPinsProvider.future);
    container.read(nearestOrSelectedStationProvider.notifier).state = 'far';

    final result = container.read(nearestOrSelectedStationValueProvider);
    expect(result?.id, 'far');
  });

  test('returns null when the station list has not loaded yet', () {
    final container = ProviderContainer(
      overrides: [
        stationMapPinsProvider.overrideWith(
          (ref) => Completer<List<StationMapPin>>().future,
        ),
        userLocationProvider.overrideWith((ref) => userLocation),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(nearestOrSelectedStationValueProvider), isNull);
  });

  test(
      'falls back to the first loaded pin when user location is unresolved '
      'and nothing is selected', () async {
    final container = ProviderContainer(
      overrides: [
        stationMapPinsProvider.overrideWith((ref) async => [far, near]),
      ],
    );
    addTearDown(container.dispose);

    await container.read(stationMapPinsProvider.future);

    final result = container.read(nearestOrSelectedStationValueProvider);
    expect(result?.id, 'far');
  });
}
