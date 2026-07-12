import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:fuel_ease_flutter/features/dispense/data/models/dispense_request.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/providers/dispense_provider.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';
import 'package:fuel_ease_flutter/shared/theme/app_text_styles.dart';

final _litersFormat = NumberFormat('#,##0.##');
final _currencyFormat = NumberFormat('#,###');
final _dateFormat = DateFormat('MMM dd, yyyy • HH:mm');

class DispenseHistoryScreen extends ConsumerWidget {
  const DispenseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsState = ref.watch(dispenseProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Dispense History'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.read(dispenseProvider.notifier).refresh(),
          ),
        ],
      ),
      body: requestsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          error: error.toString(),
          onRetry: () => ref.read(dispenseProvider.notifier).refresh(),
        ),
        data: (requests) {
          if (requests.isEmpty) return const _EmptyView();
          return RefreshIndicator(
            onRefresh: () => ref.read(dispenseProvider.notifier).refresh(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _DispenseRequestItem(
                request: requests[index],
                onTap: () => _showDetail(context, requests[index]),
              ),
            ),
          );
        },
      ),
    );
  }
}

void _showDetail(BuildContext context, DispenseRequest req) {
  final colorScheme = Theme.of(context).colorScheme;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _DetailSheet(request: req),
  );
}

// ─── List item ──────────────────────────────────────────────────────────────

class _DispenseRequestItem extends StatelessWidget {
  const _DispenseRequestItem({
    required this.request,
    required this.onTap,
  });

  final DispenseRequest request;
  final VoidCallback onTap;

  Color _statusColor() {
    switch (request.status) {
      case 'completed':
        return AppColors.success;
      case 'active':
      case 'approved':
        return AppColors.info;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondaryDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_gas_station, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_litersFormat.format(request.requestedLiters)} L',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        _StatusBadge(status: request.status, color: color),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_currencyFormat.format(request.estimatedCostTzs)} TZS',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dateFormat.format(request.createdAt),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                    ),
                    if (request.isCompleted && request.actualLiters != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Dispensed: ${_litersFormat.format(request.actualLiters!)} L',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right,
                  color: colorScheme.onSurface.withValues(alpha: 0.7), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});
  final String status;
  final Color color;

  String get _label {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─── Detail sheet ────────────────────────────────────────────────────────────

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({required this.request});
  final DispenseRequest request;

  Color get _statusColor {
    switch (request.status) {
      case 'completed':
        return AppColors.success;
      case 'active':
      case 'approved':
        return AppColors.info;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondaryDark;
    }
  }

  IconData get _statusIcon {
    switch (request.status) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'active':
        return Icons.local_gas_station;
      case 'approved':
        return Icons.thumb_up_outlined;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.hourglass_empty_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final liters = request.actualLiters ?? request.requestedLiters;
    final cost = (liters * request.pricePerLiterTzs).ceil();
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scrollCtrl) => SingleChildScrollView(
        controller: scrollCtrl,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Status hero
            Center(
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_statusIcon, color: _statusColor, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(request.formattedStatus,
                      style: AppTextStyles.titleMedium
                          .copyWith(color: _statusColor)),
                  const SizedBox(height: 4),
                  Text(
                    '${_litersFormat.format(request.actualLiters ?? request.requestedLiters)} L',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${_currencyFormat.format(cost)} TZS',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Details card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                children: [
                  _Row(
                    label: 'Requested',
                    value:
                        '${_litersFormat.format(request.requestedLiters)} L',
                  ),
                  if (request.actualLiters != null)
                    _Row(
                      label: 'Dispensed',
                      value:
                          '${_litersFormat.format(request.actualLiters!)} L',
                      valueColor: AppColors.success,
                    ),
                  _Row(
                    label: 'Price/L',
                    value:
                        '${_currencyFormat.format(request.pricePerLiterTzs)} TZS',
                  ),
                  _Row(
                    label: 'Requested on',
                    value: _dateFormat.format(request.createdAt),
                  ),
                  if (request.completedAt != null)
                    _Row(
                      label: 'Completed',
                      value: _dateFormat.format(request.completedAt!),
                    ),
                  _Row(
                    label: 'Status',
                    value: request.formattedStatus,
                    valueColor: _statusColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Request ID row with copy button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Request ID',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7))),
                      const SizedBox(height: 2),
                      Text(
                        request.id,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontFamily: 'monospace',
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  tooltip: 'Copy ID',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: request.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Request ID copied'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7))),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty / error states ────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_gas_station_outlined,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No dispense requests yet',
              style: AppTextStyles.titleSmall.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your fuel dispense history will appear here.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(error,
                style: AppTextStyles.bodySmall
                    .copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                textAlign: TextAlign.center),
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
