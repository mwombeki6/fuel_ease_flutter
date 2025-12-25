import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_transaction.freezed.dart';
part 'wallet_transaction.g.dart';

/// Wallet transaction model for ledger entries
@freezed
class WalletTransaction with _$WalletTransaction {
  const factory WalletTransaction({
    required String id,
    required String walletId,
    required String type,
    required double units,
    required double balanceAfter,
    String? reference,
    String? description,
    DateTime? createdAt,
  }) = _WalletTransaction;

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      _$WalletTransactionFromJson(json);

  const WalletTransaction._();

  /// Check if transaction is a credit (adding funds)
  bool get isCredit => type == 'credit' || type == 'recharge';

  /// Check if transaction is a debit (using funds)
  bool get isDebit => type == 'debit' || type == 'purchase';

  /// Get formatted transaction type
  String get formattedType {
    switch (type) {
      case 'credit':
      case 'recharge':
        return 'Top-up';
      case 'debit':
      case 'purchase':
        return 'Fuel Purchase';
      case 'refund':
        return 'Refund';
      case 'adjustment':
        return 'Adjustment';
      default:
        return type.toUpperCase();
    }
  }
}
