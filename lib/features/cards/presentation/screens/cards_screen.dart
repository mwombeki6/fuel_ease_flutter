import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/cards/data/models/fuel_card.dart';
import 'package:fuel_ease_flutter/features/cards/presentation/providers/cards_provider.dart';
import 'package:fuel_ease_flutter/features/cards/presentation/widgets/fuel_card_item.dart';
import 'package:fuel_ease_flutter/features/cards/presentation/widgets/cards_stats_card.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';
import 'package:fuel_ease_flutter/shared/utils/app_snackbar.dart';
import 'package:fuel_ease_flutter/shared/widgets/fe_widgets.dart';

class CardsScreen extends ConsumerStatefulWidget {
  const CardsScreen({super.key});

  @override
  ConsumerState<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends ConsumerState<CardsScreen> {
  String _selectedFilter = 'all';

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

    ref.listen(cardsProvider, (_, next) {
      next.whenOrNull(error: (e, _) => AppSnackbar.fromError(context, e));
    });

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.brand,
        backgroundColor: Theme.of(context).colorScheme.surface,
        onRefresh: () => ref.read(cardsProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Pinned app bar
            SliverAppBar(
              pinned: true,
              backgroundColor: Theme.of(context).colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              title: Text(
                'Fuel Cards',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () => context.push(Routes.createCard),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brandGlow,
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),

            // Content based on state
            ...cardsState.when(
              data: (cards) => _buildContent(context, ref, cards, activeCount, totalValue),
              loading: () => [
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (error, stack) => [
                SliverFillRemaining(
                  child: _buildError(context, ref, error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<FuelCard> cards,
    int activeCount,
    double totalValue,
  ) {
    final usedCount = cards.where((c) => c.isUsed).length;
    final filteredCards = _filterCards(cards);

    return [
      // Stats card
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: CardsStatsCard(
            activeCount: activeCount,
            totalValue: totalValue,
            usedCount: usedCount,
          ),
        ),
      ),

      // Filter chips
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  activeColor: AppColors.success,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Used ($usedCount)',
                  isSelected: _selectedFilter == 'used',
                  onTap: () => setState(() => _selectedFilter = 'used'),
                  activeColor: AppColors.info,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Expired',
                  isSelected: _selectedFilter == 'expired',
                  onTap: () => setState(() => _selectedFilter = 'expired'),
                  activeColor: AppColors.error,
                ),
              ],
            ),
          ),
        ),
      ),

      // Cards list / empty state
      if (filteredCards.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(context),
        )
      else
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final card = filteredCards[index];
              return FuelCardItem(
                card: card,
                onTap: () => context.push(Routes.cardDetails(card.id)),
              )
                  .animate(delay: (index * 40).ms)
                  .slideY(begin: 0.15, end: 0, duration: 300.ms, curve: Curves.easeOutCubic)
                  .fadeIn(duration: 250.ms);
            },
            childCount: filteredCards.length,
          ),
        ),

      const SliverToBoxAdapter(child: SizedBox(height: 100)),
    ];
  }

  Widget _buildEmptyState(BuildContext context) {
    String message;
    String description;

    switch (_selectedFilter) {
      case 'active':
        message = 'No active cards';
        description = 'Create a new fuel card to get started';
      case 'used':
        message = 'No used cards';
        description = 'Cards you\'ve redeemed will appear here';
      case 'expired':
        message = 'No expired cards';
        description = 'Expired cards will appear here';
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                ),
              ),
              child: Icon(
                Icons.credit_card_outlined,
                size: 36,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
            if (_selectedFilter == 'all') ...[
              const SizedBox(height: 28),
              GradientButton(
                onPressed: () => context.push(Routes.createCard),
                label: 'Create Card',
              ),
            ],
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
            Text(
              'Failed to load cards',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            GradientButton(
              onPressed: () => ref.read(cardsProvider.notifier).refresh(),
              label: 'Try Again',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter chip ────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.activeColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = activeColor ?? AppColors.brand;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.brandGradient : null,
          color: isSelected ? null : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : cs.outline.withValues(alpha: 0.2),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 10,
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : cs.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
