import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:fuel_ease_flutter/core/realtime/realtime_client.dart';
import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/dispense/data/models/dispense_request.dart';
import 'package:fuel_ease_flutter/features/dispense/data/repositories/dispense_repository.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/providers/live_dispense_provider.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';
import 'package:fuel_ease_flutter/shared/widgets/fe_widgets.dart';

const _pinTtlSeconds = 15 * 60; // 15 minutes

class PinQrScreen extends ConsumerStatefulWidget {
  const PinQrScreen({
    required this.requestId,
    required this.pin,
    required this.qrPayload,
    required this.stationId,
    required this.requestedLiters,
    required this.pricePerLiterTzs,
    super.key,
  });

  final String requestId;
  final String pin;
  final String qrPayload;
  final String stationId;
  final double requestedLiters;
  final int pricePerLiterTzs;

  @override
  ConsumerState<PinQrScreen> createState() => _PinQrScreenState();
}

class _PinQrScreenState extends ConsumerState<PinQrScreen> {
  int _remainingSeconds = _pinTtlSeconds;
  DispenseRequest? _latestRequest;
  String? _pollError;
  bool _isCancelling = false;

  Timer? _countdownTimer;
  Timer? _pollTimer;
  StreamSubscription<Map<String, dynamic>>? _realtimeSubscription;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _startRealtimeListener();
    _startPolling();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _countdownTimer?.cancel();
        }
      });
    });
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      try {
        final request = await ref
            .read(dispenseRepositoryProvider)
            .getRequest(widget.requestId);
        if (!mounted) return;
        setState(() {
          _latestRequest = request;
          _pollError = null;
        });
        if ((request.isActive || request.isApproved) && mounted) {
          _goLive();
        } else if (request.isCompleted) {
          _goComplete();
        } else if (request.isCancelled) {
          _pollTimer?.cancel();
          _countdownTimer?.cancel();
        }
      } catch (e) {
        if (mounted) setState(() => _pollError = e.toString());
      }
    });
  }

  void _startRealtimeListener() {
    ref.read(realtimeClientProvider).connect();
    _realtimeSubscription =
        ref.read(realtimeClientProvider).stream.listen((raw) {
      if (!mounted || _hasNavigated) return;
      final eventType = raw['event']?.toString();
      if (eventType == null) return;

      final data = raw['data'] is Map
          ? Map<String, dynamic>.from(raw['data'] as Map)
          : <String, dynamic>{};
      if (data['request_id']?.toString() != widget.requestId) return;

      if (eventType == 'dispensing_progress') {
        _goLive(
          initialMlDispensed:
              (data['ml_dispensed'] as num?)?.toDouble() ?? 0.0,
        );
      } else if (eventType == 'dispense_complete') {
        _goComplete();
      }
    });
  }

  void _goLive({double initialMlDispensed = 0.0}) {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    _realtimeSubscription?.cancel();
    context.pushReplacement(
      Routes.liveDispense(widget.requestId),
      extra: LiveDispenseParams(
        requestId: widget.requestId,
        stationId: widget.stationId,
        requestedLiters: widget.requestedLiters,
        pricePerLiterTzs: widget.pricePerLiterTzs,
        initialMlDispensed: initialMlDispensed,
      ),
    );
  }

  void _goComplete() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    _realtimeSubscription?.cancel();
    context.pushReplacement(Routes.dispenseComplete(widget.requestId));
  }

  Future<void> _cancelRequest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DarkDialog(
        title: 'Cancel Request',
        message: 'Are you sure you want to cancel this dispense request?',
        confirmLabel: 'Cancel Request',
        confirmColor: AppColors.error,
        onCancel: () => Navigator.of(ctx).pop(false),
        onConfirm: () => Navigator.of(ctx).pop(true),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);
    try {
      await ref.read(dispenseRepositoryProvider).cancelRequest(widget.requestId);
      _pollTimer?.cancel();
      _countdownTimer?.cancel();
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to cancel: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  String _formatCountdown() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final status = _latestRequest?.status ?? 'pending';
    final isExpired = _remainingSeconds == 0;
    final isCancelled = _latestRequest?.isCancelled ?? false;
    final isUrgent = _remainingSeconds < 60;

    return Scaffold(
      backgroundColor: AppColors.midnight,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Night gradient
          Container(decoration: BoxDecoration(gradient: AppColors.nightGradient)),

          // Ambient glow
          Positioned(
            top: -80,
            left: 0,
            right: 0,
            child: Container(
              height: 350,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 0.7,
                  colors: [AppColors.brandGlow, Colors.transparent],
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
                      IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: Colors.white.withValues(alpha: 0.6)),
                        onPressed: isExpired || isCancelled ? () => context.pop() : null,
                      ),
                      const Expanded(
                        child: Text(
                          'Fuel Token',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      _StatusPill(status: status),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                    child: Column(
                      children: [
                        if (isExpired || isCancelled) ...[
                          _ExpiredOrCancelledView(
                            isCancelled: isCancelled,
                            onRetry: () => context.pushReplacement(Routes.createDispensingRequest),
                          ),
                        ] else ...[
                          // PIN section
                          _PinDisplay(pin: widget.pin)
                              .animate()
                              .scale(
                                begin: const Offset(0.9, 0.9),
                                duration: 400.ms,
                                curve: Curves.easeOutBack,
                              )
                              .fadeIn(duration: 350.ms),

                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: widget.pin));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('PIN copied to clipboard'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Text(
                              'Tap to copy PIN',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.brand.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // QR section
                          Text(
                            'Or scan this QR code at the pump',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          _QrContainer(payload: widget.qrPayload)
                              .animate(delay: 100.ms)
                              .fadeIn(duration: 400.ms)
                              .scale(begin: const Offset(0.95, 0.95), duration: 350.ms),

                          const SizedBox(height: 32),

                          // Arc countdown
                          _ArcCountdown(
                            remaining: _remainingSeconds,
                            total: _pinTtlSeconds,
                            formatted: _formatCountdown(),
                            isUrgent: isUrgent,
                          ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

                          const SizedBox(height: 32),

                          // Cancel button
                          GestureDetector(
                            onTap: _isCancelling ? null : _cancelRequest,
                            child: Container(
                              width: double.infinity,
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.error.withValues(alpha: 0.5),
                                ),
                                color: AppColors.error.withValues(alpha: 0.08),
                              ),
                              child: _isCancelling
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.error,
                                      ),
                                    )
                                  : Text(
                                      'Cancel Request',
                                      style: TextStyle(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                            ),
                          ),

                          if (_pollError != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Status check failed — retrying…',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ],
                    ),
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

// ── PIN display ────────────────────────────────────────────────────────────

class _PinDisplay extends StatelessWidget {
  const _PinDisplay({required this.pin});
  final String pin;

  @override
  Widget build(BuildContext context) {
    final digits = pin.split('');
    return Column(
      children: [
        Text(
          'Enter this PIN at the pump',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandGlow,
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < digits.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Text(
                      digits[i],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── QR container ───────────────────────────────────────────────────────────

class _QrContainer extends StatelessWidget {
  const _QrContainer({required this.payload});
  final String payload;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevatedDark.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: payload,
              version: QrVersions.auto,
              size: 180,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Arc countdown ──────────────────────────────────────────────────────────

class _ArcCountdown extends StatelessWidget {
  const _ArcCountdown({
    required this.remaining,
    required this.total,
    required this.formatted,
    required this.isUrgent,
  });

  final int remaining;
  final int total;
  final String formatted;
  final bool isUrgent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(130, 130),
            painter: _ArcPainter(
              fraction: remaining / total,
              isUrgent: isUrgent,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatted,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isUrgent ? AppColors.error : Colors.white,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'remaining',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.fraction, required this.isUrgent});

  final double fraction;
  final bool isUrgent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Track ring
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.07);
    canvas.drawCircle(center, radius, trackPaint);

    if (fraction <= 0) return;

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    if (isUrgent) {
      progressPaint.color = AppColors.error;
    } else {
      progressPaint.shader = LinearGradient(
        colors: [AppColors.brand, AppColors.brandCyan],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.fraction != fraction || old.isUrgent != isUrgent;
}

// ── Status pill ────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'approved' => AppColors.info,
      'active' => AppColors.success,
      'completed' => AppColors.success,
      'cancelled' => AppColors.error,
      _ => Colors.white.withValues(alpha: 0.4),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Expired / cancelled view ───────────────────────────────────────────────

class _ExpiredOrCancelledView extends StatelessWidget {
  const _ExpiredOrCancelledView({
    required this.isCancelled,
    required this.onRetry,
  });

  final bool isCancelled;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
          ),
          child: Icon(
            isCancelled ? Icons.cancel_rounded : Icons.timer_off_rounded,
            size: 48,
            color: AppColors.error,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          isCancelled ? 'Request Cancelled' : 'PIN Expired',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isCancelled
              ? 'This dispense request has been cancelled.'
              : 'The 15-minute window has passed. Create a new request.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.45),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),
        GradientButton(
          onPressed: onRetry,
          label: 'Create New Request',
        ),
      ],
    );
  }
}

// ── Dark dialog ────────────────────────────────────────────────────────────

class _DarkDialog extends StatelessWidget {
  const _DarkDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onCancel,
    required this.onConfirm,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceElevatedDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
      content: Text(
        message,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text('No', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
        ),
        TextButton(
          onPressed: onConfirm,
          child: Text(confirmLabel,
              style: TextStyle(color: confirmColor, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
