import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/providers/dispense_provider.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';

class DispenseCompleteScreen extends ConsumerWidget {
  const DispenseCompleteScreen({required this.requestId, super.key});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(dispenseRequestByIdProvider(requestId));
    final numberFormat = NumberFormat('#,##0');
    final dateFormat = DateFormat('HH:mm, MMM d');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: requestAsync.when(
        data: (request) {
          final liters = (request.actualLiters ?? 0.0) > 0
              ? request.actualLiters!
              : request.requestedLiters;
          final cost = (liters * request.pricePerLiterTzs).ceil();

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),

                  // Checkmark
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: AppColors.success,
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Fuel Dispensed',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Primary numbers
                  Text(
                    '${liters.toStringAsFixed(2)} L',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'TZS ${numberFormat.format(cost)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Details card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _DetailRow(
                          label: 'Ref',
                          value: requestId.length > 8
                              ? requestId.substring(0, 8).toUpperCase()
                              : requestId.toUpperCase(),
                        ),
                        const SizedBox(height: 8),
                        _DetailRow(
                          label: 'Time',
                          value: dateFormat.format(request.createdAt.toLocal()),
                        ),
                        const SizedBox(height: 8),
                        _DetailRow(
                          label: 'Status',
                          value: request.formattedStatus,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.go(Routes.walletTransactions),
                          child: const Text('View History'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.go(Routes.home),
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 72),
                const SizedBox(height: 24),
                const Text(
                  'Fuel dispensed successfully',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go(Routes.home),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14, color: AppColors.textSecondary)),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      ],
    );
  }
}
