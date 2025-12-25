import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:fuel_ease_flutter/features/cards/presentation/providers/cards_provider.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/widgets/transaction_list_item.dart';
import 'package:fuel_ease_flutter/features/dashboard/presentation/widgets/quick_stat_card.dart';
import 'package:fuel_ease_flutter/features/dashboard/presentation/widgets/quick_action_button.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';

/// Home dashboard screen
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final walletState = ref.watch(walletProvider);
    final availableBalance = ref.watch(availableBalanceProvider);
    final activeCardsCount = ref.watch(activeCardsCountProvider);
    final totalCardsValue = ref.watch(totalCardsValueProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(walletProvider.notifier).refresh(),
            ref.read(cardsProvider.notifier).refresh(),
          ]);
        },
        child: CustomScrollView(
          slivers: [
            // App bar with greeting
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                title: authState.maybeWhen(
                  authenticated: (user) => Text(
                    'Hello, ${user.firstName}!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  orElse: () => const Text('Dashboard'),
                ),
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                ),
              ),
            ),

            // Quick stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: QuickStatCard(
                            title: 'Wallet Balance',
                            value: availableBalance != null
                                ? '${NumberFormat('#,##0').format(availableBalance)} L'
                                : '0 L',
                            icon: Icons.account_balance_wallet,
                            color: AppColors.primary,
                            onTap: () => context.go(Routes.wallet),
                            subtitle: availableBalance != null &&
                                    availableBalance > 0
                                ? 'Available'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: QuickStatCard(
                            title: 'Active Cards',
                            value: activeCardsCount.toString(),
                            icon: Icons.credit_card,
                            color: AppColors.accent,
                            onTap: () => context.go(Routes.cards),
                            subtitle: totalCardsValue > 0
                                ? '${NumberFormat('#,##0').format(totalCardsValue)} L'
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Quick actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: QuickActionButton(
                            label: 'Top Up Wallet',
                            icon: Icons.add_circle_outline,
                            color: AppColors.primary,
                            onTap: () => context.push(Routes.walletRecharge),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: QuickActionButton(
                            label: 'Create Card',
                            icon: Icons.card_giftcard,
                            color: AppColors.accent,
                            onTap: () => context.push(Routes.createCard),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: QuickActionButton(
                            label: 'Find Station',
                            icon: Icons.local_gas_station,
                            color: AppColors.warning,
                            onTap: () {
                              // TODO: Navigate to stations
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: QuickActionButton(
                            label: 'History',
                            icon: Icons.history,
                            color: AppColors.info,
                            onTap: () =>
                                context.push(Routes.walletTransactions),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Recent transactions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push(Routes.walletTransactions),
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
            ),

            // Transactions list
            walletState.when(
              data: (summary) {
                final transactions = summary.recentTransactions ?? [];
                if (transactions.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
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
                              'No recent activity',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your transactions will appear here',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final transaction = transactions[index];
                      return TransactionListItem(
                        transaction: transaction,
                        onTap: () {
                          // Could navigate to transaction details
                        },
                      );
                    },
                    childCount: transactions.length > 5 ? 5 : transactions.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (error, stack) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Failed to load recent activity',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }
}
