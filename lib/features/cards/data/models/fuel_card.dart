/// Fuel card model matching Go backend response schema.
class FuelCard {
  const FuelCard({
    required this.id,
    required this.companyId,
    required this.last4,
    required this.expiresAt,
    required this.status,
    required this.createdAt,
    this.cvv,
  });

  final String id;
  final String companyId;
  final String last4;
  final DateTime expiresAt;
  final String status; // pending | active | blocked | expired
  final DateTime createdAt;
  final String? cvv; // only present on the creation response, shown once

  factory FuelCard.fromJson(Map<String, dynamic> json) => FuelCard(
        id: json['id'] as String,
        companyId: json['company_id'] as String,
        last4: json['last4'] as String,
        expiresAt: DateTime.parse(json['expires_at'] as String),
        status: json['status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        cvv: json['cvv'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'last4': last4,
        'expires_at': expiresAt.toIso8601String(),
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  FuelCard copyWith({
    String? id,
    String? companyId,
    String? last4,
    DateTime? expiresAt,
    String? status,
    DateTime? createdAt,
    String? cvv,
  }) =>
      FuelCard(
        id: id ?? this.id,
        companyId: companyId ?? this.companyId,
        last4: last4 ?? this.last4,
        expiresAt: expiresAt ?? this.expiresAt,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        cvv: cvv ?? this.cvv,
      );

  // ── Compatibility getters for existing UI widgets ──

  String get maskedCardNumber => '****$last4';
  String get cardNumber => maskedCardNumber; // alias used by card_details_screen
  String get maskedPin => '****';
  double get units => 0.0; // card doesn't carry units in the Go model
  String? get stationName => null;
  String? get recipientName => null;
  String? get recipientPhone => null;
  DateTime? get usedAt => null;
  String? get usedBy => null;

  bool get isActive => status == 'active';
  bool get isUsed => false;
  bool get isCancelled => status == 'suspended';
  bool get isExpired {
    if (status == 'expired') return true;
    return DateTime.now().isAfter(expiresAt);
  }

  String get formattedStatus {
    switch (status) {
      case 'active':
        return 'Active';
      case 'pending':
        return 'Pending';
      case 'blocked':
        return 'Blocked';
      case 'expired':
        return 'Expired';
      default:
        return status.toUpperCase();
    }
  }

  int? get daysUntilExpiry {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return 0;
    return expiresAt.difference(now).inDays;
  }

  bool get isExpiringSoon {
    final days = daysUntilExpiry;
    return days != null && days > 0 && days <= 7;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FuelCard && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
