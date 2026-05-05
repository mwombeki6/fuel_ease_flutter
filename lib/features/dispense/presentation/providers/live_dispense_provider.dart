import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/core/realtime/realtime_client.dart';

enum LiveDispensePhase { connecting, flowing, paused, completed, error }

class LiveDispenseParams {
  const LiveDispenseParams({
    required this.requestId,
    required this.stationId,
    required this.requestedLiters,
    required this.pricePerLiterTzs,
  });

  final String requestId;
  final String stationId;
  final double requestedLiters;
  final int pricePerLiterTzs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiveDispenseParams && requestId == other.requestId;

  @override
  int get hashCode => requestId.hashCode;
}

class LiveDispenseState {
  const LiveDispenseState({
    required this.phase,
    required this.requestId,
    required this.requestedLiters,
    required this.pricePerLiterTzs,
    this.mlDispensed = 0.0,
    this.lastEventAt,
    this.actualMl,
    this.errorMessage,
  });

  final LiveDispensePhase phase;
  final String requestId;
  final double requestedLiters;
  final int pricePerLiterTzs;
  final double mlDispensed;
  final DateTime? lastEventAt;
  final double? actualMl;
  final String? errorMessage;

  double get litersDispensed => mlDispensed / 1000;
  int get amountChargedTzs => (litersDispensed * pricePerLiterTzs).ceil();

  double get progressFraction => requestedLiters > 0
      ? (litersDispensed / requestedLiters).clamp(0.0, 1.0)
      : 0.0;

  bool get isStale =>
      lastEventAt != null &&
      DateTime.now().difference(lastEventAt!).inSeconds > 5;

  LiveDispenseState copyWith({
    LiveDispensePhase? phase,
    double? mlDispensed,
    DateTime? lastEventAt,
    double? actualMl,
    String? errorMessage,
  }) {
    return LiveDispenseState(
      phase: phase ?? this.phase,
      requestId: requestId,
      requestedLiters: requestedLiters,
      pricePerLiterTzs: pricePerLiterTzs,
      mlDispensed: mlDispensed ?? this.mlDispensed,
      lastEventAt: lastEventAt ?? this.lastEventAt,
      actualMl: actualMl ?? this.actualMl,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class LiveDispenseNotifier extends StateNotifier<LiveDispenseState> {
  LiveDispenseNotifier(
    LiveDispenseParams params,
    Stream<Map<String, dynamic>> eventStream,
  ) : super(LiveDispenseState(
          phase: LiveDispensePhase.connecting,
          requestId: params.requestId,
          requestedLiters: params.requestedLiters,
          pricePerLiterTzs: params.pricePerLiterTzs,
        )) {
    _subscription = eventStream.listen(_handleEvent);
    _staleTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.phase == LiveDispensePhase.flowing && state.isStale) {
        state = state.copyWith(phase: LiveDispensePhase.paused);
      }
    });
  }

  StreamSubscription<Map<String, dynamic>>? _subscription;
  Timer? _staleTicker;

  void _handleEvent(Map<String, dynamic> raw) {
    // Server sends WebMessage: {"channel":"user:<id>","event":"...","data":{...}}
    final eventType = raw['event']?.toString();
    if (eventType == null) return;

    final data = raw['data'] is Map
        ? Map<String, dynamic>.from(raw['data'] as Map)
        : <String, dynamic>{};

    final requestId = data['request_id']?.toString();
    if (requestId != state.requestId) return; // event isolation

    switch (eventType) {
      case 'dispensing_progress':
        final ml = (data['ml_dispensed'] as num?)?.toDouble() ?? state.mlDispensed;
        state = state.copyWith(
          phase: LiveDispensePhase.flowing,
          mlDispensed: ml,
          lastEventAt: DateTime.now(),
        );
      case 'dispense_complete':
        final actualMl = (data['actual_ml'] as num?)?.toDouble();
        state = state.copyWith(
          phase: LiveDispensePhase.completed,
          actualMl: actualMl,
        );
      case 'error':
        state = state.copyWith(
          phase: LiveDispensePhase.error,
          errorMessage: data['reason']?.toString() ?? 'Pump error',
        );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _staleTicker?.cancel();
    super.dispose();
  }
}

final liveDispenseProvider = StateNotifierProvider.autoDispose
    .family<LiveDispenseNotifier, LiveDispenseState, LiveDispenseParams>(
  (ref, params) {
    final client = ref.watch(realtimeClientProvider);
    return LiveDispenseNotifier(params, client.stream);
  },
);
