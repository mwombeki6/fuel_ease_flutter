import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet.freezed.dart';
part 'wallet.g.dart';

/// Wallet model representing customer wallet
@freezed
class Wallet with _$Wallet {
  const factory Wallet({
    required String id,
    required String customerId,
    required double balanceUnits,
    required double reservedUnits,
    required String status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Wallet;

  factory Wallet.fromJson(Map<String, dynamic> json) => _$WalletFromJson(json);

  const Wallet._();

  /// Get available balance (balance - reserved)
  double get availableBalance => balanceUnits - reservedUnits;

  /// Check if wallet is active
  bool get isActive => status == 'active';

  /// Check if wallet is suspended
  bool get isSuspended => status == 'suspended';

  /// Check if wallet has sufficient balance
  bool hasSufficientBalance(double requiredUnits) {
    return availableBalance >= requiredUnits;
  }
}
