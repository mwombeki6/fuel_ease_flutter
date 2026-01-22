import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/core/api/api_client.dart';
import 'package:fuel_ease_flutter/core/api/api_error.dart';
import 'package:fuel_ease_flutter/features/stations/data/models/station.dart';
import 'package:fuel_ease_flutter/features/stations/data/models/fuel_inventory_entry.dart';
import 'package:fuel_ease_flutter/features/stations/data/models/pump.dart';

class StationsRepository {
  StationsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Station>> getStations() async {
    try {
      final response = await _apiClient.get('/stations');

      if (response.data['status'] == 'success') {
        final data = response.data['data'] as Map<String, dynamic>? ?? {};
        final List<dynamic> stationsData =
            (data['stations'] as List<dynamic>?) ?? [];
        return stationsData
            .map((json) =>
                Station.fromJson(Map<String, dynamic>.from(json as Map)))
            .toList();
      }

      throw ApiError(
        message: response.data['message'] ?? 'Failed to fetch stations',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      if (e.error is ApiError) {
        rethrow;
      }
      throw ApiError.fromDioException(e);
    }
  }

  Future<Station> getStationById(String stationId) async {
    try {
      final response = await _apiClient.get('/stations/$stationId');

      if (response.data['status'] == 'success') {
        final data = response.data['data'] as Map<String, dynamic>? ?? {};
        final station = data['station'] as Map<String, dynamic>? ?? {};
        return Station.fromJson(Map<String, dynamic>.from(station));
      }

      throw ApiError(
        message: response.data['message'] ?? 'Failed to fetch station',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      if (e.error is ApiError) {
        rethrow;
      }
      throw ApiError.fromDioException(e);
    }
  }

  Future<List<FuelInventoryEntry>> getStationInventory(
    String stationId,
  ) async {
    try {
      final response = await _apiClient.get('/stations/$stationId/fuel-inventory');

      if (response.data['status'] == 'success') {
        final data = response.data['data'] as Map<String, dynamic>? ?? {};
        final inventory =
            (data['fuelInventory'] as Map<String, dynamic>? ?? {});

        return inventory.entries.map((entry) {
          final detail = Map<String, dynamic>.from(entry.value as Map);
          return FuelInventoryEntry(
            fuelType: entry.key,
            currentLevel: (detail['currentLevel'] as num?)?.toDouble() ?? 0,
            capacity: (detail['capacity'] as num?)?.toDouble() ?? 0,
            lowLevelAlert: (detail['lowLevelAlert'] as num?)?.toDouble(),
            lastRefill: detail['lastRefill'] as String?,
          );
        }).toList();
      }

      throw ApiError(
        message: response.data['message'] ?? 'Failed to fetch inventory',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      if (e.error is ApiError) {
        rethrow;
      }
      throw ApiError.fromDioException(e);
    }
  }

  Future<List<Pump>> getStationPumps(String stationId) async {
    try {
      final response = await _apiClient.get('/pumps/station/$stationId');

      if (response.data['status'] == 'success') {
        final List<dynamic> pumpsData =
            (response.data['data'] as List<dynamic>? ?? []);
        return pumpsData
            .map((json) => Pump.fromJson(Map<String, dynamic>.from(json as Map)))
            .toList();
      }

      throw ApiError(
        message: response.data['message'] ?? 'Failed to fetch pumps',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      if (e.error is ApiError) {
        rethrow;
      }
      throw ApiError.fromDioException(e);
    }
  }
}

final stationsRepositoryProvider = Provider<StationsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StationsRepository(apiClient);
});
