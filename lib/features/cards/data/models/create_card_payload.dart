import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_card_payload.freezed.dart';
part 'create_card_payload.g.dart';

/// Payload for creating a new fuel card
@freezed
class CreateCardPayload with _$CreateCardPayload {
  const factory CreateCardPayload({
    required String stationId,
    required double units,
    required String pin,
    String? recipientName,
    String? recipientPhone,
    DateTime? expiresAt,
  }) = _CreateCardPayload;

  factory CreateCardPayload.fromJson(Map<String, dynamic> json) =>
      _$CreateCardPayloadFromJson(json);
}

/// Response after creating a fuel card
@freezed
class CreateCardResponse with _$CreateCardResponse {
  const factory CreateCardResponse({
    required String cardId,
    required String cardNumber,
    required String pin,
    required double units,
    String? qrCode,
    String? message,
  }) = _CreateCardResponse;

  factory CreateCardResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateCardResponseFromJson(json);
}

/// Payload for using a fuel card
@freezed
class UseCardPayload with _$UseCardPayload {
  const factory UseCardPayload({
    required String cardNumber,
    required String pin,
  }) = _UseCardPayload;

  factory UseCardPayload.fromJson(Map<String, dynamic> json) =>
      _$UseCardPayloadFromJson(json);
}
