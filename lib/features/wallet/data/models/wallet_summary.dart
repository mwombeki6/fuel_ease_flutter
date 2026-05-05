import 'package:fuel_ease_flutter/features/wallet/data/models/wallet.dart';
import 'package:fuel_ease_flutter/features/wallet/data/models/wallet_transaction.dart';

/// Simplified wallet summary — wraps Wallet for use in providers/screens.
class WalletSummary {
  const WalletSummary({
    required this.wallet,
    this.recentTransactions,
  });

  final Wallet wallet;
  final List<WalletTransaction>? recentTransactions;
}
