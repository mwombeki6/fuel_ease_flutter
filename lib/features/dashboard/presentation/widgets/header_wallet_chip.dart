import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/providers/wallet_provider.dart';

class HeaderWalletChip extends ConsumerWidget {
  const HeaderWalletChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final balance = ref.watch(availableBalanceProvider);
    final formatted = balance == null
        ? '—'
        : NumberFormat.decimalPattern('en_US').format(balance.round());

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.push(Routes.wallet),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Text(
          'TZS $formatted',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: colorScheme.primary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
