import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'package:fuel_ease_flutter/features/cards/data/models/create_card_payload.dart';
import 'package:fuel_ease_flutter/features/cards/data/models/fuel_card.dart';
import 'package:fuel_ease_flutter/features/cards/data/repositories/cards_repository.dart';

class CardsNotifier extends AsyncNotifier<List<FuelCard>> {
  final Logger _logger = Logger();

  @override
  Future<List<FuelCard>> build() async => _fetchCards();

  Future<List<FuelCard>> _fetchCards() async {
    return ref.read(cardsRepositoryProvider).getCards();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchCards);
  }

  Future<CreateCardResponse> createCard({
    required String companyId,
    DateTime? expiresAt,
  }) async {
    final payload = CreateCardPayload(
      companyId: companyId,
      expiresAt: expiresAt ?? DateTime.now().add(const Duration(days: 365)),
    );
    final response =
        await ref.read(cardsRepositoryProvider).createCard(payload);
    await refresh();
    _logger.i('Card created: ${response.card.last4}');
    return response;
  }

  Future<void> cancelCard(String cardId) async {
    await ref.read(cardsRepositoryProvider).cancelCard(cardId);
    await refresh();
    _logger.i('Card cancelled: $cardId');
  }
}

final cardsProvider =
    AsyncNotifierProvider<CardsNotifier, List<FuelCard>>(CardsNotifier.new);

final cardByIdProvider =
    FutureProvider.autoDispose.family<FuelCard, String>((ref, cardId) async {
  return ref.read(cardsRepositoryProvider).getCardById(cardId);
});

final activeCardsCountProvider = Provider<int>((ref) {
  final cardsState = ref.watch(cardsProvider);
  return cardsState.whenOrNull(
        data: (cards) => cards.where((c) => c.isActive).length,
      ) ??
      0;
});

/// Returns 0.0 — cards no longer carry a unit balance in the Go model.
final totalCardsValueProvider = Provider<double>((ref) => 0.0);
