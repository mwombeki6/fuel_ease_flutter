import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fuel_ease_flutter/features/cards/data/models/fuel_card.dart';
import 'package:fuel_ease_flutter/features/cards/presentation/providers/card_sessions_provider.dart';
import 'package:fuel_ease_flutter/features/cards/presentation/providers/cards_provider.dart';
import 'package:fuel_ease_flutter/features/cards/presentation/widgets/flip_fuel_card.dart';
import 'package:fuel_ease_flutter/features/stations/presentation/providers/station_map_provider.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';

/// Card details screen showing full card information
class CardDetailsScreen extends ConsumerWidget {
  const CardDetailsScreen({
    required this.cardId,
    super.key,
  });

  final String cardId;

  // Fix: static DateFormat so it's not re-allocated on every build
  static final _dateFormat = DateFormat('MMM dd, yyyy • HH:mm');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardAsync = ref.watch(cardByIdProvider(cardId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Details'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
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

  Widget _buildContent(BuildContext context, WidgetRef ref, FuelCard card) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Flip card visual
          FlipFuelCard(card: card),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Tap card to flip',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
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
                value: _dateFormat.format(card.createdAt),
                icon: Icons.calendar_today_outlined,
              ),
              _InfoRow(
                label: 'Expires',
                value: _dateFormat.format(card.expiresAt),
                icon: Icons.event_outlined,
                valueColor: card.isExpiringSoon ? AppColors.warning : null,
              ),
              if (card.usedAt != null)
                _InfoRow(
                  label: 'Used On',
                  value: _dateFormat.format(card.usedAt!),
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

          const SizedBox(height: 24),
          _SessionsSection(cardId: card.id),
          const SizedBox(height: 24),
          _StatusTimeline(card: card),

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

  void _shareCard(BuildContext context, FuelCard card) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Share Card Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose how to share your card information',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 20),
            // Fix 2a: label changed from 'Copy Card Number' to 'Copy Card ID'
            // Fix 3: resolve messenger before pop to avoid stale-context snackbar
            _ShareOption(
              icon: Icons.copy_outlined,
              label: 'Copy Card ID',
              onTap: () {
                final messenger = ScaffoldMessenger.of(context);
                Clipboard.setData(
                  ClipboardData(text: card.maskedCardNumber),
                );
                Navigator.of(ctx).pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Card number copied'),
                      ],
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
            // Fix 2b: format expiresAt as MM/yy instead of raw DateTime.toString()
            // Fix 3: resolve messenger before pop
            _ShareOption(
              icon: Icons.text_snippet_outlined,
              label: 'Copy Full Details',
              onTap: () {
                final messenger = ScaffoldMessenger.of(context);
                final text =
                    'Card: ${card.maskedCardNumber}\nExpires: ${DateFormat('MM/yy').format(card.expiresAt)}';
                Clipboard.setData(ClipboardData(text: text));
                Navigator.of(ctx).pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Card details copied'),
                      ],
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _copyCardDetails(BuildContext context, FuelCard card) {
    final details = 'Card: ${card.maskedCardNumber}\nExpires: ${_dateFormat.format(card.expiresAt)}';

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
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
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
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Theme.of(context).colorScheme.onSurface,
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

class _ShareOption extends StatelessWidget {
  const _ShareOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionsSection extends ConsumerWidget {
  const _SessionsSection({required this.cardId});
  final String cardId;

  // Fix: static DateFormat so it's not re-allocated on every build
  static final _dateFmt = DateFormat('MMM d, HH:mm');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fix 4: watch sessions first, then early-return before subscribing to
    // stationMapPinsProvider — avoids a needless provider subscription when
    // there are no sessions to display.
    final sessions = ref.watch(cardSessionsProvider(cardId));
    if (sessions.isEmpty) return const SizedBox.shrink();

    final pinsAsync = ref.watch(stationMapPinsProvider);
    final cs = Theme.of(context).colorScheme;

    final stationNames = pinsAsync.whenOrNull(
          data: (pins) => {for (final p in pins) p.id: p.name},
        ) ??
        {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fuel Sessions',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sessions.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: cs.outline.withValues(alpha: 0.12)),
            itemBuilder: (context, i) {
              final session = sessions[i];
              // Fix 1: guard against stationId shorter than 8 characters
              final sid = session.stationId;
              final stationFallback =
                  'Station …${sid.length > 8 ? sid.substring(sid.length - 8) : sid}';
              final stationName = stationNames[session.stationId] ?? stationFallback;
              final liters = session.actualLiters ?? session.requestedLiters;
              final statusColor = session.isCompleted
                  ? AppColors.success
                  : session.isCancelled
                      ? cs.onSurface.withValues(alpha: 0.4)
                      : AppColors.warning;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.local_gas_station_rounded, size: 18, color: statusColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(stationName,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(
                            '${liters.toStringAsFixed(1)} L • ${_dateFmt.format(session.createdAt)}',
                            style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.55)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        session.formattedStatus,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.card});
  final FuelCard card;

  // Fix: static DateFormat so it's not re-allocated on every build
  static final _dateFmt = DateFormat('MMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final steps = <_TimelineStep>[
      _TimelineStep(
        label: 'Issued',
        date: _dateFmt.format(card.createdAt),
        reached: true,
        isCurrent: card.status == 'pending',
        color: cs.primary,
      ),
      _TimelineStep(
        label: 'Active',
        date: null,
        // Fix: include isCancelled so cancelled cards show Active as reached
        reached: card.isActive || card.status == 'blocked' || card.isExpired || card.isCancelled,
        isCurrent: card.isActive,
        color: AppColors.success,
      ),
      if (card.status == 'blocked')
        _TimelineStep(
          label: 'Blocked',
          date: null,
          reached: true,
          isCurrent: true,
          color: AppColors.error,
        ),
      _TimelineStep(
        label: 'Expired',
        date: card.isExpired ? _dateFmt.format(card.expiresAt) : null,
        reached: card.isExpired,
        isCurrent: card.isExpired && card.status != 'blocked',
        color: cs.onSurface.withValues(alpha: 0.4),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Status',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface),
        ),
        const SizedBox(height: 16),
        ...List.generate(steps.length, (i) {
          final step = steps[i];
          final isLast = i == steps.length - 1;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: step.reached ? step.color : cs.outline.withValues(alpha: 0.3),
                          border: step.isCurrent
                              ? Border.all(color: step.color, width: 2)
                              : null,
                        ),
                        child: step.isCurrent
                            ? Center(
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: step.color),
                                ),
                              )
                            : null,
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(width: 1, color: cs.outline.withValues(alpha: 0.2)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: step.reached ? cs.onSurface : cs.onSurface.withValues(alpha: 0.35),
                        ),
                      ),
                      if (step.date != null)
                        Text(
                          step.date!,
                          style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _TimelineStep {
  const _TimelineStep({
    required this.label,
    required this.date,
    required this.reached,
    required this.isCurrent,
    required this.color,
  });

  final String label;
  final String? date;
  final bool reached;
  final bool isCurrent;
  final Color color;
}
