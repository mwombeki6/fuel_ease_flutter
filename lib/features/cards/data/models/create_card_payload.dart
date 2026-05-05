import 'package:fuel_ease_flutter/features/cards/data/models/fuel_card.dart';

/// Payload for creating a new fuel card.
class CreateCardPayload {
  const CreateCardPayload({
    required this.companyId,
    required this.expiresAt,
  });

  final String companyId;
  final DateTime expiresAt;

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'expires_at': expiresAt.toIso8601String(),
      };
}

/// Response after creating a fuel card — includes the one-time CVV.
class CreateCardResponse {
  const CreateCardResponse({required this.card});

  final FuelCard card;

  factory CreateCardResponse.fromJson(Map<String, dynamic> json) =>
      CreateCardResponse(card: FuelCard.fromJson(json));
}
