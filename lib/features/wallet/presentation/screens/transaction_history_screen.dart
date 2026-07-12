import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/features/wallet/data/models/wallet_transaction.dart';
import 'package:fuel_ease_flutter/features/wallet/data/repositories/wallet_repository.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/widgets/transaction_detail_sheet.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/widgets/transaction_list_item.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';
import 'package:fuel_ease_flutter/shared/theme/app_text_styles.dart';

const _pageSize = 30;

// Paginated notifier: accumulates transactions as pages are loaded.
class _TransactionListNotifier extends StateNotifier<AsyncValue<List<WalletTransaction>>> {
  _TransactionListNotifier(this._repo) : super(const AsyncValue.loading()) {
    _load();
  }

  final WalletRepository _repo;
  int _offset = 0;
  bool _hasMore = true;
  bool _loading = false;

  Future<void> _load() async {
    if (_loading || !_hasMore) return;
    _loading = true;
    try {
      final page = await _repo.getTransactions(limit: _pageSize, offset: _offset);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data([...current, ...page]);
      _offset += page.length;
      _hasMore = page.length == _pageSize;
    } catch (e, st) {
      if (_offset == 0) state = AsyncValue.error(e, st);
    } finally {
      _loading = false;
    }
  }

  Future<void> loadMore() => _load();

  Future<void> refresh() async {
    _offset = 0;
    _hasMore = true;
    state = const AsyncValue.loading();
    await _load();
  }
}

final _transactionListProvider = StateNotifierProvider.autoDispose<
    _TransactionListNotifier, AsyncValue<List<WalletTransaction>>>((ref) {
  return _TransactionListNotifier(ref.read(walletRepositoryProvider));
});

/// Transaction history screen with filter chips and infinite scroll.
class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  final _scrollController = ScrollController();
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(_transactionListProvider.notifier).loadMore();
    }
  }

  List<WalletTransaction> _filtered(List<WalletTransaction> all) {
    if (_filter == 'credit') return all.where((t) => t.isCredit).toList();
    if (_filter == 'debit') return all.where((t) => t.isDebit).toList();
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final asyncTx = ref.watch(_transactionListProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Transaction History'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(_transactionListProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: cs.surface,
            child: Row(
              children: [
                _Chip(
                  label: 'All',
                  selected: _filter == 'all',
                  onTap: () => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                _Chip(
                  label: 'Top-ups',
                  selected: _filter == 'credit',
                  icon: Icons.arrow_downward_rounded,
                  iconColor: AppColors.success,
                  onTap: () => setState(() => _filter = 'credit'),
                ),
                const SizedBox(width: 8),
                _Chip(
                  label: 'Purchases',
                  selected: _filter == 'debit',
                  icon: Icons.arrow_upward_rounded,
                  iconColor: AppColors.error,
                  onTap: () => setState(() => _filter = 'debit'),
                ),
              ],
            ),
          ),

          Expanded(
            child: asyncTx.when(
              data: (all) {
                final items = _filtered(all);
                if (items.isEmpty) return _Empty(filter: _filter);
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(_transactionListProvider.notifier).refresh(),
                  child: ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: items.length + 1,
                    separatorBuilder: (context2, idx2) => Divider(
                      height: 1,
                      color: cs.outlineVariant,
                      indent: 72,
                    ),
                    itemBuilder: (context, index) {
                      if (index == items.length) {
                        return const _LoadingFooter();
                      }
                      return TransactionListItem(
                        transaction: items[index],
                        onTap: () =>
                            showTransactionDetail(context, items[index]),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _Error(
                message: err.toString(),
                onRetry: () =>
                    ref.read(_transactionListProvider.notifier).refresh(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.iconColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: selected ? Colors.white : iconColor,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: selected ? Colors.white : cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingFooter extends StatelessWidget {
  const _LoadingFooter();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.filter});

  final String filter;

  @override
  Widget build(BuildContext context) {
    final msg = filter == 'credit'
        ? 'No top-up transactions yet'
        : filter == 'debit'
            ? 'No purchase transactions yet'
            : 'No transactions yet';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(msg, style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            Text(
              filter == 'all'
                  ? 'Your transaction history will appear here'
                  : 'Change filter to view other transactions',
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Failed to load transactions', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
