import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/widgets/transaction_list_item.dart';
import 'package:fuel_ease_flutter/core/realtime/realtime_client.dart';
import 'package:fuel_ease_flutter/core/realtime/realtime_status_provider.dart';
import 'package:fuel_ease_flutter/features/cards/presentation/providers/cards_provider.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';
import 'package:fuel_ease_flutter/shared/utils/app_snackbar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _hasSeenConnected = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(walletProvider, (_, next) {
      next.whenOrNull(
        error: (e, _) => AppSnackbar.fromError(context, e),
      );
    });

    ref.listen<RealtimeStatus>(realtimeStatusProvider, (previous, next) {
      if (!mounted) return;
      if (!_hasSeenConnected && next.state == RealtimeConnectionState.connected) {
        _hasSeenConnected = true;
        return;
      }
      if (previous == null) return;
      if ((previous.state == RealtimeConnectionState.reconnecting ||
              previous.state == RealtimeConnectionState.disconnected) &&
          next.state == RealtimeConnectionState.connected) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reconnected to live feed')),
        );
      }
    });

    final authState = ref.watch(authProvider);
    final walletState = ref.watch(walletProvider);
    final availableBalance = ref.watch(availableBalanceProvider);
    final realtimeStatus = ref.watch(realtimeStatusProvider);
    final cs = Theme.of(context).colorScheme;

    final firstName = authState.maybeWhen(
      authenticated: (user) => user.firstName,
      orElse: () => '',
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(walletProvider.notifier).refresh(),
            ref.read(cardsProvider.notifier).refresh(),
          ]);
        },
        child: CustomScrollView(
          slivers: [
            // Header
            SliverAppBar(
              pinned: true,
              floating: false,
              expandedHeight: 0,
              backgroundColor: cs.surface,
              surfaceTintColor: Colors.transparent,
              titleSpacing: 20,
              title: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'F',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'FuelEase',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                  ),
                ],
              ),
              actions: [
                // Connection status dot
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _StatusDot(status: realtimeStatus),
                ),
                // Notification icon placeholder
                IconButton(
                  icon: Icon(Icons.notifications_outlined, color: cs.onSurface),
                  onPressed: () {},
                ),
                // Avatar
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _Avatar(firstName: firstName),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    Text(
                      _greeting(firstName),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'What do you need today?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                    ),

                    const SizedBox(height: 24),

                    // Wallet balance card
                    _WalletBalanceCard(
                      balance: availableBalance,
                      walletState: walletState,
                      onTopUp: () => context.push(Routes.walletRecharge),
                      onHistory: () => context.push(Routes.walletTransactions),
                    ),

                    const SizedBox(height: 20),

                    // Hero CTA — Fuel Up
                    _FuelUpButton(
                      onTap: () => context.go(Routes.map),
                    ),

                    const SizedBox(height: 16),

                    // Secondary actions
                    Row(
                      children: [
                        Expanded(
                          child: _SecondaryActionTile(
                            icon: Icons.map_rounded,
                            label: 'Find Station',
                            onTap: () => context.go(Routes.map),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SecondaryActionTile(
                            icon: Icons.receipt_long_rounded,
                            label: 'Dispense History',
                            onTap: () => context.push(Routes.dispensingRequests),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Recent transactions header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Transactions',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                        ),
                        TextButton(
                          onPressed: () => context.push(Routes.walletTransactions),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'All',
                                style: TextStyle(color: cs.primary, fontSize: 13),
                              ),
                              Icon(Icons.chevron_right, size: 16, color: cs.primary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Transactions
            walletState.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (_, st) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Text(
                    'Could not load transactions',
                    style: TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
              ),
              data: (summary) {
                final txns = (summary.recentTransactions ?? []).take(3).toList();
                if (txns.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _EmptyTransactions(),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: TransactionListItem(
                        transaction: txns[i],
                        onTap: () {},
                      ),
                    ),
                    childCount: txns.length,
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  String _greeting(String firstName) {
    final hour = DateTime.now().hour;
    final salutation = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    return firstName.isNotEmpty ? '$salutation, $firstName' : salutation;
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';
    return GestureDetector(
      onTap: () => context.go(Routes.profile),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: cs.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final RealtimeStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status.state) {
      RealtimeConnectionState.connected => AppColors.success,
      RealtimeConnectionState.connecting => AppColors.warning,
      RealtimeConnectionState.reconnecting => AppColors.warning,
      RealtimeConnectionState.disconnected => AppColors.error,
    };
    return Tooltip(
      message: status.state.name,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _WalletBalanceCard extends StatelessWidget {
  const _WalletBalanceCard({
    required this.balance,
    required this.walletState,
    required this.onTopUp,
    required this.onHistory,
  });

  final double? balance;
  final AsyncValue<dynamic> walletState;
  final VoidCallback onTopUp;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final balanceText = balance != null
        ? 'TZS ${NumberFormat('#,##0').format(balance!.toInt())}'
        : '—';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wallet Balance',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                  letterSpacing: 0.4,
                ),
          ),
          const SizedBox(height: 8),
          walletState.isLoading
              ? const SizedBox(
                  height: 32,
                  width: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  balanceText,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _CardAction(
                  label: 'Top Up',
                  icon: Icons.add_rounded,
                  onTap: onTopUp,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CardAction(
                  label: 'History',
                  icon: Icons.history_rounded,
                  onTap: onHistory,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FuelUpButton extends StatelessWidget {
  const _FuelUpButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_gas_station_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fuel Up',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Find a station & request fuel',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.7),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryActionTile extends StatelessWidget {
  const _SecondaryActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: cs.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.onSurface,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 40,
            color: cs.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 8),
          Text(
            'No transactions yet',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
          ),
        ],
      ),
    );
  }
}
