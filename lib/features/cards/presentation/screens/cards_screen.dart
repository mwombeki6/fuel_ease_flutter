import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/cards/data/models/fuel_card.dart';
import 'package:fuel_ease_flutter/features/cards/presentation/providers/cards_provider.dart';
import 'package:fuel_ease_flutter/features/cards/presentation/widgets/fuel_card_item.dart';
import 'package:fuel_ease_flutter/features/cards/presentation/widgets/cards_stats_card.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';

/// Cards screen showing all fuel cards
class CardsScreen extends ConsumerStatefulWidget {
  const CardsScreen({super.key});

  @override
  ConsumerState<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends ConsumerState<CardsScreen> {
  String _selectedFilter = 'all'; // all, active, used, expired

  List<FuelCard> _filterCards(List<FuelCard> cards) {
    switch (_selectedFilter) {
      case 'active':
        return cards.where((c) => c.isActive).toList();
      case 'used':
        return cards.where((c) => c.isUsed).toList();
      case 'expired':
        return cards.where((c) => c.isExpired || c.isCancelled).toList();
      default:
        return cards;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardsState = ref.watch(cardsProvider);
    final activeCount = ref.watch(activeCardsCountProvider);
    final totalValue = ref.watch(totalCardsValueProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fuel Cards'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              context.push(Routes.createCard);
            },
            tooltip: 'Create New Card',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(cardsProvider.notifier).refresh();
        },
        child: cardsState.when(
          data: (cards) => _buildContent(context, cards, activeCount, totalValue),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => _buildError(context, error),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<FuelCard> cards,
    int activeCount,
    double totalValue,
  ) {
    final usedCount = cards.where((c) => c.isUsed).length;
    final filteredCards = _filterCards(cards);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Stats card
        SliverToBoxAdapter(
          child: CardsStatsCard(
            activeCount: activeCount,
            totalValue: totalValue,
            usedCount: usedCount,
          ),
        ),

        // Filter chips
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All (${cards.length})',
                    isSelected: _selectedFilter == 'all',
                    onTap: () => setState(() => _selectedFilter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Active ($activeCount)',
                    isSelected: _selectedFilter == 'active',
                    onTap: () => setState(() => _selectedFilter = 'active'),
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Used ($usedCount)',
                    isSelected: _selectedFilter == 'used',
                    onTap: () => setState(() => _selectedFilter = 'used'),
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Expired',
                    isSelected: _selectedFilter == 'expired',
                    onTap: () => setState(() => _selectedFilter = 'expired'),
                    color: AppColors.error,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Cards list
        if (filteredCards.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final card = filteredCards[index];
                return FuelCardItem(
                  card: card,
                  onTap: () {
                    context.push(Routes.cardDetails(card.id));
                  },
                );
              },
              childCount: filteredCards.length,
            ),
          ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    String message;
    String description;

    switch (_selectedFilter) {
      case 'active':
        message = 'No active cards';
        description = 'Create a new fuel card to get started';
        break;
      case 'used':
        message = 'No used cards';
        description = 'Cards you\'ve redeemed will appear here';
        break;
      case 'expired':
        message = 'No expired cards';
        description = 'Expired cards will appear here';
        break;
      default:
        message = 'No fuel cards yet';
        description = 'Create your first fuel card to share fuel with others';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card_outlined,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_selectedFilter == 'all') ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  context.push(Routes.createCard);
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Card'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
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
              'Failed to load cards',
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
                ref.read(cardsProvider.notifier).refresh();
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

/// Filter chip widget
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
