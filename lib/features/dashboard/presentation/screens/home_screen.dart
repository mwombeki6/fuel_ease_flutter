import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:fuel_ease_flutter/core/realtime/realtime_debug_provider.dart';
import 'package:fuel_ease_flutter/core/realtime/realtime_status_provider.dart';
import 'package:fuel_ease_flutter/core/realtime/realtime_client.dart';
import 'package:fuel_ease_flutter/features/stations/presentation/providers/station_provider.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';
import 'package:fuel_ease_flutter/shared/theme/app_text_styles.dart';

/// Home dashboard screen
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _hasSeenConnected = false;

  @override
  void initState() {
    super.initState();
    ref.listen<RealtimeStatus>(realtimeStatusProvider, (previous, next) {
      if (!mounted) return;
      if (!_hasSeenConnected &&
          next.state == RealtimeConnectionState.connected) {
        _hasSeenConnected = true;
        return;
      }
      if (previous == null) return;
      if ((previous.state == RealtimeConnectionState.reconnecting ||
              previous.state == RealtimeConnectionState.disconnected) &&
          next.state == RealtimeConnectionState.connected) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Realtime reconnected'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final walletState = ref.watch(walletProvider);
    final availableBalance = ref.watch(availableBalanceProvider);
    final activeCardsCount = ref.watch(activeCardsCountProvider);
    final stationState = ref.watch(stationSelectionProvider);
    final realtimeState = ref.watch(realtimeDebugProvider);
    final realtimeStatus = ref.watch(realtimeStatusProvider);
    final realtimeClient = ref.read(realtimeClientProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(walletProvider.notifier).refresh(),
            ref.read(cardsProvider.notifier).refresh(),
            ref.read(stationSelectionProvider.notifier).refresh(),
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
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12, top: 8),
                  child: _RealtimeStatusChip(status: realtimeStatus),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: authState.maybeWhen(
                  authenticated: (user) => Text(
                    'Hello, ${user.firstName}!',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: Colors.white,
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

            // Station selector
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: AppColors.cardGradient,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_gas_station, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected station',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (stationState.isLoading)
                              Text(
                                'Loading stations…',
                                style: AppTextStyles.titleSmall,
                              )
                            else if (stationState.error != null)
                              Text(
                                'Unable to load stations',
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: AppColors.error,
                                ),
                              )
                            else if (stationState.stations.isEmpty)
                              Text(
                                'No stations available',
                                style: AppTextStyles.titleSmall,
                              )
                            else
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: stationState.stationId ??
                                      stationState.stations.first.id,
                                  isExpanded: true,
                                  icon: const Icon(Icons.expand_more),
                                  items: stationState.stations
                                      .map((station) => DropdownMenuItem(
                                            value: station.id,
                                            child: Text(
                                              station.name,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTextStyles.titleSmall,
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    final selected = stationState.stations.firstWhere(
                                      (station) => station.id == value,
                                      orElse: () => stationState.stations.first,
                                    );
                                    ref
                                        .read(stationSelectionProvider.notifier)
                                        .setStation(selected);
                                  },
                                ),
                              ),
                            if (stationState.fromCache)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  children: [
                                    const Icon(Icons.cloud_off,
                                        size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Showing cached data',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (stationState.lastUpdated != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.schedule,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Last sync ${DateFormat('HH:mm').format(stationState.lastUpdated!)}',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Realtime status
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _RealtimeStatusCard(
                  status: realtimeStatus,
                  onReconnect: () => realtimeClient.connect(),
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
                    Text(
                      'Overview',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: QuickStatCard(
                            title: 'Wallet Balance',
                            value: availableBalance != null
                                ? '${NumberFormat('#,##0').format(availableBalance.toInt())} TZS'
                                : '0 TZS',
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
                    Text(
                      'Quick Actions',
                      style: AppTextStyles.titleMedium,
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
                              context.push(Routes.stations);
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
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: QuickActionButton(
                        label: 'Dispense Fuel',
                        icon: Icons.local_gas_station,
                        color: AppColors.success,
                        onTap: () =>
                            context.push(Routes.createDispensingRequest),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Realtime debug ticker (QA)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.cardGradient,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Realtime Feed', style: AppTextStyles.titleMedium),
                          TextButton(
                            onPressed: () => ref
                                .read(realtimeDebugProvider.notifier)
                                .clear(),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Live telemetry events (QA visibility)',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (realtimeState.events.isEmpty)
                        Text(
                          'No realtime events yet.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        )
                      else
                        Column(
                          children: realtimeState.events.reversed.take(4).map((event) {
                            final type = (event['type'] ?? 'event').toString();
                            final stationId = event['stationId']?.toString();
                            final pumpId = event['pumpId']?.toString();
                            final timestamp = event['timestamp']?.toString();
                            final meta = [
                              if (pumpId != null) 'pump $pumpId',
                              if (stationId != null) 'station $stationId',
                            ].join(' · ');

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          type,
                                          style: AppTextStyles.labelLarge,
                                        ),
                                        if (meta.isNotEmpty)
                                          Text(
                                            meta,
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (timestamp != null)
                                    Text(
                                      timestamp.split('T').last.split('.').first,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
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
                    Text('Recent Activity', style: AppTextStyles.titleMedium),
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
                              style: AppTextStyles.titleSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your transactions will appear here',
                              style: AppTextStyles.bodySmall.copyWith(
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

class _RealtimeStatusCard extends StatelessWidget {
  const _RealtimeStatusCard({
    required this.status,
    required this.onReconnect,
  });

  final RealtimeStatus status;
  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status.state);
    final label = _statusLabel(status.state);
    final detail = _lastEventLabel(status.lastEventAt, status.state);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Realtime',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (status.state == RealtimeConnectionState.disconnected)
            TextButton(
              onPressed: onReconnect,
              child: const Text('Reconnect'),
            ),
        ],
      ),
    );
  }

  Color _statusColor(RealtimeConnectionState state) {
    switch (state) {
      case RealtimeConnectionState.connected:
        return AppColors.success;
      case RealtimeConnectionState.connecting:
        return AppColors.warning;
      case RealtimeConnectionState.reconnecting:
        return AppColors.warning;
      case RealtimeConnectionState.disconnected:
        return AppColors.error;
    }
  }

  String _statusLabel(RealtimeConnectionState state) {
    switch (state) {
      case RealtimeConnectionState.connected:
        return 'Connected';
      case RealtimeConnectionState.connecting:
        return 'Connecting…';
      case RealtimeConnectionState.reconnecting:
        return 'Reconnecting…';
      case RealtimeConnectionState.disconnected:
        return 'Disconnected';
    }
  }

  String _lastEventLabel(
    DateTime? lastEventAt,
    RealtimeConnectionState state,
  ) {
    if (lastEventAt == null) {
      return state == RealtimeConnectionState.connected
          ? 'Waiting for events…'
          : 'No recent events';
    }
    final diff = DateTime.now().difference(lastEventAt);
    if (diff.inSeconds < 60) {
      return 'Last event ${diff.inSeconds}s ago';
    }
    if (diff.inMinutes < 60) {
      return 'Last event ${diff.inMinutes}m ago';
    }
    return 'Last event at ${DateFormat('HH:mm').format(lastEventAt)}';
  }
}

class _RealtimeStatusChip extends StatelessWidget {
  const _RealtimeStatusChip({required this.status});

  final RealtimeStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _chipColor(status.state);
    final label = _chipLabel(status.state);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Color _chipColor(RealtimeConnectionState state) {
    switch (state) {
      case RealtimeConnectionState.connected:
        return AppColors.success;
      case RealtimeConnectionState.connecting:
        return AppColors.warning;
      case RealtimeConnectionState.reconnecting:
        return AppColors.warning;
      case RealtimeConnectionState.disconnected:
        return AppColors.error;
    }
  }

  String _chipLabel(RealtimeConnectionState state) {
    switch (state) {
      case RealtimeConnectionState.connected:
        return 'Live';
      case RealtimeConnectionState.connecting:
        return 'Sync';
      case RealtimeConnectionState.reconnecting:
        return 'Retry';
      case RealtimeConnectionState.disconnected:
        return 'Offline';
    }
  }
}
