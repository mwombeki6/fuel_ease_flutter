import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/features/wallet/presentation/providers/wallet_provider.dart';

/// Sum of all debit transactions within the last 7 days (integer TZS).
final weeklySpendProvider = Provider<int>((ref) {
  final walletState = ref.watch(walletProvider);
  return walletState.whenOrNull(data: (summary) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return (summary.recentTransactions ?? [])
        .where((t) => t.isDebit && (t.createdAt?.isAfter(cutoff) ?? false))
        .fold<int>(0, (sum, t) => sum + t.amountTzs);
  }) ?? 0;
});

/// Days-ago (0 = today) → total debit TZS for the last 30 days.
/// Used by the wallet spending bar chart.
final spendingChartDataProvider = Provider<Map<int, int>>((ref) {
  final walletState = ref.watch(walletProvider);
  return walletState.whenOrNull(data: (summary) {
    final now = DateTime.now();
    final result = <int, int>{};
    for (final t in (summary.recentTransactions ?? [])) {
      if (!t.isDebit) continue;
      final date = t.createdAt;
      if (date == null) continue;
      final daysAgo = now.difference(date).inDays;
      if (daysAgo < 0 || daysAgo >= 30) continue;
      result[daysAgo] = ((result[daysAgo] ?? 0) + t.amountTzs).toInt();
    }
    return result;
  }) ?? {};
});
