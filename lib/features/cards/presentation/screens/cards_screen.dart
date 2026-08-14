import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fuel_ease_flutter/features/cards/presentation/providers/cards_provider.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';
import 'package:fuel_ease_flutter/shared/widgets/glassmorphism.dart' show GlassCard, GlassButton;

class CardsScreen extends ConsumerStatefulWidget {
  const CardsScreen({super.key});

  @override
  ConsumerState<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends ConsumerState<CardsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                      'Your Fuel Cards',
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
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.2, end: 0),
              ),
            ),

            // Stats Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Total Cards',
                        value: '3',
                        icon: Icons.credit_card_rounded,
                        gradient: isDark
                            ? AppColors.brandGradientDark
                            : AppColors.brandGradient,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Active',
                        value: '2',
                        icon: Icons.check_circle_rounded,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.success,
                            AppColors.successLight,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Balance',
                        value: 'TZS 1.2M',
                        icon: Icons.account_balance_wallet_rounded,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent,
                            AppColors.accentLight,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Cards List
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Cards',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    TextButton.icon(
                      onPressed: () => context.push(Routes.createCard),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Card'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Cards List
            SliverFillRemaining(
              hasScrollBody: false,
              child: Consumer(
                builder: (context, ref, _) {
                  final cardsAsync = ref.watch(cardsProvider);
                  return cardsAsync.when(
                    data: (cards) {
                      if (cards.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GlassCard(
                                padding: const EdgeInsets.all(40),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.2),
                                            Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.1),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                      child: Icon(
                                        Icons.credit_card_rounded,
                                        size: 64,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'No Cards Yet',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add your first fuel card to start fueling',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    GlassButton(
                                      onPressed: () => context.push(Routes.createCard),
                                      leadingIcon: Icons.add_rounded,
                                      child: const Text('Add Your First Card'),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: cards.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final card = cards[index];
                          return _FuelCardWidget(card: card)
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
                            'Failed to load cards',
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Gradient gradient;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFamily: 'Sora',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FuelCardWidget extends StatelessWidget {
  final dynamic card;

  const _FuelCardWidget({required this.card});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/cards/${card.id}'),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        margin: EdgeInsets.zero,
        onTap: () => context.push('/cards/${card.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getFuelColor(card.fuelType).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        card.fuelType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _getFuelColor(card.fuelType),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      card.cardNumber.masked,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Sora',
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(card.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    card.status.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _getStatusColor(card.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    label: 'Balance',
                    value: 'TZS ${_formatAmount(card.balance)}',
                    icon: Icons.account_balance_wallet_rounded,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
                Expanded(
                  child: _InfoItem(
                    label: 'Limit',
                    value: 'TZS ${_formatAmount(card.dailyLimit)}',
                    icon: Icons.speed_rounded,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
                Expanded(
                  child: _InfoItem(
                    label: 'Used Today',
                    value: 'TZS ${_formatAmount(card.usedToday)}',
                    icon: Icons.local_fire_department_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getFuelColor(String fuelType) {
    switch (fuelType.toLowerCase()) {
      case 'petrol':
        return AppColors.petrolColor;
      case 'diesel':
        return AppColors.dieselColor;
      case 'premium':
        return AppColors.premiumColor;
      case 'kero':
        return AppColors.keroColor;
      default:
        return AppColors.primary;
    }
  }

  Color _getStatusColor(dynamic status) {
    switch (status.name.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'suspended':
        return AppColors.error;
      case 'cancelled':
        return AppColors.textTertiary;
      default:
        return AppColors.textTertiary;
    }
  }

  String _formatAmount(num amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: colorScheme.primary,
            size: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Sora',
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}