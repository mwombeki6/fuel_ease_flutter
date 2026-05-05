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
