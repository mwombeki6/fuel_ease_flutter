import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/features/wallet/data/models/recharge_payload.dart';
import 'package:fuel_ease_flutter/features/wallet/data/models/wallet_summary.dart';
import 'package:fuel_ease_flutter/features/wallet/data/models/wallet_transaction.dart';
import 'package:fuel_ease_flutter/features/wallet/data/repositories/wallet_repository.dart';

class WalletNotifier extends AsyncNotifier<WalletSummary> {
  @override
  Future<WalletSummary> build() async => _fetchWallet();

  Future<WalletSummary> _fetchWallet() async {
    return ref.read(walletRepositoryProvider).getWalletSummary();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchWallet);
  }

  /// Initiate a mobile-money top-up (AzamPay STK push).
  Future<void> topUp({
    required int amountTzs,
    required String msisdn,
    required String provider,
  }) async {
    final payload = TopUpPayload(
      amountTzs: amountTzs,
      msisdn: msisdn,
      provider: provider,
    );
    await ref.read(walletRepositoryProvider).topUpWallet(payload);
    // Wallet balance won't update until the webhook callback confirms payment
  }

  // Backward-compat alias used by existing recharge screen
  Future<void> recharge({
    required int amountTzs,
    required String msisdn,
    String? stationId,
    String? provider,
  }) => topUp(
    amountTzs: amountTzs,
    msisdn: msisdn,
    provider: provider ?? 'Mpesa',
  );
}

final walletProvider = AsyncNotifierProvider<WalletNotifier, WalletSummary>(
  WalletNotifier.new,
);

final availableBalanceProvider = Provider<double?>((ref) {
  final walletState = ref.watch(walletProvider);
  return walletState.whenOrNull(
    data: (summary) => summary.wallet.availableBalance,
  );
});

final walletStatusProvider = Provider<String?>((ref) {
  final walletState = ref.watch(walletProvider);
  return walletState.whenOrNull(data: (summary) => summary.wallet.status);
});

final walletTransactionsProvider = FutureProvider.autoDispose
    .family<List<WalletTransaction>, WalletTransactionsParams>((
      ref,
      params,
    ) async {
      return ref
          .read(walletRepositoryProvider)
          .getTransactions(limit: params.limit, offset: params.offset);
    });

class WalletTransactionsParams {
  const WalletTransactionsParams({required this.limit, required this.offset});

  final int limit;
  final int offset;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletTransactionsParams &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode => limit.hashCode ^ offset.hashCode;
}
