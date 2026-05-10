import 'package:flutter_test/flutter_test.dart';

import 'package:fuel_ease_flutter/features/dispense/data/models/dispense_request.dart';

// Minimal valid JSON matching what the Go API actually returns.
Map<String, dynamic> _baseJson({
  String requestedLiters = '2.500',
  dynamic actualLiters,
  String? walletHoldId,
  String? completedAt,
}) =>
    {
      'id': 'req-uuid-001',
      'card_id': 'card-uuid-001',
      'station_id': 'station-uuid-001',
      'requested_liters': requestedLiters,
      'price_per_liter_tzs': 4000,
      'status': 'pending',
      'created_at': '2026-05-10T06:00:00Z',
      if (actualLiters != null) 'actual_liters': actualLiters,
      if (walletHoldId != null) 'wallet_hold_id': walletHoldId,
      if (completedAt != null) 'completed_at': completedAt,
    };

void main() {
  group('DispenseRequest.fromJson — NUMERIC string parsing', () {
    test('parses requested_liters from PostgreSQL NUMERIC string', () {
      final req = DispenseRequest.fromJson(_baseJson(requestedLiters: '2.500'));
      expect(req.requestedLiters, closeTo(2.5, 0.001));
    });

    test('parses whole-number NUMERIC string without decimal', () {
      final req = DispenseRequest.fromJson(_baseJson(requestedLiters: '5'));
      expect(req.requestedLiters, closeTo(5.0, 0.001));
    });

    test('defaults requested_liters to 0.0 when field is null', () {
      final json = _baseJson()..remove('requested_liters');
      final req = DispenseRequest.fromJson(json);
      expect(req.requestedLiters, 0.0);
    });

    test('parses actual_liters from NUMERIC string when present', () {
      final req = DispenseRequest.fromJson(
        _baseJson(actualLiters: '1.500'),
      );
      expect(req.actualLiters, isNotNull);
      expect(req.actualLiters!, closeTo(1.5, 0.001));
    });

    test('leaves actual_liters null when field is absent', () {
      final req = DispenseRequest.fromJson(_baseJson());
      expect(req.actualLiters, isNull);
    });

    test('leaves actual_liters null when field is JSON null', () {
      final json = _baseJson();
      json['actual_liters'] = null;
      final req = DispenseRequest.fromJson(json);
      expect(req.actualLiters, isNull);
    });
  });

  group('DispenseRequest.fromJson — wallet_hold_id field', () {
    test('maps wallet_hold_id to holdId', () {
      final req = DispenseRequest.fromJson(
        _baseJson(walletHoldId: 'hold-uuid-001'),
      );
      expect(req.holdId, 'hold-uuid-001');
    });

    test('holdId is null when wallet_hold_id is absent', () {
      final req = DispenseRequest.fromJson(_baseJson());
      expect(req.holdId, isNull);
    });
  });

  group('DispenseRequest.fromJson — computed properties', () {
    test('estimatedCostTzs rounds up correctly', () {
      // 2.5 L * 4000 TZS = 10000 TZS exact
      final req = DispenseRequest.fromJson(_baseJson(requestedLiters: '2.500'));
      expect(req.estimatedCostTzs, 10000);
    });

    test('status helpers reflect parsed status', () {
      final req = DispenseRequest.fromJson(_baseJson());
      expect(req.isPending, isTrue);
      expect(req.isCompleted, isFalse);
    });

    test('isTerminal is true for completed status', () {
      final json = _baseJson();
      json['status'] = 'completed';
      final req = DispenseRequest.fromJson(json);
      expect(req.isTerminal, isTrue);
    });
  });

  group('DispenseRequest.fromJson — date parsing', () {
    test('parses completedAt when present', () {
      final req = DispenseRequest.fromJson(
        _baseJson(completedAt: '2026-05-10T08:30:00Z'),
      );
      expect(req.completedAt, isNotNull);
      expect(req.completedAt!.year, 2026);
    });

    test('completedAt is null when field is absent', () {
      final req = DispenseRequest.fromJson(_baseJson());
      expect(req.completedAt, isNull);
    });
  });
}
