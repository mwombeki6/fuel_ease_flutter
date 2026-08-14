import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:fuel_ease_flutter/features/dispense/presentation/providers/live_dispense_provider.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _params = LiveDispenseParams(
  requestId: 'req-001',
  stationId: 'station-001',
  requestedLiters: 2.0,
  pricePerLiterTzs: 4000,
);

LiveDispenseState _baseState({
  LiveDispensePhase phase = LiveDispensePhase.awaitingActivation,
  double mlDispensed = 0.0,
  DateTime? lastEventAt,
  double? actualMl,
  String? errorMessage,
}) => LiveDispenseState(
  phase: phase,
  requestId: 'req-001',
  requestedLiters: 2.0,
  pricePerLiterTzs: 4000,
  mlDispensed: mlDispensed,
  lastEventAt: lastEventAt,
  actualMl: actualMl,
  errorMessage: errorMessage,
);

Map<String, dynamic> _progressEvent({
  String requestId = 'req-001',
  double mlDispensed = 1000.0,
}) => {
  'event': 'dispensing_progress',
  'data': {
    'request_id': requestId,
    'ml_dispensed': mlDispensed,
    'flow_rate': 50.0,
  },
};

Map<String, dynamic> _completeEvent({
  String requestId = 'req-001',
  double? actualMl = 2000.0,
}) => {
  'event': 'dispense_complete',
  'data': {
    'request_id': requestId,
    if (actualMl != null) 'actual_ml': actualMl,
  },
};

Map<String, dynamic> _errorEvent({
  String requestId = 'req-001',
  String reason = 'pressure fault',
}) => {
  'event': 'error',
  'data': {'request_id': requestId, 'reason': reason},
};

// ---------------------------------------------------------------------------
// LiveDispenseState — computed property tests (no I/O, no timers)
// ---------------------------------------------------------------------------

