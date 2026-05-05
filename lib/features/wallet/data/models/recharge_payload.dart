/// Top-up (recharge) request payload matching the Go backend.
class TopUpPayload {
  const TopUpPayload({
    required this.amountTzs,
    required this.msisdn,
    required this.provider,
  });

  final int amountTzs;
  final String msisdn;
  final String provider; // 'Mpesa' | 'Tigopesa' | 'Airtel' | 'Halopesa'

  Map<String, dynamic> toJson() => {
        'amount_tzs': amountTzs,
        'msisdn': msisdn,
        'provider': provider,
      };
}

/// Alias kept for backward compatibility with existing provider code.
typedef RechargePayload = TopUpPayload;

/// Response after initiating a wallet top-up.
class TopUpResponse {
  const TopUpResponse({
    required this.topupId,
    required this.status,
    this.message,
  });

  final String topupId;
  final String status; // pending
  final String? message;

  factory TopUpResponse.fromJson(Map<String, dynamic> json) => TopUpResponse(
        topupId: json['topup_id'] as String? ?? json['id'] as String,
        status: json['status'] as String,
        message: json['message'] as String?,
      );
}

/// Alias kept for backward compatibility.
typedef RechargeResponse = TopUpResponse;
