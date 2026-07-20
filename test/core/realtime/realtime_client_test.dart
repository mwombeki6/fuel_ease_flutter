import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_ease_flutter/core/api/api_client.dart';
import 'package:fuel_ease_flutter/core/realtime/realtime_client.dart';
import 'package:fuel_ease_flutter/core/realtime/realtime_event.dart';
import 'package:fuel_ease_flutter/core/storage/secure_storage.dart';

// Pure-logic tests for the reusable realtime client. These deliberately
// avoid opening a real WebSocket — buildSubscribeFrame, nextBackoff, and
// RealtimeEvent.fromWire are extracted as top-level/factory pure functions
// specifically so they can be exercised without a live socket.
//
// _FakeSecureStorage.getToken() short-circuits to null so that, when
// ensureConnected() kicks off a connect(), it returns immediately after its
// "not logged in" pre-check instead of ever touching a platform channel or
// the network — keeping these tests fast and socket-free.
class _FakeSecureStorage extends SecureStorage {
  _FakeSecureStorage() : super(const FlutterSecureStorage());

  @override
  Future<String?> getToken() async => null;
}

void main() {
  group('buildSubscribeFrame', () {
    test('builds the exact WebHub wire shape for a user channel', () {
      expect(
        buildSubscribeFrame('user:u1'),
        '{"action":"subscribe","channel":"user:u1"}',
      );
    });

    test('is stable for different channel ids (no caching/aliasing bugs)', () {
      expect(
        buildSubscribeFrame('user:abc-123'),
        '{"action":"subscribe","channel":"user:abc-123"}',
      );
    });

    test('works for any channel, not just user: channels', () {
      expect(
        buildSubscribeFrame('station:42'),
        '{"action":"subscribe","channel":"station:42"}',
      );
    });
  });

  group('RealtimeClient.ensureConnected', () {
    test(
      'records the user channel as a subscription intent even without a '
      'live socket (so it is not lost if a connect() were already in '
      'flight — see realtime_client.dart ensureConnected doc comment)',
      () {
        final storage = _FakeSecureStorage();
        final client = RealtimeClient(storage, ApiClient(storage));
        client.ensureConnected('u1');
        expect(client.debugSubscriptions, contains('user:u1'));
      },
    );
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