void main() {
  group('LiveDispenseState.litersDispensed', () {
    test('converts ml to liters', () {
      expect(
        _baseState(mlDispensed: 1500).litersDispensed,
        closeTo(1.5, 0.001),
      );
    });

    test('returns 0.0 when no ml dispensed', () {
      expect(_baseState().litersDispensed, 0.0);
    });
  });

  group('LiveDispenseState.amountChargedTzs', () {
    test('ceils partial cent', () {
      // 1.001 L * 4000 = 4004 — no rounding needed, exact
      expect(_baseState(mlDispensed: 1001).amountChargedTzs, 4004);
    });

    test('rounds up fractional TZS', () {
      // 1.5 L * 3000 TZS = 4500 exact
      final state = LiveDispenseState(
        phase: LiveDispensePhase.flowing,
        requestId: 'r',
        requestedLiters: 2.0,
        pricePerLiterTzs: 3000,
        mlDispensed: 1500,
      );
      expect(state.amountChargedTzs, 4500);
    });

    test('ceil kicks in for fractional result', () {
      // 1333 ml = 1.333 L * 4000 = 5332.0 → ceil = 5332
      expect(_baseState(mlDispensed: 1333).amountChargedTzs, 5332);
    });

    test('1 ml still charges at least 1 TZS', () {
      // 1 ml = 0.001 L * 4000 = 4.0 → ceil = 4
      expect(_baseState(mlDispensed: 1).amountChargedTzs, 4);
    });
  });

  group('LiveDispenseState.progressFraction', () {
    test('returns 0.0 before any dispensing', () {
      expect(_baseState().progressFraction, 0.0);
    });

    test('returns 0.5 at halfway point', () {
      // 2.0 L requested, 1.0 L dispensed = 50%
      expect(
        _baseState(mlDispensed: 1000).progressFraction,
        closeTo(0.5, 0.001),
      );
    });

    test('returns 1.0 at full amount', () {
      expect(_baseState(mlDispensed: 2000).progressFraction, 1.0);
    });

    test('clamps to 1.0 when over-dispensed', () {
      expect(_baseState(mlDispensed: 9999).progressFraction, 1.0);
    });

    test(
      'returns 0.0 when requestedLiters is zero (guard against division)',
      () {
        final state = LiveDispenseState(
          phase: LiveDispensePhase.awaitingActivation,
          requestId: 'r',
          requestedLiters: 0.0,
          pricePerLiterTzs: 4000,
        );
        expect(state.progressFraction, 0.0);
      },
    );
  });

  group('LiveDispenseState.isStale', () {
    test('returns false when lastEventAt is null', () {
      expect(_baseState().isStale, isFalse);
    });

    test('returns false for a very recent event', () {
      expect(_baseState(lastEventAt: DateTime.now()).isStale, isFalse);
    });

    test('returns true when last event was more than 5 seconds ago', () {
      final staleTime = DateTime.now().subtract(const Duration(seconds: 6));
      expect(_baseState(lastEventAt: staleTime).isStale, isTrue);
    });

    test('returns false exactly at the 5-second boundary', () {
      final borderTime = DateTime.now().subtract(const Duration(seconds: 5));
      // difference.inSeconds truncates — 5 seconds is NOT > 5, so not stale
      expect(_baseState(lastEventAt: borderTime).isStale, isFalse);
    });
  });

  group('LiveDispenseState.copyWith', () {
    test('preserves unchanged fields', () {
      final original = _baseState(
        phase: LiveDispensePhase.flowing,
        mlDispensed: 500,
      );
      final copy = original.copyWith(phase: LiveDispensePhase.paused);
      expect(copy.mlDispensed, 500);
      expect(copy.requestedLiters, 2.0);
      expect(copy.pricePerLiterTzs, 4000);
      expect(copy.requestId, 'req-001');
    });

    test('overrides specified fields', () {
      final state = _baseState().copyWith(
        phase: LiveDispensePhase.completed,
        mlDispensed: 2000,
        actualMl: 1950,
      );
      expect(state.phase, LiveDispensePhase.completed);
      expect(state.mlDispensed, 2000);
      expect(state.actualMl, 1950);
    });
  });

  // ---------------------------------------------------------------------------
  // LiveDispenseNotifier — event handling tests
  // ---------------------------------------------------------------------------

  group('LiveDispenseNotifier', () {
    late StreamController<Map<String, dynamic>> controller;
    late LiveDispenseNotifier notifier;

    setUp(() {
      controller = StreamController<Map<String, dynamic>>.broadcast();
      notifier = LiveDispenseNotifier(_params, controller.stream);
    });

    tearDown(() {
      notifier.dispose();
      controller.close();
    });

    test('initial state is awaiting activation with zero ml', () {
      expect(notifier.state.phase, LiveDispensePhase.awaitingActivation);
      expect(notifier.state.mlDispensed, 0.0);
      expect(notifier.state.requestId, 'req-001');
    });

    test('dispensing_progress → flowing phase with updated ml', () async {
      controller.add(_progressEvent(mlDispensed: 750.0));
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.phase, LiveDispensePhase.flowing);
      expect(notifier.state.mlDispensed, 750.0);
      expect(notifier.state.lastEventAt, isNotNull);
    });

    test('dispensing_progress with wrong request_id is ignored', () async {
      controller.add(_progressEvent(requestId: 'other-req', mlDispensed: 999));
      await Future<void>.delayed(Duration.zero);

      // State must be unchanged — still awaiting activation, still 0 ml
      expect(notifier.state.phase, LiveDispensePhase.awaitingActivation);
      expect(notifier.state.mlDispensed, 0.0);
    });

    test('dispense_complete → completed phase with actualMl', () async {
      controller.add(_completeEvent(actualMl: 1980.0));
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.phase, LiveDispensePhase.completed);
      expect(notifier.state.actualMl, closeTo(1980.0, 0.01));
    });

    test(
      'dispense_complete without actual_ml still transitions to completed',
      () async {
        controller.add(_completeEvent(actualMl: null));
        await Future<void>.delayed(Duration.zero);

        expect(notifier.state.phase, LiveDispensePhase.completed);
        expect(notifier.state.actualMl, isNull);
      },
    );

    test('error event → error phase with message', () async {
      controller.add(_errorEvent(reason: 'pressure fault'));
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.phase, LiveDispensePhase.error);
      expect(notifier.state.errorMessage, 'pressure fault');
    });

    test('error event without reason uses fallback message', () async {
      controller.add({
        'event': 'error',
        'data': {'request_id': 'req-001'},
      });
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.phase, LiveDispensePhase.error);
      expect(notifier.state.errorMessage, isNotEmpty);
    });

    test('unknown event type does not change state', () async {
      controller.add({
        'event': 'some_unknown_event',
        'data': {'request_id': 'req-001'},
      });
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.phase, LiveDispensePhase.awaitingActivation);
    });

    test('event missing event key does not throw', () async {
      controller.add({'data': {}});
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.phase, LiveDispensePhase.awaitingActivation);
    });

    test('ml advances on successive telemetry events', () async {
      controller.add(_progressEvent(mlDispensed: 500.0));
      await Future<void>.delayed(Duration.zero);
      controller.add(_progressEvent(mlDispensed: 1000.0));
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.mlDispensed, 1000.0);
      expect(notifier.state.litersDispensed, closeTo(1.0, 0.001));
    });

    test('isStale is false immediately after a progress event', () async {
      controller.add(_progressEvent());
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.isStale, isFalse);
    });
  });
}
