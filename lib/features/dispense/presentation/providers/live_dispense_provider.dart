import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/core/realtime/realtime_client.dart';
import 'package:fuel_ease_flutter/features/dispense/data/models/dispense_request.dart';
import 'package:fuel_ease_flutter/features/dispense/data/repositories/dispense_repository.dart';

enum LiveDispensePhase { awaitingActivation, flowing, paused, completed, error }

class LiveDispenseParams {
  const LiveDispenseParams({
    required this.requestId,
    required this.stationId,
    required this.requestedLiters,
    required this.pricePerLiterTzs,
    this.initialMlDispensed = 0.0,
  });

  final String requestId;
  final String stationId;
  final double requestedLiters;
  final int pricePerLiterTzs;
  final double initialMlDispensed;

  factory LiveDispenseParams.fromRequest(DispenseRequest request) {
    return LiveDispenseParams(
      requestId: request.id,
      stationId: request.stationId,
      requestedLiters: request.requestedLiters,
      pricePerLiterTzs: request.pricePerLiterTzs,
      initialMlDispensed: (request.actualLiters ?? 0) * 1000,
    );
  }

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
    Stream<Map<String, dynamic>> eventStream, {
    DispenseRepository? repository,
    Iterable<Map<String, dynamic>> recentEvents = const [],
  }) : _repository = repository,
       super(
         LiveDispenseState(
           phase: params.initialMlDispensed > 0
               ? LiveDispensePhase.flowing
               : LiveDispensePhase.awaitingActivation,
           requestId: params.requestId,
           requestedLiters: params.requestedLiters,
           pricePerLiterTzs: params.pricePerLiterTzs,
           mlDispensed: params.initialMlDispensed,
           lastEventAt: params.initialMlDispensed > 0 ? DateTime.now() : null,
         ),
       ) {
    _subscription = eventStream.listen(_handleEvent);
    for (final event in recentEvents) {
      _handleEvent(event);
    }
    _syncFromServer();
    _snapshotTicker = Timer.periodic(const Duration(seconds: 2), (_) {
      if (state.phase == LiveDispensePhase.completed ||
          state.phase == LiveDispensePhase.error) {
        return;
      }
      _syncFromServer();
    });
    _staleTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.phase == LiveDispensePhase.flowing && state.isStale) {
        state = state.copyWith(phase: LiveDispensePhase.paused);
      }
    });
  }

  final DispenseRepository? _repository;
  StreamSubscription<Map<String, dynamic>>? _subscription;
  Timer? _staleTicker;
  Timer? _snapshotTicker;
  bool _syncing = false;

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
        final ml =
            (data['ml_dispensed'] as num?)?.toDouble() ?? state.mlDispensed;
        state = state.copyWith(
          phase: LiveDispensePhase.flowing,
          mlDispensed: ml,
          lastEventAt: DateTime.now(),
        );
      case 'dispense_complete':
        final actualMl = (data['actual_ml'] as num?)?.toDouble();
        state = state.copyWith(
          phase: LiveDispensePhase.completed,
          mlDispensed: actualMl ?? state.mlDispensed,
          actualMl: actualMl,
          lastEventAt: DateTime.now(),
        );
      case 'error':
        state = state.copyWith(
          phase: LiveDispensePhase.error,
          errorMessage: data['reason']?.toString() ?? 'Pump error',
        );
    }
  }

  Future<void> _syncFromServer() async {
    final repository = _repository;
    if (repository == null) return;
    if (_syncing) return;
    _syncing = true;
    try {
      final request = await repository.getRequest(state.requestId);
      _applySnapshot(request);
    } catch (_) {
      // Realtime is primary; transient snapshot failures should not disrupt UI.
    } finally {
      _syncing = false;
    }
  }

  void _applySnapshot(DispenseRequest request) {
    if (request.isCompleted) {
      final actualMl = request.actualLiters != null
          ? request.actualLiters! * 1000
          : state.actualMl;
      state = state.copyWith(
        phase: LiveDispensePhase.completed,
        mlDispensed: actualMl ?? state.mlDispensed,
        actualMl: actualMl,
        lastEventAt: DateTime.now(),
      );
      return;
    }

    if (request.isCancelled) {
      state = state.copyWith(
        phase: LiveDispensePhase.error,
        errorMessage: 'Dispense request was cancelled',
      );
      return;
    }

    if (request.isApproved &&
        state.phase == LiveDispensePhase.awaitingActivation) {
      state = state.copyWith(lastEventAt: DateTime.now());
    }

    if (request.isActive &&
        state.phase == LiveDispensePhase.awaitingActivation) {
      state = state.copyWith(
        phase: LiveDispensePhase.flowing,
        lastEventAt: DateTime.now(),
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _staleTicker?.cancel();
    _snapshotTicker?.cancel();
    super.dispose();
  }
}

final liveDispenseProvider = StateNotifierProvider.autoDispose
    .family<LiveDispenseNotifier, LiveDispenseState, LiveDispenseParams>((
      ref,
      params,
    ) {
      final client = ref.watch(realtimeClientProvider);
      final repository = ref.watch(dispenseRepositoryProvider);
      unawaited(client.connect());
      return LiveDispenseNotifier(
        params,
        client.stream,
        repository: repository,
        recentEvents: client.recentEvents(),
      );
    });
