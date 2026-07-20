import 'package:flutter_test/flutter_test.dart';

import 'package:fuel_ease_flutter/features/dispense/data/models/session_verification.dart';

void main() {
  group('SessionVerification.fromJson', () {
    test('{linked:false} -> linked:false, anchored:false, no other fields',
        () {
      final result = SessionVerification.fromJson({'linked': false});

      expect(result.linked, isFalse);
      expect(result.anchored, isFalse);
      expect(result.sessionId, isNull);
      expect(result.classification, isNull);
      expect(result.deviceId, isNull);
      expect(result.startSeq, isNull);
      expect(result.endSeq, isNull);
      expect(result.volumeMl, isNull);
      expect(result.anchoredSeq, isNull);
    });

    test(
        'a full snake_case map with no `linked` key -> linked:true and '
        'correct fields', () {
      final result = SessionVerification.fromJson({
        'session_id': 'S1',
        'classification': 'genuine',
        'device_id': 'dev-1',
        'start_seq': 1,
        'end_seq': 42,
        'volume_ml': 15000,
        'anchored': false,
      });

      expect(result.linked, isTrue);
      expect(result.sessionId, 'S1');
      expect(result.classification, 'genuine');
      expect(result.deviceId, 'dev-1');
      expect(result.startSeq, 1);
      expect(result.endSeq, 42);
      expect(result.volumeMl, 15000);
      expect(result.anchored, isFalse);
      expect(result.anchoredSeq, isNull);
    });

    test('nullable-absent fields decode to null', () {
      final result = SessionVerification.fromJson({
        'session_id': 'S1',
        'anchored': true,
        'anchored_seq': 9,
      });

      expect(result.linked, isTrue);
      expect(result.sessionId, 'S1');
      expect(result.anchored, isTrue);
      expect(result.anchoredSeq, 9);
      expect(result.classification, isNull);
      expect(result.deviceId, isNull);
      expect(result.startSeq, isNull);
      expect(result.endSeq, isNull);
      expect(result.volumeMl, isNull);
    });
  });
}
