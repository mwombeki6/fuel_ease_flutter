import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/dispense/data/models/create_dispense_response.dart';
import 'package:fuel_ease_flutter/features/dispense/data/models/dispense_request.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/providers/dispense_provider.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/providers/live_dispense_provider.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/screens/live_dispense_screen.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/screens/pin_qr_screen.dart';

enum DispenseRequestDestination { token, live, complete, cancelled }

DispenseRequestDestination destinationForDispenseRequest(
  DispenseRequest request,
) {
  if (request.isCompleted) return DispenseRequestDestination.complete;
  if (request.isCancelled || request.isRejected || request.isExpired) {
    return DispenseRequestDestination.cancelled;
  }
  if (request.isApproved || request.isActive) {
    return DispenseRequestDestination.live;
  }
  if (request.isPending) return DispenseRequestDestination.token;
  return DispenseRequestDestination.cancelled;
}

class DispenseRequestResolverScreen extends ConsumerWidget {
  const DispenseRequestResolverScreen({
    required this.requestId,
    this.createdResponse,
    super.key,
  });

  final String requestId;
  final CreateDispenseResponse? createdResponse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final response = createdResponse;
    if (response != null && response.request.id == requestId) {
      return _CreationResponseResolver(
        response: response,
        serverRequest: ref.watch(dispenseRequestByIdProvider(requestId)),
      );
    }

    return ref
        .watch(dispenseRequestByIdProvider(requestId))
        .when(
          data: (request) => _ResolvedDispenseRequest(request: request),
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, _) => Scaffold(
            appBar: AppBar(title: const Text('Dispense Request')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'This dispense request could not be loaded.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref.invalidate(
                        dispenseRequestByIdProvider(requestId),
                      ),
                      child: const Text('Try Again'),
                    ),
                    TextButton(
                      onPressed: () => context.go(Routes.home),
                      child: const Text('Back to Home'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
  }
}

class _CreationResponseResolver extends StatelessWidget {
  const _CreationResponseResolver({
    required this.response,
    required this.serverRequest,
  });

  final CreateDispenseResponse response;
  final AsyncValue<DispenseRequest> serverRequest;

  @override
  Widget build(BuildContext context) {
    return serverRequest.when(
      data: (request) => _ResolvedDispenseRequest(
        request: request,
        createdResponse: request.isPending ? response : null,
      ),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        appBar: AppBar(title: const Text('Dispense Request')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'The current request status could not be verified. Try again '
                  'before presenting the PIN or QR code.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      context.go(Routes.dispensingRequest(response.request.id)),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResolvedDispenseRequest extends StatelessWidget {
  const _ResolvedDispenseRequest({required this.request, this.createdResponse});

  final DispenseRequest request;
  final CreateDispenseResponse? createdResponse;

  @override
  Widget build(BuildContext context) {
    switch (destinationForDispenseRequest(request)) {
      case DispenseRequestDestination.complete:
        return _DispenseCompleteRedirect(requestId: request.id);
      case DispenseRequestDestination.live:
        return LiveDispenseScreen(
          params: LiveDispenseParams.fromRequest(request),
        );
      case DispenseRequestDestination.cancelled:
        final terminalLabel = switch (request.status) {
          'rejected' => 'rejected',
          'expired' => 'expired',
          _ => 'cancelled',
        };
        return Scaffold(
          appBar: AppBar(title: const Text('Dispense Request')),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cancel_outlined, size: 48),
                const SizedBox(height: 12),
                Text('This dispense request was $terminalLabel.'),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => context.go(Routes.home),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        );
      case DispenseRequestDestination.token:
        final response = createdResponse;
        if (response != null) {
          return PinQrScreen(
            requestId: request.id,
            pin: response.pin,
            qrPayload: response.qrPayload,
            stationId: request.stationId,
            requestedLiters: request.requestedLiters,
            pricePerLiterTzs: request.pricePerLiterTzs,
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Dispense Request')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.hourglass_top_rounded, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'This request is waiting for pump confirmation. For '
                    'security, its PIN and QR code are shown only when the '
                    'request is created.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => context.go(Routes.home),
                    child: const Text('Back to Home'),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }
}

class _DispenseCompleteRedirect extends StatefulWidget {
  const _DispenseCompleteRedirect({required this.requestId});

  final String requestId;

  @override
  State<_DispenseCompleteRedirect> createState() =>
      _DispenseCompleteRedirectState();
}

class _DispenseCompleteRedirectState extends State<_DispenseCompleteRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.pushReplacement(Routes.dispenseComplete(widget.requestId));
      }
    });
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
