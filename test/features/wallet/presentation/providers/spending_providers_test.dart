import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_ease_flutter/features/wallet/data/models/wallet.dart';
import 'package:fuel_ease_flutter/features/wallet/data/models/wallet_summary.dart';
import 'package:fuel_ease_flutter/features/wallet/data/models/wallet_transaction.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/providers/spending_providers.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/providers/wallet_provider.dart';

WalletTransaction _tx(String type, int amountTzs, DateTime createdAt) =>
    WalletTransaction(
      id: 'tx-$amountTzs',
      walletId: 'w1',
      type: type,
      amountTzs: amountTzs,
      balanceAfterTzs: 0,
      createdAt: createdAt,
    );

Wallet _wallet() => Wallet(
      id: 'w1',
      balanceTzs: 100000,
      status: 'active',
      updatedAt: DateTime.now(),
    );

void main() {
  test('weeklySpendProvider sums debits within last 7 days', () async {
    final now = DateTime.now();
    final txs = [
      _tx('debit', 5000, now.subtract(const Duration(days: 2))),   // in range
      _tx('debit', 3000, now.subtract(const Duration(days: 6))),   // in range
      _tx('debit', 9999, now.subtract(const Duration(days: 8))),   // out of range
      _tx('credit', 1000, now.subtract(const Duration(days: 1))),  // credit — ignored
    ];

    final container = ProviderContainer(
      overrides: [
        walletProvider.overrideWith(() => _FakeWalletNotifier(
              WalletSummary(wallet: _wallet(), recentTransactions: txs),
            )),
      ],
    );
    addTearDown(container.dispose);

    await container.read(walletProvider.future);
    expect(container.read(weeklySpendProvider), 8000);
  });

  test('spendingChartDataProvider keys are 0–29, credits excluded', () async {
    final now = DateTime.now();
    final txs = [
      _tx('debit', 2000, now),                                       // today = key 0
      _tx('debit', 4000, now.subtract(const Duration(days: 15))),    // key 15
      _tx('credit', 1000, now.subtract(const Duration(days: 1))),    // ignored
      _tx('debit', 500, now.subtract(const Duration(days: 31))),     // out of range
    ];

    final container = ProviderContainer(
      overrides: [
        walletProvider.overrideWith(() => _FakeWalletNotifier(
              WalletSummary(wallet: _wallet(), recentTransactions: txs),
            )),
      ],
    );
    addTearDown(container.dispose);

    await container.read(walletProvider.future);
    final data = container.read(spendingChartDataProvider);
    expect(data[0], 2000);
    expect(data[15], 4000);
    expect(data.containsKey(31), isFalse);
    expect(data.values.every((v) => v > 0), isTrue);
    expect(data.length, 2); // only 2 debit txs in the 30-day window
  });
}

class _FakeWalletNotifier extends WalletNotifier {
  _FakeWalletNotifier(this._value);
  final WalletSummary _value;

  @override
  Future<WalletSummary> build() async => _value;
}
