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
      _assertSuccess(response);
      final list = response.data['data'] as List? ?? [];
      return list
          .map((j) => Station.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  Future<Station> getStationById(String stationId) async {
    try {
      final response = await _apiClient.get('/stations/$stationId');
      _assertSuccess(response);
      return Station.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  /// Fuel inventory is not yet available in the Go backend — returns empty.
  Future<List<FuelInventoryEntry>> getStationInventory(String stationId) async {
    return [];
  }

  Future<List<Pump>> getStationPumps(String stationId) async {
    try {
      final response = await _apiClient.get('/stations/$stationId/pumps');
      _assertSuccess(response);
      final list = response.data['data'] as List? ?? [];
      return list
          .map((j) => Pump.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  void _assertSuccess(Response response) {
    final code = response.statusCode ?? 0;
    if (code >= 300) {
      final data = response.data as Map<String, dynamic>?;
      final msg =
          (data?['error'] as Map?)?['message'] as String? ?? 'Request failed';
      throw ApiError(message: msg, statusCode: code);
    }
  }
}

final stationsRepositoryProvider = Provider<StationsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StationsRepository(apiClient);
});
