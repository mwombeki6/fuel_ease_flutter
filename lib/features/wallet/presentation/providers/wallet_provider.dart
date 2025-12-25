import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'package:fuel_ease_flutter/features/wallet/data/models/recharge_payload.dart';
import 'package:fuel_ease_flutter/features/wallet/data/models/wallet_summary.dart';
import 'package:fuel_ease_flutter/features/wallet/data/models/wallet_transaction.dart';
import 'package:fuel_ease_flutter/features/wallet/data/repositories/wallet_repository.dart';

/// AsyncNotifier for managing wallet state (replaces TanStack Query)
class WalletNotifier extends AsyncNotifier<WalletSummary> {
  final Logger _logger = Logger();

  @override
  Future<WalletSummary> build() async {
    // Auto-fetch on mount
    return _fetchWallet();
  }

  Future<WalletSummary> _fetchWallet() async {
    final repository = ref.read(walletRepositoryProvider);
    return await repository.getWalletSummary();
  }

  /// Refresh wallet data
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchWallet());
  }

  /// Recharge wallet
  Future<void> recharge({
    required int amountTzs,
    required String msisdn,
    required String stationId,
    String? provider,
  }) async {
    try {
      final repository = ref.read(walletRepositoryProvider);
      final payload = RechargePayload(
        amountTzs: amountTzs,
        msisdn: msisdn,
        stationId: stationId,
        provider: provider,
      );

      await repository.rechargeWallet(payload);

      // Refresh wallet after successful recharge
      await refresh();

      _logger.i('Wallet recharged successfully: $amountTzs TZS');
    } catch (e) {
      _logger.e('Wallet recharge failed', error: e);
      rethrow;
    }
  }
}

/// Provider for wallet data
final walletProvider =
    AsyncNotifierProvider<WalletNotifier, WalletSummary>(() {
  return WalletNotifier();
});

/// Convenience provider for available balance
final availableBalanceProvider = Provider<double?>((ref) {
  final walletState = ref.watch(walletProvider);
  return walletState.whenOrNull(
    data: (summary) => summary.wallet.availableBalance,
  );
});

/// Convenience provider for wallet status
final walletStatusProvider = Provider<String?>((ref) {
  final walletState = ref.watch(walletProvider);
  return walletState.whenOrNull(
    data: (summary) => summary.wallet.status,
  );
});

/// Provider for fetching wallet transactions with pagination
final walletTransactionsProvider = FutureProvider.autoDispose
    .family<List<WalletTransaction>, WalletTransactionsParams>((ref, params) async {
  final repository = ref.read(walletRepositoryProvider);
  return await repository.getTransactions(
    limit: params.limit,
    offset: params.offset,
  );
});

/// Parameters for wallet transactions provider
class WalletTransactionsParams {
  const WalletTransactionsParams({
    required this.limit,
    required this.offset,
  });

  final int limit;
  final int offset;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletTransactionsParams &&
          runtimeType == other.runtimeType &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode => limit.hashCode ^ offset.hashCode;
}
