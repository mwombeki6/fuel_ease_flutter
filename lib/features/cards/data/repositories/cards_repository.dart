import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/core/api/api_client.dart';
import 'package:fuel_ease_flutter/core/api/api_error.dart';
import 'package:fuel_ease_flutter/features/cards/data/models/create_card_payload.dart';
import 'package:fuel_ease_flutter/features/cards/data/models/fuel_card.dart';

/// Repository for fuel card operations against the Go backend.
class CardsRepository {
  CardsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<FuelCard>> getCards() async {
    try {
      final response = await _apiClient.get('/cards');
      _assertSuccess(response);
      final list = response.data['data'] as List? ?? [];
      return list
          .map((j) => FuelCard.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  Future<FuelCard> getCardById(String cardId) async {
    try {
      final response = await _apiClient.get('/cards/$cardId');
      _assertSuccess(response);
      return FuelCard.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  Future<CreateCardResponse> createCard(CreateCardPayload payload) async {
    try {
      final response = await _apiClient.post('/cards', data: payload.toJson());
      _assertSuccess(response);
      return CreateCardResponse.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  Future<void> cancelCard(String cardId) async {
    try {
      final response = await _apiClient.put(
        '/cards/$cardId/status',
        data: {'status': 'suspended'},
      );
      _assertSuccess(response);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  /// Returns all fuel companies (public endpoint, no auth required).
  Future<List<Map<String, dynamic>>> getCompanies() async {
    try {
      final response = await _apiClient.get('/companies');
      _assertSuccess(response);
      final list = response.data['data'] as List? ?? [];
      return list.cast<Map<String, dynamic>>();
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

final cardsRepositoryProvider = Provider<CardsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CardsRepository(apiClient);
});
