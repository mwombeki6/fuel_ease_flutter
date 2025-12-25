import 'package:freezed_annotation/freezed_annotation.dart';

part 'recharge_payload.freezed.dart';
part 'recharge_payload.g.dart';

/// Wallet recharge request payload
@freezed
class RechargePayload with _$RechargePayload {
  const factory RechargePayload({
    required int amountTzs,
    required String msisdn,
    required String stationId,
    String? provider, // 'mpesa' or 'azampay'
  }) = _RechargePayload;

  factory RechargePayload.fromJson(Map<String, dynamic> json) =>
      _$RechargePayloadFromJson(json);
}

/// Wallet recharge response
@freezed
class RechargeResponse with _$RechargeResponse {
  const factory RechargeResponse({
    required String transactionId,
    required String status,
    String? message,
    String? reference,
  }) = _RechargeResponse;

  factory RechargeResponse.fromJson(Map<String, dynamic> json) =>
      _$RechargeResponseFromJson(json);
}
