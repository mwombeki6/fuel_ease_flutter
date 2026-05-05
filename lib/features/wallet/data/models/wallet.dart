/// Wallet model matching Go backend response schema.
class Wallet {
  const Wallet({
    required this.id,
    required this.balanceTzs,
    required this.status,
    required this.updatedAt,
  });

  final String id;
  final int balanceTzs; // balance in Tanzanian Shillings
  final String status; // active | suspended
  final DateTime updatedAt;

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
        id: json['id'] as String,
        balanceTzs: (json['balance_tzs'] as num).toInt(),
        status: json['status'] as String,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'balance_tzs': balanceTzs,
        'status': status,
        'updated_at': updatedAt.toIso8601String(),
      };

  // ── Compatibility getters for existing UI widgets ──

  double get balanceUnits => balanceTzs.toDouble();
  double get reservedUnits => 0.0;
  double get availableBalance => balanceTzs.toDouble();

  bool get isActive => status == 'active';
  bool get isSuspended => status == 'suspended';
  bool hasSufficientBalance(int required) => balanceTzs >= required;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Wallet && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
