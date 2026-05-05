import 'package:fuel_ease_flutter/features/dispense/data/models/dispense_request.dart';

class CreateDispenseResponse {
  const CreateDispenseResponse({
    required this.request,
    required this.pin,
    required this.qrPayload,
  });

  final DispenseRequest request;
  final String pin;       // 6-digit plain text, shown once
  final String qrPayload; // JSON string {"r":"uuid"} for QR rendering

  factory CreateDispenseResponse.fromJson(Map<String, dynamic> json) =>
      CreateDispenseResponse(
        request: DispenseRequest.fromJson(
            json['request'] as Map<String, dynamic>),
        pin: json['pin'] as String,
        qrPayload: json['qr_payload'] as String,
      );
}

class CreateDispensePayload {
  const CreateDispensePayload({
    required this.cardId,
    required this.stationId,
    required this.fuelType,
    required this.requestedLiters,
  });

  final String cardId;
  final String stationId;
  final String fuelType; // petrol | diesel | premium | gas
  final double requestedLiters;

  Map<String, dynamic> toJson() => {
        'card_id': cardId,
        'station_id': stationId,
        'fuel_type': fuelType,
        'requested_liters': requestedLiters,
      };
}
