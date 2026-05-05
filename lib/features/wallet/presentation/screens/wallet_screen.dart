import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/widgets/transaction_list_item.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/widgets/wallet_balance_card.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';

/// Wallet overview screen showing balance and recent transactions
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Wallet'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              context.push(Routes.walletTransactions);
            },
            tooltip: 'Transaction History',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(walletProvider.notifier).refresh();
        },
        child: walletState.when(
          data: (summary) => _buildContent(context, ref, summary),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => _buildError(context, ref, error),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(Routes.walletRecharge);
        },
        icon: const Icon(Icons.add),
        label: const Text('Top Up'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    dynamic summary,
  ) {
    final wallet = summary.wallet;
    final recentTransactions = summary.recentTransactions ?? [];

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Wallet balance card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: WalletBalanceCard(
              wallet: wallet,
              onRecharge: () {
                context.push(Routes.walletRecharge);
              },
            ),
          ),
        ),

        // Recent transactions header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (recentTransactions.length >= 5)
                  TextButton(
                    onPressed: () {
                      context.push(Routes.walletTransactions);
                    },
                    child: const Text('View All'),
                  ),
              ],
            ),
          ),
        ),

        // Recent transactions list
        if (recentTransactions.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyTransactions(context),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final transaction = recentTransactions[index];
                return TransactionListItem(
                  transaction: transaction,
                  onTap: () {
                    // TODO: Navigate to transaction detail
                    // context.push(Routes.transactionDetail, extra: transaction);
                  },
                );
              },
              childCount: recentTransactions.length,
            ),
          ),

        // Bottom padding for FAB
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }

  Widget _buildEmptyTransactions(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Top up your wallet to get started',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load wallet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(walletProvider.notifier).refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
