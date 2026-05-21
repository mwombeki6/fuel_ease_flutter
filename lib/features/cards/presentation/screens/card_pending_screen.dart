import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/cards/data/repositories/cards_repository.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';

class CardPendingScreen extends ConsumerStatefulWidget {
  const CardPendingScreen({required this.cardId, super.key});

  final String cardId;

  @override
  ConsumerState<CardPendingScreen> createState() => _CardPendingScreenState();
}

class _CardPendingScreenState extends ConsumerState<CardPendingScreen> {
  Timer? _pollTimer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    // Poll immediately, then every 30 seconds
    _checkStatus();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _checkStatus();
    });
  }

  Future<void> _checkStatus() async {
    try {
      final card = await ref
          .read(cardsRepositoryProvider)
          .getCardById(widget.cardId);
      if (!mounted) return;
      if (card.isActive) {
        _pollTimer?.cancel();
        context.pushReplacement(Routes.cardDetails(widget.cardId));
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnight,
      appBar: AppBar(
        title: const Text('Card Application'),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                size: 48,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Card Application Submitted',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Your card is being reviewed. This typically takes up to 48 hours. We\'ll notify you when it\'s ready.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondaryDark,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This screen will automatically advance when your card is activated.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textTertiaryDark,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 48),
            OutlinedButton.icon(
              onPressed: () => context.go(Routes.cards),
              icon: const Icon(Icons.credit_card),
              label: const Text('View My Cards'),
            ),
          ],
        ),
      ),
    );
  }
}
