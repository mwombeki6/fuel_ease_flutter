import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/features/wallet/data/models/wallet_transaction.dart';
import 'package:fuel_ease_flutter/features/wallet/data/repositories/wallet_repository.dart';

/// Provider for wallet transactions with pagination
final walletTransactionsProvider = FutureProvider.family<
    List<WalletTransaction>,
    ({int limit, int offset})>((ref, params) async {
  final repository = ref.watch(walletRepositoryProvider);
  return await repository.getTransactions(
    limit: params.limit,
    offset: params.offset,
  );
});

/// Provider for recent transactions (last 20)
final recentTransactionsProvider =
    FutureProvider<List<WalletTransaction>>((ref) async {
  return ref.watch(
    walletTransactionsProvider((limit: 20, offset: 0)),
  ).value ?? [];
});
