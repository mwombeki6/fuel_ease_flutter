import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fuel_ease_flutter/features/cards/presentation/providers/cards_provider.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';

/// Card details screen showing full card information
class CardDetailsScreen extends ConsumerWidget {
  const CardDetailsScreen({
    required this.cardId,
    super.key,
  });

  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardAsync = ref.watch(cardByIdProvider(cardId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Card Details'),
        elevation: 0,
      ),
      body: cardAsync.when(
        data: (card) => _buildContent(context, ref, card),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => _buildError(context, ref, error),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, dynamic card) {
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card visual representation
          Container(
            height: 220,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: card.isActive
                  ? AppColors.primaryGradient
                  : LinearGradient(
                      colors: [Colors.grey.shade600, Colors.grey.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (card.isActive ? AppColors.primary : Colors.grey)
                      .withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status and logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.local_gas_station,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        card.formattedStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // Card number
                Text(
                  card.cardNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 8),

                // Expiry
                Text(
                  'Expires ${card.expiresAt.month.toString().padLeft(2, '0')}/${card.expiresAt.year}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 20),

                // CVV (shown once on creation, hidden afterwards)
                Text(
                  card.cvv != null ? 'CVV: ${card.cvv}' : 'CVV: ***',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons (only for active cards)
          if (card.isActive) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareCard(context, card),
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyCardDetails(context, card),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Details'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Card information
          _InfoSection(
            title: 'Card Information',
            children: [
              if (card.stationName != null)
                _InfoRow(
                  label: 'Station',
                  value: card.stationName!,
                  icon: Icons.location_on_outlined,
                ),
              if (card.recipientName != null)
                _InfoRow(
                  label: 'Recipient',
                  value: card.recipientName!,
                  icon: Icons.person_outline,
                ),
              if (card.recipientPhone != null)
                _InfoRow(
                  label: 'Phone',
                  value: card.recipientPhone!,
                  icon: Icons.phone_outlined,
                ),
              _InfoRow(
                label: 'Created',
                value: card.createdAt != null
                    ? dateFormat.format(card.createdAt!)
                    : 'N/A',
                icon: Icons.calendar_today_outlined,
              ),
              if (card.expiresAt != null)
                _InfoRow(
                  label: 'Expires',
                  value: dateFormat.format(card.expiresAt!),
                  icon: Icons.event_outlined,
                  valueColor: card.isExpiringSoon ? AppColors.warning : null,
                ),
              if (card.usedAt != null)
                _InfoRow(
                  label: 'Used On',
                  value: dateFormat.format(card.usedAt!),
                  icon: Icons.check_circle_outline,
                ),
              if (card.usedBy != null)
                _InfoRow(
                  label: 'Used By',
                  value: card.usedBy!,
                  icon: Icons.person_outline,
                ),
            ],
          ),

          // Cancel button (only for active cards)
          if (card.isActive) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _cancelCard(context, ref, card.id),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel Card'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _shareCard(BuildContext context, dynamic card) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon'),
      ),
    );
  }

  void _copyCardDetails(BuildContext context, dynamic card) {
    final details = 'Card: ${card.maskedCardNumber}\nExpires: ${card.expiresAt}';

    Clipboard.setData(ClipboardData(text: details));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Card details copied to clipboard'),
          ],
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _cancelCard(
      BuildContext context, WidgetRef ref, String cardId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Card'),
        content: const Text(
          'Are you sure you want to cancel this card? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(cardsProvider.notifier).cancelCard(cardId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Card cancelled successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel card: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
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
              'Failed to load card',
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
                ref.invalidate(cardByIdProvider(cardId));
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

/// Information section widget
class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

/// Information row widget
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
