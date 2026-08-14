import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/widgets/transaction_list_item.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/widgets/wallet_balance_card.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final walletAsync = ref.watch(walletProvider);
    final authState = ref.watch(authProvider);
    final firstName = authState.maybeWhen(
      authenticated: (user) => user.firstName,
      orElse: () => '',
    );
    final hour = DateTime.now().hour;
    final timeOfDay = hour < 12
        ? 'morning'
        : hour < 17
            ? 'afternoon'
            : 'evening';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good $timeOfDay, ${firstName.split(' ').first}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your Fuel Wallet',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
              ),
            ),

            // Balance Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: walletAsync.when(
                  data: (summary) => WalletBalanceCard(wallet: summary.wallet),
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (_, _) => const Center(
                    child: Icon(Icons.error_outline_rounded),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 100.ms)
                    .slideY(begin: 0.3, end: 0),
              ),
            ),

            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  children: [
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                  ],
                ),
              ),
            ),

            // Quick Action Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.add_rounded,
                        label: 'Add Funds',
                        subtitle: 'Recharge wallet',
                        gradient: isDark
                            ? AppColors.accentGradientDark
                            : AppColors.accentGradientLight,
                        onTap: () => context.push(Routes.walletRecharge),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.history_rounded,
                        label: 'History',
                        subtitle: 'View transactions',
                        gradient: LinearGradient(
                          colors: [
                            AppColors.info,
                            AppColors.infoLight,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () => context.push(Routes.walletTransactions),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                        subtitle: 'Wallet settings',
                        gradient: LinearGradient(
                          colors: [
                            AppColors.textTertiary,
                            AppColors.textSecondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () {
                          // TODO: Wallet settings
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Recent Transactions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Transactions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    TextButton(
                      onPressed: () => context.push(Routes.walletTransactions),
                      child: Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Transaction List
            SliverFillRemaining(
              hasScrollBody: false,
              child: Consumer(
                builder: (context, ref, _) {
                  final transactionsAsync =
                      ref.watch(walletTransactionsProvider(
                    WalletTransactionsParams(limit: 10, offset: 0),
                  ));
                  return transactionsAsync.when(
                    data: (transactions) {
                      if (transactions.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                size: 64,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No transactions yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your first transaction will appear here',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn().slideY(begin: 0.2, end: 0);
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: transactions.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          return TransactionListItem(transaction: tx)
                              .animate()
                              .fadeIn(duration: 400.ms, delay: (100 * index).ms)
                              .slideX(begin: 0.2, end: 0);
                        },
                      );
                    },
                    loading: () => Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    error: (e, _) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load transactions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Sora',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}