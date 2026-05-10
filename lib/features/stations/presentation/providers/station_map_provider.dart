import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/features/stations/data/models/station_map_pin.dart';
import 'package:fuel_ease_flutter/features/stations/data/repositories/stations_repository.dart';

final stationMapPinsProvider =
    FutureProvider.autoDispose<List<StationMapPin>>((ref) async {
  return ref.watch(stationsRepositoryProvider).getStationMapPins();
});
