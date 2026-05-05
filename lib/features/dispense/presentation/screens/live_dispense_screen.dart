import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/dispense/data/repositories/dispense_repository.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/providers/live_dispense_provider.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';

class LiveDispenseScreen extends ConsumerStatefulWidget {
  const LiveDispenseScreen({required this.params, super.key});

  final LiveDispenseParams params;

  @override
  ConsumerState<LiveDispenseScreen> createState() => _LiveDispenseScreenState();
}

class _LiveDispenseScreenState extends ConsumerState<LiveDispenseScreen> {
  bool _isStopping = false;

  String _appBarTitle(LiveDispensePhase phase) {
    switch (phase) {
      case LiveDispensePhase.connecting:
        return 'Connecting…';
      case LiveDispensePhase.flowing:
        return 'Dispensing…';
      case LiveDispensePhase.paused:
        return 'No Signal';
      case LiveDispensePhase.completed:
        return 'Done';
      case LiveDispensePhase.error:
        return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveDispenseProvider(widget.params));
    final numberFormat = NumberFormat('#,##0');

    ref.listen(liveDispenseProvider(widget.params), (_, next) {
      if (next.phase == LiveDispensePhase.completed && mounted) {
        context.pushReplacement(Routes.dispenseComplete(widget.params.requestId));
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        _showStopDialog(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_appBarTitle(state.phase)),
          automaticallyImplyLeading: false,
          elevation: 0,
        ),
        body: Column(
          children: [
            if (state.phase == LiveDispensePhase.error)
              _ErrorBanner(message: state.errorMessage ?? 'Pump error'),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatusChip(phase: state.phase),
                    const SizedBox(height: 24),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: state.phase == LiveDispensePhase.connecting
                            ? null
                            : state.progressFraction,
                        minHeight: 12,
                        backgroundColor: AppColors.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          state.phase == LiveDispensePhase.error
                              ? AppColors.error
                              : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Primary numbers
                    _BigNumber(
                      value: '${state.litersDispensed.toStringAsFixed(2)} L',
                      label: 'dispensed',
                    ),
                    const SizedBox(height: 8),
                    _BigNumber(
                      value: 'TZS ${numberFormat.format(state.amountChargedTzs)}',
                      label: 'charged so far',
                      valueColor: AppColors.textPrimary,
                      valueFontSize: 28,
                    ),
                    const SizedBox(height: 24),

                    // Secondary info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Requested: ${widget.params.requestedLiters.toStringAsFixed(2)} L',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'TZS ${numberFormat.format(widget.params.pricePerLiterTzs)}/L',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Signal indicator
                    _SignalIndicator(phase: state.phase),
                    const SizedBox(height: 24),

                    // Emergency stop
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isStopping ? null : () => _showStopDialog(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isStopping
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'EMERGENCY STOP',
                                style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStopDialog(BuildContext context) {
    final router = GoRouter.of(context);
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send stop request?'),
        content: const Text(
          'Pump will stop if the connection is still active.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Stop'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true || !mounted) return;
      setState(() => _isStopping = true);
      try {
        await ref
            .read(dispenseRepositoryProvider)
            .cancelRequest(widget.params.requestId);
      } finally {
        if (mounted) {
          setState(() => _isStopping = false);
          router.go(Routes.home);
        }
      }
    });
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.phase});

  final LiveDispensePhase phase;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (phase) {
      LiveDispensePhase.connecting => ('CONNECTING', AppColors.textSecondary),
      LiveDispensePhase.flowing => ('FLOWING', AppColors.success),
      LiveDispensePhase.paused => ('PAUSED', Colors.amber),
      LiveDispensePhase.completed => ('DONE', AppColors.success),
      LiveDispensePhase.error => ('ERROR', AppColors.error),
    };

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _BigNumber extends StatelessWidget {
  const _BigNumber({
    required this.value,
    required this.label,
    this.valueColor = AppColors.primary,
    this.valueFontSize = 40,
  });

  final String value;
  final String label;
  final Color valueColor;
  final double valueFontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: valueFontSize,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SignalIndicator extends StatelessWidget {
  const _SignalIndicator({required this.phase});

  final LiveDispensePhase phase;

  @override
  Widget build(BuildContext context) {
    if (phase == LiveDispensePhase.connecting) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Connecting to pump…',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      );
    }

    final (color, label) = phase == LiveDispensePhase.flowing
        ? (AppColors.success, 'LIVE')
        : (Colors.amber.shade700, 'Waiting for signal…');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 13, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.error.withOpacity(0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
