import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/providers/live_dispense_provider.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';
import 'package:fuel_ease_flutter/shared/widgets/fe_widgets.dart';

class LiveDispenseScreen extends ConsumerStatefulWidget {
  const LiveDispenseScreen({required this.params, super.key});

  final LiveDispenseParams params;

  @override
  ConsumerState<LiveDispenseScreen> createState() => _LiveDispenseScreenState();
}

class _LiveDispenseScreenState extends ConsumerState<LiveDispenseScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveDispenseProvider(widget.params));
    final numberFormat = NumberFormat('#,##0');
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen(liveDispenseProvider(widget.params), (_, next) {
      if (next.phase == LiveDispensePhase.completed && mounted) {
        context.pushReplacement(
          Routes.dispenseComplete(widget.params.requestId),
        );
      }
    });

    final (phaseLabel, phaseColor) = switch (state.phase) {
      LiveDispensePhase.awaitingActivation => (
        'WAITING',
        Colors.white.withValues(alpha: 0.5),
      ),
      LiveDispensePhase.flowing => ('FLOWING', AppColors.success),
      LiveDispensePhase.paused => ('PAUSED', Colors.amber),
      LiveDispensePhase.completed => ('DONE', AppColors.success),
      LiveDispensePhase.error => ('ERROR', AppColors.error),
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        _showLeaveDialog(context);
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Night gradient
            Container(decoration: BoxDecoration(color: colorScheme.surface)),

            // Ambient glow behind the numbers
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 0.7,
                    colors: [
                      (state.phase == LiveDispensePhase.error
                              ? AppColors.error
                              : colorScheme.primary)
                          .withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        const SizedBox(width: 40),
                        Expanded(
                          child: Text(
                            _appBarTitle(state.phase),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        // Phase badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: phaseColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: phaseColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            phaseLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: phaseColor,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Error banner
                  if (state.phase == LiveDispensePhase.error)
                    _ErrorBanner(message: state.errorMessage ?? 'Pump error'),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),

                          // Live indicator
                          _LiveSignalRow(phase: state.phase),

                          const SizedBox(height: 28),

                          // Gradient progress bar
                          _GradientProgressBar(
                            value:
                                state.phase ==
                                    LiveDispensePhase.awaitingActivation
                                ? null
                                : state.progressFraction,
                            isError: state.phase == LiveDispensePhase.error,
                          ),

                          const SizedBox(height: 40),

                          // Primary: liters dispensed
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'dispensed',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.4),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                AnimatedCounter(
                                  value: state.litersDispensed,
                                  formatter: (v) => '${v.toStringAsFixed(2)} L',
                                  style: const TextStyle(
                                    fontSize: 56,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Secondary: TZS charged
                          Center(
                            child: AnimatedCounter(
                              value: state.amountChargedTzs.toDouble(),
                              formatter: (v) =>
                                  'TZS ${numberFormat.format(v.toInt())}',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Context row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _ContextChip(
                                label:
                                    'Requested: ${widget.params.requestedLiters.toStringAsFixed(2)} L',
                              ),
                              const SizedBox(width: 10),
                              _ContextChip(
                                label:
                                    '${numberFormat.format(widget.params.pricePerLiterTzs)} TZS/L',
                              ),
                            ],
                          ),

                          const Spacer(),

                          // This app has no endpoint that can stop an active pump.
                          GestureDetector(
                            onTap: () => _showLeaveDialog(context),
                            child: Container(
                              height: 56,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'LEAVE LIVE VIEW',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _appBarTitle(LiveDispensePhase phase) => switch (phase) {
    LiveDispensePhase.awaitingActivation => 'Waiting for Flow',
    LiveDispensePhase.flowing => 'Dispensing…',
    LiveDispensePhase.paused => 'No Signal',
    LiveDispensePhase.completed => 'Done',
    LiveDispensePhase.error => 'Error',
  };

  Future<void> _showLeaveDialog(BuildContext context) async {
    final router = GoRouter.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Leave live view?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This does not stop an active pump. Fueling may continue while you '
          'return to the home screen.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Stay',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Leave',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) router.go(Routes.home);
  }
}

// ── Live signal row ────────────────────────────────────────────────────────

class _LiveSignalRow extends StatelessWidget {
  const _LiveSignalRow({required this.phase});

  final LiveDispensePhase phase;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (phase == LiveDispensePhase.awaitingActivation) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Pump authorized. Waiting for flow…',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      );
    }

    if (phase == LiveDispensePhase.flowing) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const PulsingDot(color: AppColors.success, size: 10),
          const SizedBox(width: 8),
          Text(
            'LIVE',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.success,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      );
    }

    final (color, label) = phase == LiveDispensePhase.paused
        ? (Colors.amber, 'Waiting for signal…')
        : (AppColors.error, phase.name.toUpperCase());

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Gradient progress bar ─────────────────────────────────────────────────

class _GradientProgressBar extends StatelessWidget {
  const _GradientProgressBar({required this.value, required this.isError});

  final double? value;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          // Track
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          // Animated fill
          LayoutBuilder(
            builder: (context, constraints) {
              final fillWidth = value == null
                  ? constraints.maxWidth
                  : constraints.maxWidth * value!.clamp(0.0, 1.0);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                height: 10,
                width: fillWidth,
                decoration: BoxDecoration(
                  gradient: isError
                      ? LinearGradient(
                          colors: [
                            AppColors.error,
                            AppColors.error.withValues(alpha: 0.7),
                          ],
                        )
                      : AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            },
          ),
          // Shimmer on indeterminate
          if (value == null)
            Container(
              height: 10,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: const LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.transparent),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Context chip ───────────────────────────────────────────────────────────

class _ContextChip extends StatelessWidget {
  const _ContextChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

// ── Error banner ───────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.error.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.error,
            size: 18,
          ),
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
