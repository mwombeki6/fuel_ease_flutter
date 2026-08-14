class DispenseRequest {
  const DispenseRequest({
    required this.id,
    required this.cardId,
    required this.stationId,
    required this.requestedLiters,
    required this.pricePerLiterTzs,
    required this.status,
    required this.createdAt,
    this.pumpId,
    this.actualLiters,
    this.completedAt,
    this.holdId,
  });

  final String id;
  final String cardId;
  final String stationId;
  final double requestedLiters;
  final int pricePerLiterTzs;
  final String status; // pending | approved | active | completed | cancelled
  final DateTime createdAt;
  final String? pumpId;
  final double? actualLiters;
  final DateTime? completedAt;
  final String? holdId;

  factory DispenseRequest.fromJson(Map<String, dynamic> json) =>
      DispenseRequest(
        id: json['id'] as String,
        cardId: json['card_id'] as String,
        stationId: json['station_id'] as String,
        requestedLiters:
            double.tryParse(json['requested_liters']?.toString() ?? '0') ?? 0.0,
        pricePerLiterTzs: (json['price_per_liter_tzs'] as num?)?.toInt() ?? 0,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        pumpId: json['pump_id'] as String?,
        actualLiters: json['actual_liters'] != null
            ? double.tryParse(json['actual_liters'].toString())
            : null,
        completedAt: json['completed_at'] != null
            ? DateTime.tryParse(json['completed_at'] as String)
            : null,
        holdId: json['wallet_hold_id'] as String?,
      );

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isRejected => status == 'rejected';
  bool get isExpired => status == 'expired';
  bool get isTerminal => isCompleted || isCancelled || isRejected || isExpired;

  int get estimatedCostTzs => (requestedLiters * pricePerLiterTzs).ceil();

  String get formattedStatus {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      case 'expired':
        return 'Expired';
      default:
        return status.toUpperCase();
    }
  }
}
