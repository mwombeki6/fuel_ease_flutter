import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/features/stations/data/models/fuel_inventory_entry.dart';
import 'package:fuel_ease_flutter/features/stations/data/models/pump.dart';
import 'package:fuel_ease_flutter/features/stations/data/models/station.dart';
import 'package:fuel_ease_flutter/features/stations/data/repositories/stations_cache.dart';
import 'package:fuel_ease_flutter/features/stations/data/repositories/stations_repository.dart';

class StationDetailsController extends FamilyAsyncNotifier<Station, String> {
  late String _stationId;

  @override
  Future<Station> build(String stationId) async {
    _stationId = stationId;
    final repository = ref.read(stationsRepositoryProvider);
    final cache = ref.read(stationsCacheProvider);

    final cached = await cache.getStation(stationId);
    if (cached != null) {
      state = AsyncValue.data(cached.data);
    }

    try {
      final station = await repository.getStationById(stationId);
      await cache.setStation(station);
      return station;
    } catch (error, stackTrace) {
      if (cached != null) {
        return cached.data;
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(stationsRepositoryProvider);
      final cache = ref.read(stationsCacheProvider);
      final station = await repository.getStationById(_stationId);
      await cache.setStation(station);
      return station;
    });
  }
}

class StationInventoryController
    extends FamilyAsyncNotifier<List<FuelInventoryEntry>, String> {
  late String _stationId;

  @override
  Future<List<FuelInventoryEntry>> build(String stationId) async {
    _stationId = stationId;
    final repository = ref.read(stationsRepositoryProvider);
    final cache = ref.read(stationsCacheProvider);

    final cached = await cache.getInventory(stationId);
    if (cached != null) {
      state = AsyncValue.data(cached.data);
    }

    try {
      final inventory = await repository.getStationInventory(stationId);
      await cache.setInventory(stationId, inventory);
      return inventory;
    } catch (error, stackTrace) {
      if (cached != null) {
        return cached.data;
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(stationsRepositoryProvider);
      final cache = ref.read(stationsCacheProvider);
      final inventory = await repository.getStationInventory(_stationId);
      await cache.setInventory(_stationId, inventory);
      return inventory;
    });
  }
}

class StationPumpsController extends FamilyAsyncNotifier<List<Pump>, String> {
  late String _stationId;

  @override
  Future<List<Pump>> build(String stationId) async {
    _stationId = stationId;
    final repository = ref.read(stationsRepositoryProvider);
    final cache = ref.read(stationsCacheProvider);

    final cached = await cache.getPumps(stationId);
    if (cached != null) {
      state = AsyncValue.data(cached.data);
    }

    try {
      final pumps = await repository.getStationPumps(stationId);
      await cache.setPumps(stationId, pumps);
      return pumps;
    } catch (error, stackTrace) {
      if (cached != null) {
        return cached.data;
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(stationsRepositoryProvider);
      final cache = ref.read(stationsCacheProvider);
      final pumps = await repository.getStationPumps(_stationId);
      await cache.setPumps(_stationId, pumps);
      return pumps;
    });
  }
}

final stationDetailsProvider =
    AsyncNotifierProvider.family<StationDetailsController, Station, String>(
  StationDetailsController.new,
);

final stationInventoryProvider = AsyncNotifierProvider.family<
    StationInventoryController, List<FuelInventoryEntry>, String>(
  StationInventoryController.new,
);

final stationPumpsProvider =
    AsyncNotifierProvider.family<StationPumpsController, List<Pump>, String>(
  StationPumpsController.new,
);
