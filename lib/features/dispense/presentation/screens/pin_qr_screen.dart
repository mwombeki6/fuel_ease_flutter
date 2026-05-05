import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/dispense/data/models/dispense_request.dart';
import 'package:fuel_ease_flutter/features/dispense/data/repositories/dispense_repository.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/providers/live_dispense_provider.dart';
import 'package:fuel_ease_flutter/shared/theme/app_colors.dart';

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

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _startPolling();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
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
        if (request.isActive && mounted) {
          _pollTimer?.cancel();
          _countdownTimer?.cancel();
          context.pushReplacement(
            Routes.liveDispense(widget.requestId),
            extra: LiveDispenseParams(
              requestId: widget.requestId,
              stationId: widget.stationId,
              requestedLiters: widget.requestedLiters,
              pricePerLiterTzs: widget.pricePerLiterTzs,
            ),
          );
        } else if (request.isCompleted) {
          _pollTimer?.cancel();
          _countdownTimer?.cancel();
          if (mounted) context.pushReplacement(Routes.dispenseComplete(widget.requestId));
        } else if (request.isCancelled) {
          _pollTimer?.cancel();
          _countdownTimer?.cancel();
        }
      } catch (e) {
        if (mounted) setState(() => _pollError = e.toString());
      }
    });
  }

  Future<void> _cancelRequest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text('Are you sure you want to cancel this dispense request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);
    try {
      await ref
          .read(dispenseRepositoryProvider)
          .cancelRequest(widget.requestId);
      _pollTimer?.cancel();
      _countdownTimer?.cancel();
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel: $e'),
            backgroundColor: AppColors.error,
          ),
        );
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fuel Token'),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Status chip
            _StatusChip(status: status),
            const SizedBox(height: 32),

            if (isExpired || isCancelled) ...[
              _ExpiredOrCancelledBanner(isCancelled: isCancelled),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () =>
                    context.pushReplacement(Routes.createDispensingRequest),
                icon: const Icon(Icons.refresh),
                label: const Text('Create New Request'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else ...[
              // PIN display
              _PinDisplay(pin: widget.pin),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.pin));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN copied')),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy PIN'),
              ),
              const SizedBox(height: 32),

              // QR code
              const Text(
                'Or scan this QR code at the pump',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: widget.qrPayload,
                  version: QrVersions.auto,
                  size: 200,
                ),
              ),
              const SizedBox(height: 32),

              // Countdown
              _CountdownTimer(
                formatted: _formatCountdown(),
                remaining: _remainingSeconds,
              ),
              const SizedBox(height: 32),

              // Cancel button
              OutlinedButton.icon(
                onPressed: _isCancelling ? null : _cancelRequest,
                icon: _isCancelling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cancel_outlined),
                label: const Text('Cancel Request'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error),
                ),
              ),
            ],

            if (_pollError != null) ...[
              const SizedBox(height: 16),
              Text(
                'Status update error: $_pollError',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PinDisplay extends StatelessWidget {
  const _PinDisplay({required this.pin});
  final String pin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Enter this PIN at the pump',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            pin.split('').join('  '),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}

class _CountdownTimer extends StatelessWidget {
  const _CountdownTimer({
    required this.formatted,
    required this.remaining,
  });

  final String formatted;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final isUrgent = remaining < 60;
    return Column(
      children: [
        Text(
          'Expires in',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          formatted,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: isUrgent ? AppColors.error : AppColors.textPrimary,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'approved':
        color = AppColors.info;
        break;
      case 'active':
        color = AppColors.success;
        break;
      case 'completed':
        color = AppColors.success;
        break;
      case 'cancelled':
        color = AppColors.error;
        break;
      default:
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiredOrCancelledBanner extends StatelessWidget {
  const _ExpiredOrCancelledBanner({required this.isCancelled});
  final bool isCancelled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          isCancelled ? Icons.cancel : Icons.timer_off,
          size: 64,
          color: AppColors.error,
        ),
        const SizedBox(height: 16),
        Text(
          isCancelled ? 'Request Cancelled' : 'PIN Expired',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isCancelled
              ? 'This dispense request has been cancelled.'
              : 'The 15-minute window has passed. Create a new request.',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
