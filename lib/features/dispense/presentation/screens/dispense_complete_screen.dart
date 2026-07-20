import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/providers/dispense_provider.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/widgets/verification_panel.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';
import 'package:fuel_ease_flutter/shared/widgets/fe_widgets.dart';

class DispenseCompleteScreen extends ConsumerStatefulWidget {
  const DispenseCompleteScreen({required this.requestId, super.key});

  final String requestId;

  @override
  ConsumerState<DispenseCompleteScreen> createState() =>
      _DispenseCompleteScreenState();
}

class _DispenseCompleteScreenState extends ConsumerState<DispenseCompleteScreen>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confettiController;
  late final AnimationController _checkmarkController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );
    _checkmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
      _checkmarkController.forward();
      HapticFeedback.heavyImpact();
      _refreshFinancialState();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _checkmarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requestAsync = ref.watch(
      dispenseRequestByIdProvider(widget.requestId),
    );
    final numberFormat = NumberFormat('#,##0');
    final dateFormat = DateFormat('HH:mm, MMM d');
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Night gradient
          Container(decoration: BoxDecoration(color: colorScheme.surface)),

          // Success glow
          Positioned(
            top: -60,
            left: 0,
            right: 0,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 0.75,
                  colors: [
                    AppColors.success.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 24,
              particleDrag: 0.05,
              emissionFrequency: 0.04,
              gravity: 0.06,
              colors: [
                colorScheme.primary,
                colorScheme.secondary,
                Colors.white,
                AppColors.success,
                const Color(0xFFFFC107),
              ],
            ),
          ),

          // Content
          requestAsync.when(
            data: (request) {
              final liters = (request.actualLiters ?? 0.0) > 0
                  ? request.actualLiters!
                  : request.requestedLiters;
              final cost = (liters * request.pricePerLiterTzs).ceil();

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: LayoutBuilder(
                    builder: (context, c) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: c.maxHeight),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              const Spacer(),

                              // Animated checkmark
                              ScaleTransition(
                                scale: CurvedAnimation(
                                  parent: _checkmarkController,
                                  curve: Curves.easeOutBack,
                                ),
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.success,
                                        AppColors.success.withValues(
                                          alpha: 0.6,
                                        ),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.success.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 36,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 56,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 28),

                              Text(
                                    'Fuel Dispensed!',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                  )
                                  .animate()
                                  .slideY(
                                    begin: 0.3,
                                    end: 0,
                                    duration: 400.ms,
                                    delay: 300.ms,
                                  )
                                  .fadeIn(duration: 350.ms, delay: 300.ms),

                              const SizedBox(height: 32),

                              // Liters
                              AnimatedCounter(
                                    value: liters,
                                    formatter: (v) =>
                                        '${v.toStringAsFixed(2)} L',
                                    style: const TextStyle(
                                      fontSize: 52,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -1,
                                    ),
                                  )
                                  .animate()
                                  .slideY(
                                    begin: 0.3,
                                    end: 0,
                                    duration: 400.ms,
                                    delay: 400.ms,
                                  )
                                  .fadeIn(duration: 350.ms, delay: 400.ms),

                              const SizedBox(height: 8),

                              AnimatedCounter(
                                value: cost.toDouble(),
                                formatter: (v) =>
                                    'TZS ${numberFormat.format(v.toInt())}',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.75),
                                ),
                              ).animate().fadeIn(
                                duration: 350.ms,
                                delay: 500.ms,
                              ),

                              const SizedBox(height: 32),

                              // Details glass card
                              ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 14,
                                        sigmaY: 14,
                                      ),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: colorScheme
                                              .surfaceContainerHighest
                                              .withValues(alpha: 0.9),
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.07,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            _DetailRow(
                                              label: 'Ref',
                                              value: widget.requestId.length > 8
                                                  ? widget.requestId
                                                        .substring(0, 8)
                                                        .toUpperCase()
                                                  : widget.requestId
                                                        .toUpperCase(),
                                            ),
                                            const SizedBox(height: 12),
                                            _DetailRow(
                                              label: 'Time',
                                              value: dateFormat.format(
                                                request.createdAt.toLocal(),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            _DetailRow(
                                              label: 'Status',
                                              value: request.formattedStatus,
                                              valueColor: AppColors.success,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                  .animate()
                                  .slideY(
                                    begin: 0.2,
                                    end: 0,
                                    duration: 400.ms,
                                    delay: 550.ms,
                                  )
                                  .fadeIn(duration: 350.ms, delay: 550.ms),

                              const SizedBox(height: 16),

                              // Live two-guarantee fuel-session verification panel.
                              VerificationPanel(requestId: widget.requestId)
                                  .animate()
                                  .slideY(
                                    begin: 0.2,
                                    end: 0,
                                    duration: 400.ms,
                                    delay: 600.ms,
                                  )
                                  .fadeIn(duration: 350.ms, delay: 600.ms),

                              const Spacer(),

                              // Action buttons
                              Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () async {
                                            await _refreshFinancialState();
                                            if (mounted) {
                                              context.go(
                                                Routes.walletTransactions,
                                              );
                                            }
                                          },
                                          child: Container(
                                            height: 52,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: Colors.white.withValues(
                                                  alpha: 0.15,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              'View History',
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.8,
                                                ),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: GradientButton(
                                          onPressed: () async {
                                            await _refreshFinancialState();
                                            if (mounted) {
                                              context.go(Routes.home);
                                            }
                                          },
                                          label: 'Done',
                                        ),
                                      ),
                                    ],
                                  )
                                  .animate()
                                  .slideY(
                                    begin: 0.3,
                                    end: 0,
                                    duration: 400.ms,
                                    delay: 650.ms,
                                  )
                                  .fadeIn(duration: 350.ms, delay: 650.ms),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 80,
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Fuel dispensed successfully',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),
                    GradientButton(
                      onPressed: () async {
                        await _refreshFinancialState();
                        if (mounted) context.go(Routes.home);
                      },
                      label: 'Done',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshFinancialState() async {
    await ref.read(walletProvider.notifier).refresh();
  }
}

// ── Detail row ─────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.white,
          ),
        ),
      ],
    );
  }
}
