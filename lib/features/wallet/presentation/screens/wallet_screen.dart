import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/widgets/transaction_detail_sheet.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/widgets/transaction_list_item.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';
import 'package:fuel_ease_flutter/shared/utils/app_snackbar.dart';
import 'package:fuel_ease_flutter/shared/widgets/fe_widgets.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(walletProvider);

    ref.listen(walletProvider, (_, next) {
      next.whenOrNull(error: (e, _) => AppSnackbar.fromError(context, e));
    });

    return Scaffold(
      backgroundColor: AppColors.midnight,
      body: RefreshIndicator(
        color: AppColors.brand,
        backgroundColor: AppColors.surfaceDark,
        onRefresh: () async {
          await ref.read(walletProvider.notifier).refresh();
        },
        child: walletState.when(
          data: (summary) => _buildContent(context, ref, summary),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildError(context, ref, error),
        ),
      ),
      floatingActionButton: _GradientFab(
        onTap: () => context.push(Routes.walletRecharge),
        label: 'Top Up',
        icon: Icons.add_rounded,
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, dynamic summary) {
    final wallet = summary.wallet;
    final recentTransactions = summary.recentTransactions ?? [];

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Dark pinned app bar
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.midnight,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'My Wallet',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.history_rounded,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              onPressed: () => context.push(Routes.walletTransactions),
              tooltip: 'Transaction History',
            ),
          ],
        ),

        // Gradient balance card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _BalanceCard(wallet: wallet, onTopUp: () => context.push(Routes.walletRecharge)),
          ),
        ),

        // Recent transactions header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                if (recentTransactions.length >= 5)
                  GestureDetector(
                    onTap: () => context.push(Routes.walletTransactions),
                    child: Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brand,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Transactions list / empty state
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
                  onTap: () => showTransactionDetail(context, transaction),
                )
                    .animate(delay: (index * 40).ms)
                    .slideY(begin: 0.1, end: 0, duration: 280.ms, curve: Curves.easeOutCubic)
                    .fadeIn(duration: 250.ms);
              },
              childCount: recentTransactions.length,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevatedDark,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 36,
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Top up your wallet to get started',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.4),
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
            Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 20),
            const Text(
              'Failed to load wallet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.4)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            GradientButton(
              onPressed: () => ref.read(walletProvider.notifier).refresh(),
              label: 'Try Again',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated balance card ──────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.wallet, required this.onTopUp});

  final dynamic wallet;
  final VoidCallback onTopUp;

  @override
  Widget build(BuildContext context) {
    final numberFmt = NumberFormat('#,##0');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandGlow,
            blurRadius: 32,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AVAILABLE BALANCE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.65),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          AnimatedCounter(
            value: wallet.balanceTzs.toDouble(),
            formatter: (v) => 'TZS ${numberFmt.format(v.toInt())}',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _CardChip(
                icon: Icons.add_rounded,
                label: 'Top Up',
                onTap: onTopUp,
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance_wallet_rounded,
                        size: 14, color: Colors.white.withValues(alpha: 0.8)),
                    const SizedBox(width: 6),
                    Text(
                      'Active wallet',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 350.ms);
  }
}

class _CardChip extends StatelessWidget {
  const _CardChip({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Gradient FAB ───────────────────────────────────────────────────────────

class _GradientFab extends StatelessWidget {
  const _GradientFab({required this.onTap, required this.label, required this.icon});

  final VoidCallback onTap;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandGlow,
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
