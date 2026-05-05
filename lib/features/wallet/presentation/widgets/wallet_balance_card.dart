import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:fuel_ease_flutter/features/wallet/data/models/wallet.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';

/// Wallet balance display card
class WalletBalanceCard extends StatelessWidget {
  const WalletBalanceCard({
    required this.wallet,
    this.onRecharge,
    super.key,
  });

  final Wallet wallet;
  final VoidCallback? onRecharge;

  @override
  Widget build(BuildContext context) {

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Wallet Balance',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: wallet.isActive
                      ? Colors.white.withOpacity(0.2)
                      : Colors.red.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  wallet.status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Available Balance
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${NumberFormat('#,##0').format(wallet.balanceTzs)} TZS',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Available Balance',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (onRecharge != null) ...[
            const SizedBox(height: 24),
            // Recharge button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRecharge,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text('Top Up Wallet'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
