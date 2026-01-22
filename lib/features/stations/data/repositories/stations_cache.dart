import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/core/storage/app_cache.dart';
import 'package:fuel_ease_flutter/features/stations/data/models/fuel_inventory_entry.dart';
import 'package:fuel_ease_flutter/features/stations/data/models/pump.dart';
import 'package:fuel_ease_flutter/features/stations/data/models/station.dart';

class StationsCache {
  StationsCache(this._cache);

  final AppCache _cache;

  static const String _stationsKey = 'stations.list.v1';

  String _stationKey(String stationId) => 'stations.$stationId.detail.v1';

  String _pumpsKey(String stationId) => 'stations.$stationId.pumps.v1';

  String _inventoryKey(String stationId) => 'stations.$stationId.inventory.v1';

  Future<CacheEntry<List<Station>>?> getStations() async {
    return _cache.get<List<Station>>(_stationsKey, (json) {
      final list = (json as List<dynamic>? ?? []);
      return list
          .map((entry) =>
              Station.fromJson(Map<String, dynamic>.from(entry as Map)))
          .toList();
    });
  }

  Future<void> setStations(List<Station> stations) async {
    final data = stations.map((station) => station.toJson()).toList();
    await _cache.set(_stationsKey, data);
  }

  Future<CacheEntry<Station>?> getStation(String stationId) async {
    return _cache.get<Station>(_stationKey(stationId), (json) {
      return Station.fromJson(Map<String, dynamic>.from(json as Map));
    });
  }

  Future<void> setStation(Station station) async {
    await _cache.set(_stationKey(station.id), station.toJson());
  }

  Future<CacheEntry<List<Pump>>?> getPumps(String stationId) async {
    return _cache.get<List<Pump>>(_pumpsKey(stationId), (json) {
      final list = (json as List<dynamic>? ?? []);
      return list
          .map((entry) => Pump.fromJson(Map<String, dynamic>.from(entry as Map)))
          .toList();
    });
  }

  Future<void> setPumps(String stationId, List<Pump> pumps) async {
    final data = pumps.map((pump) => pump.toJson()).toList();
    await _cache.set(_pumpsKey(stationId), data);
  }

  Future<CacheEntry<List<FuelInventoryEntry>>?> getInventory(
    String stationId,
  ) async {
    return _cache.get<List<FuelInventoryEntry>>(_inventoryKey(stationId),
        (json) {
      final list = (json as List<dynamic>? ?? []);
      return list
          .map((entry) => FuelInventoryEntry.fromJson(
              Map<String, dynamic>.from(entry as Map)))
          .toList();
    });
  }

  Future<void> setInventory(
    String stationId,
    List<FuelInventoryEntry> inventory,
  ) async {
    final data = inventory.map((entry) => entry.toJson()).toList();
    await _cache.set(_inventoryKey(stationId), data);
  }
}

final stationsCacheProvider = Provider<StationsCache>((ref) {
  final cache = AppCache();
  return StationsCache(cache);
});
