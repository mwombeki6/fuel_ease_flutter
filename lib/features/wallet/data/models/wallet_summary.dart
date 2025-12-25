import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:fuel_ease_flutter/features/wallet/data/models/wallet.dart';
import 'package:fuel_ease_flutter/features/wallet/data/models/wallet_transaction.dart';
import 'package:fuel_ease_flutter/features/wallet/data/models/fuel_session.dart';

part 'wallet_summary.freezed.dart';
part 'wallet_summary.g.dart';

/// Wallet summary with additional metadata
@freezed
class WalletSummary with _$WalletSummary {
  const factory WalletSummary({
    required Wallet wallet,
    int? totalTransactions,
    double? totalSpent,
    double? totalRecharged,
    List<WalletTransaction>? recentTransactions,
    List<FuelSession>? activeSessions,
  }) = _WalletSummary;

  factory WalletSummary.fromJson(Map<String, dynamic> json) =>
      _$WalletSummaryFromJson(json);
}
