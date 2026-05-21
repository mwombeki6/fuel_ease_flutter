import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';

/// Cards statistics overview card
class CardsStatsCard extends StatelessWidget {
  const CardsStatsCard({
    required this.activeCount,
    required this.totalValue,
    required this.usedCount,
    super.key,
  });

  final int activeCount;
  final double totalValue;
  final int usedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Icon(
                Icons.credit_card,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'My Fuel Cards',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats grid
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Active Cards',
                  value: activeCount.toString(),
                  icon: Icons.check_circle_outline,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Total Value',
                  value: '${NumberFormat('#,##0').format(totalValue)} L',
                  icon: Icons.local_gas_station,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Used',
                  value: usedCount.toString(),
                  icon: Icons.history,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Individual stat item
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.8),
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
