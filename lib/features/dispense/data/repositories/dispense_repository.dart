import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/core/api/api_client.dart';
import 'package:fuel_ease_flutter/core/api/api_error.dart';
import 'package:fuel_ease_flutter/features/dispense/data/models/create_dispense_response.dart';
import 'package:fuel_ease_flutter/features/dispense/data/models/dispense_request.dart';

class DispenseRepository {
  DispenseRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<CreateDispenseResponse> createRequest(
      CreateDispensePayload payload) async {
    try {
      final response =
          await _apiClient.post('/dispense', data: payload.toJson());
      _assertSuccess(response);
      return CreateDispenseResponse.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  Future<DispenseRequest> getRequest(String id) async {
    try {
      final response = await _apiClient.get('/dispense/$id');
      _assertSuccess(response);
      return DispenseRequest.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  Future<List<DispenseRequest>> getRequests() async {
    try {
      final response = await _apiClient.get('/dispense');
      _assertSuccess(response);
      final list = response.data['data'] as List? ?? [];
      return list
          .map((j) => DispenseRequest.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  Future<void> cancelRequest(String id) async {
    try {
      final response = await _apiClient.put('/dispense/$id/cancel');
      _assertSuccess(response);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  /// Resolves a device serial — scanned from the QR code shown on the pump's
  /// own screen — to the station and pump the customer is standing at.
  Future<DeviceQRInfo> lookupDeviceQR(String serial) async {
    try {
      final response = await _apiClient.get('/dispense/device-lookup/$serial');
      _assertSuccess(response);
      return DeviceQRInfo.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  void _assertSuccess(Response response) {
    if ((response.statusCode ?? 0) >= 300) {
      final data = response.data;
      final message = (data is Map)
          ? (data['error']?['message'] ?? data['message'] ?? 'Request failed')
          : 'Request failed';
      throw ApiError(message: message.toString());
    }
  }
}

final dispenseRepositoryProvider = Provider<DispenseRepository>((ref) {
  return DispenseRepository(ref.read(apiClientProvider));
});

class DeviceQRInfo {
  const DeviceQRInfo({
    required this.stationId,
    required this.stationName,
    required this.pumpId,
    required this.pumpNumber,
    required this.fuelType,
  });

  factory DeviceQRInfo.fromJson(Map<String, dynamic> json) => DeviceQRInfo(
        stationId: json['stationId'] as String,
        stationName: json['stationName'] as String,
        pumpId: json['pumpId'] as String,
        pumpNumber: json['pumpNumber'] as int?,
        fuelType: json['fuelType'] as String,
      );

  final String stationId;
  final String stationName;
  final String pumpId;
  final int? pumpNumber;
  final String fuelType;
}
