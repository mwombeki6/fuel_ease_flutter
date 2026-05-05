/// Wallet transaction model matching Go backend response schema.
class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amountTzs,
    required this.balanceAfterTzs,
    this.refId,
    this.description,
    this.createdAt,
  });

  final String id;
  final String walletId;
  final String type; // credit | debit
  final int amountTzs;
  final int balanceAfterTzs;
  final String? refId;
  final String? description;
  final DateTime? createdAt;

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      WalletTransaction(
        id: json['id'] as String,
        walletId: json['wallet_id'] as String,
        type: json['type'] as String,
        amountTzs: (json['amount_tzs'] as num).toInt(),
        balanceAfterTzs: (json['balance_after_tzs'] as num?)?.toInt() ?? 0,
        refId: json['ref_id'] as String?,
        description: json['description'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  String? get reference => refId;

  bool get isCredit => type == 'credit';
  bool get isDebit => type == 'debit';

  String get formattedType {
    switch (type) {
      case 'credit':
        return 'Top-up';
      case 'debit':
        return 'Fuel Purchase';
      case 'refund':
        return 'Refund';
      default:
        return type.toUpperCase();
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is WalletTransaction && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
