import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_ease_flutter/core/realtime/realtime_client.dart';
import 'package:fuel_ease_flutter/core/realtime/realtime_event.dart';

// Pure-logic tests for the reusable realtime client. These deliberately
// avoid opening a real WebSocket — buildSubscribeFrame, nextBackoff, and
// RealtimeEvent.fromWire are extracted as top-level/factory pure functions
// specifically so they can be exercised without a live socket.
void main() {
  group('buildSubscribeFrame', () {
    test('targets the user channel with the exact WebHub wire shape', () {
      expect(
        buildSubscribeFrame('u1'),
        '{"action":"subscribe","channel":"user:u1"}',
      );
    });

    test('is stable for different user ids (no caching/aliasing bugs)', () {
      expect(
        buildSubscribeFrame('abc-123'),
        '{"action":"subscribe","channel":"user:abc-123"}',
      );
    });
  });

  group('RealtimeEvent.fromWire', () {
    test('parses the primary {channel,event,data} envelope', () {
      final e = RealtimeEvent.fromWire({
        'channel': 'user:u1',
        'event': 'session.anchored',
        'data': {'anchored_seq': 5},
      });
      expect(e.channel, 'user:u1');
      expect(e.event, 'session.anchored');
      expect(e.data, {'anchored_seq': 5});
    });

    test('tolerates "type" as a fallback for "event"', () {
      expect(
        RealtimeEvent.fromWire({
          'channel': 'user:u1',
          'type': 'session.anchored',
          'data': {'anchored_seq': 5},
        }).event,
        'session.anchored',
      );
    });

    test(
      'defaults channel/event to empty string and data to {} when absent',
      () {
        final e = RealtimeEvent.fromWire(const {});
        expect(e.channel, '');
        expect(e.event, '');
        expect(e.data, <String, dynamic>{});
      },
    );

    test('prefers "event" over "type" when both are present', () {
      final e = RealtimeEvent.fromWire({
        'channel': 'user:u1',
        'event': 'session.anchored',
        'type': 'legacy.name',
        'data': <String, dynamic>{},
      });
      expect(e.event, 'session.anchored');
    });
  });

  group('nextBackoff', () {
    test('is monotonically non-decreasing as attempts increase', () {
      Duration? previous;
      for (var attempt = 0; attempt < 10; attempt++) {
        final delay = nextBackoff(attempt);
        if (previous != null) {
          expect(
            delay.inMilliseconds,
            greaterThanOrEqualTo(previous.inMilliseconds),
          );
        }
        previous = delay;
      }
    });

    test(
      'is capped at a bounded maximum even for very large attempt counts',
      () {
        final atCap = nextBackoff(10);
        final farBeyondCap = nextBackoff(1000);
        expect(farBeyondCap, atCap);
        expect(farBeyondCap.inSeconds, lessThanOrEqualTo(30));
      },
    );

    test('never returns a non-positive delay', () {
      expect(nextBackoff(0).inMilliseconds, greaterThan(0));
      expect(nextBackoff(-5).inMilliseconds, greaterThan(0));
    });
  });
}
