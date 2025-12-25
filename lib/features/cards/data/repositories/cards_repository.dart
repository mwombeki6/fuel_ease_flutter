import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/core/api/api_client.dart';
import 'package:fuel_ease_flutter/features/cards/data/models/fuel_card.dart';
import 'package:fuel_ease_flutter/features/cards/data/models/create_card_payload.dart';

/// Repository for fuel cards operations
class CardsRepository {
  CardsRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Get all fuel cards for current user
  Future<List<FuelCard>> getCards() async {
    final response = await _apiClient.get('/fuel-cards/me');
    final List<dynamic> data = response.data['cards'] ?? [];
    return data.map((json) => FuelCard.fromJson(json)).toList();
  }

  /// Get card by ID
  Future<FuelCard> getCardById(String cardId) async {
    final response = await _apiClient.get('/fuel-cards/$cardId');
    return FuelCard.fromJson(response.data['card']);
  }

  /// Create a new fuel card
  Future<CreateCardResponse> createCard(CreateCardPayload payload) async {
    final response = await _apiClient.post(
      '/fuel-cards',
      data: payload.toJson(),
    );
    return CreateCardResponse.fromJson(response.data);
  }

  /// Cancel a fuel card
  Future<void> cancelCard(String cardId) async {
    await _apiClient.delete('/fuel-cards/$cardId');
  }

  /// Use/redeem a fuel card
  Future<FuelCard> useCard(UseCardPayload payload) async {
    final response = await _apiClient.post(
      '/fuel-cards/use',
      data: payload.toJson(),
    );
    return FuelCard.fromJson(response.data['card']);
  }

  /// Share card details (get shareable link/QR)
  Future<Map<String, dynamic>> shareCard(String cardId) async {
    final response = await _apiClient.get('/fuel-cards/$cardId/share');
    return response.data;
  }
}

/// Provider for cards repository
final cardsRepositoryProvider = Provider<CardsRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return CardsRepository(apiClient);
});
