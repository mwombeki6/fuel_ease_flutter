import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'package:fuel_ease_flutter/features/cards/data/models/fuel_card.dart';
import 'package:fuel_ease_flutter/features/cards/data/models/create_card_payload.dart';
import 'package:fuel_ease_flutter/features/cards/data/repositories/cards_repository.dart';

/// AsyncNotifier for managing fuel cards state
class CardsNotifier extends AsyncNotifier<List<FuelCard>> {
  final Logger _logger = Logger();

  @override
  Future<List<FuelCard>> build() async {
    // Auto-fetch cards on mount
    return _fetchCards();
  }

  Future<List<FuelCard>> _fetchCards() async {
    final repository = ref.read(cardsRepositoryProvider);
    return await repository.getCards();
  }

  /// Refresh cards list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchCards());
  }

  /// Create a new fuel card
  Future<CreateCardResponse> createCard({
    required String stationId,
    required double units,
    required String pin,
    String? recipientName,
    String? recipientPhone,
    DateTime? expiresAt,
  }) async {
    try {
      final repository = ref.read(cardsRepositoryProvider);
      final payload = CreateCardPayload(
        stationId: stationId,
        units: units,
        pin: pin,
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        expiresAt: expiresAt,
      );

      final response = await repository.createCard(payload);

      // Refresh cards list after creating
      await refresh();

      _logger.i('Card created successfully: ${response.cardNumber}');
      return response;
    } catch (e) {
      _logger.e('Card creation failed', error: e);
      rethrow;
    }
  }

  /// Cancel a fuel card
  Future<void> cancelCard(String cardId) async {
    try {
      final repository = ref.read(cardsRepositoryProvider);
      await repository.cancelCard(cardId);

      // Refresh cards list after cancelling
      await refresh();

      _logger.i('Card cancelled successfully: $cardId');
    } catch (e) {
      _logger.e('Card cancellation failed', error: e);
      rethrow;
    }
  }
}

/// Provider for fuel cards list
final cardsProvider = AsyncNotifierProvider<CardsNotifier, List<FuelCard>>(() {
  return CardsNotifier();
});

/// Provider for a single card by ID
final cardByIdProvider =
    FutureProvider.autoDispose.family<FuelCard, String>((ref, cardId) async {
  final repository = ref.read(cardsRepositoryProvider);
  return await repository.getCardById(cardId);
});

/// Convenience provider for active cards count
final activeCardsCountProvider = Provider<int>((ref) {
  final cardsState = ref.watch(cardsProvider);
  return cardsState.whenOrNull(
        data: (cards) => cards.where((c) => c.isActive).length,
      ) ??
      0;
});

/// Convenience provider for total cards value
final totalCardsValueProvider = Provider<double>((ref) {
  final cardsState = ref.watch(cardsProvider);
  return cardsState.whenOrNull(
        data: (cards) => cards
            .where((c) => c.isActive)
            .fold<double>(0.0, (sum, c) => sum + c.units),
      ) ??
      0.0;
});
