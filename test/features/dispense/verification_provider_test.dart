import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fuel_ease_flutter/core/api/api_client.dart';
import 'package:fuel_ease_flutter/core/realtime/realtime_providers.dart';
import 'package:fuel_ease_flutter/core/storage/secure_storage.dart';
import 'package:fuel_ease_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fuel_ease_flutter/features/dispense/data/models/session_verification.dart';
import 'package:fuel_ease_flutter/features/dispense/data/repositories/verification_repository.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/providers/verification_provider.dart';
import 'package:fuel_ease_flutter/shared/models/user.dart';

// ---------------------------------------------------------------------------
// Fakes
//
// _FakeSecureStorage.getToken() short-circuits to null (same trick as
// test/core/realtime/realtime_client_test.dart) so any accidental real
// connect() attempt returns immediately without touching a platform channel.
// ---------------------------------------------------------------------------

class _FakeSecureStorage extends SecureStorage {
  _FakeSecureStorage() : super(const FlutterSecureStorage());

  @override
  Future<String?> getToken() async => null;
}

/// Subclasses the real [RealtimeClient] (rather than a from-scratch fake) so
/// the provider under test talks to the exact same public surface it will
/// see in production, with only `ensureConnected`/`reconnected` swapped out
/// for test-controllable versions.
class _FakeRealtimeClient extends RealtimeClient {
  _FakeRealtimeClient() : super(_FakeSecureStorage(), ApiClient(_FakeSecureStorage()));

  final _reconnectedController = StreamController<void>.broadcast();
  int ensureConnectedCalls = 0;
  String? lastEnsureConnectedUserId;

  @override
  void ensureConnected(String userId) {
    ensureConnectedCalls++;
    lastEnsureConnectedUserId = userId;
  }

  @override
  Stream<void> get reconnected => _reconnectedController.stream;

  void fireReconnected() => _reconnectedController.add(null);

  void closeFake() => unawaited(_reconnectedController.close());
}

/// Subclasses the real [VerificationRepository] so the provider exercises
/// the actual production type, with `fetch` swapped for a scripted sequence
/// of responses (last response repeats once the list is exhausted).
class _FakeVerificationRepository extends VerificationRepository {
  _FakeVerificationRepository(this._responses)
      : super(ApiClient(_FakeSecureStorage()));

  final List<SessionVerification> _responses;
  int fetchCount = 0;

  @override
  Future<SessionVerification> fetch(String requestId) async {
    fetchCount++;
    final index = (fetchCount - 1).clamp(0, _responses.length - 1);
    return _responses[index];
  }
}

const _testUser = User(
  id: 'u1',
  email: 'driver@example.com',
  role: 'customer',
  firstName: 'Driver',
  lastName: 'One',
);

const _unanchored = SessionVerification(
  linked: true,
  sessionId: 'S1',
  classification: 'genuine',
  deviceId: 'dev-1',
  startSeq: 1,
  endSeq: 42,
  volumeMl: 15000,
  anchored: false,
);

const _anchoredFromRest = SessionVerification(
  linked: true,
  sessionId: 'S1',
  classification: 'genuine',
  anchored: true,
  anchoredSeq: 9,
);

const _unanchoredS2 = SessionVerification(
  linked: true,
  sessionId: 'S2',
  classification: 'genuine',
  anchored: false,
);

/// Keyed by `requestId` so a single override can back two different
/// `.family` instances at once, each with its own linked `sessionId` — used
/// to prove events don't leak across requests.
class _KeyedFakeRepository extends VerificationRepository {
  _KeyedFakeRepository(this._byRequestId) : super(ApiClient(_FakeSecureStorage()));

  final Map<String, SessionVerification> _byRequestId;
  final Map<String, int> fetchCounts = {};

  @override
  Future<SessionVerification> fetch(String requestId) async {
    fetchCounts[requestId] = (fetchCounts[requestId] ?? 0) + 1;
    return _byRequestId[requestId]!;
  }
}

void main() {
  late _FakeRealtimeClient client;
  late StreamController<RealtimeEvent> events;

  ProviderContainer makeContainer(VerificationRepository repo) {
    final container = ProviderContainer(
      overrides: [
        verificationRepositoryProvider.overrideWithValue(repo),
        realtimeClientProvider.overrideWithValue(client),
        realtimeEventsProvider.overrideWith((ref) => events.stream),
        currentUserProvider.overrideWithValue(_testUser),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    client = _FakeRealtimeClient();
    events = StreamController<RealtimeEvent>.broadcast();
  });

  tearDown(() {
    client.closeFake();
    unawaited(events.close());
  });

  test('initial REST anchored:false is exposed as-is, and connects realtime',
      () async {
    final repo = _FakeVerificationRepository([_unanchored]);
    final container = makeContainer(repo);

    final result = await container.read(verificationProvider('req-1').future);

    expect(result.linked, isTrue);
    expect(result.anchored, isFalse);
    expect(result.sessionId, 'S1');
    expect(repo.fetchCount, 1);
    expect(client.ensureConnectedCalls, 1);
    expect(client.lastEnsureConnectedUserId, 'u1');
  });

  test('session.anchored event flips anchored:true without a refetch',
      () async {
    final repo = _FakeVerificationRepository([_unanchored]);
    final container = makeContainer(repo);
    await container.read(verificationProvider('req-1').future);

    events.add(const RealtimeEvent(
      channel: 'user:u1',
      event: 'session.anchored',
      data: {'session_id': 'S1', 'anchored_seq': 5},
    ));
    await Future<void>.delayed(Duration.zero);

    final state = container.read(verificationProvider('req-1'));
    expect(state.value?.anchored, isTrue);
    expect(state.value?.anchoredSeq, 5);
    // No second fetch — the WS event alone flipped the flag.
    expect(repo.fetchCount, 1);
  });

  test('session.recorded for the linked session never flips anchored',
      () async {
    final repo = _FakeVerificationRepository([_unanchored]);
    final container = makeContainer(repo);
    await container.read(verificationProvider('req-1').future);

    events.add(const RealtimeEvent(
      channel: 'user:u1',
      event: 'session.recorded',
      data: {'session_id': 'S1', 'anchored': false},
    ));
    await Future<void>.delayed(Duration.zero);

    final state = container.read(verificationProvider('req-1'));
    expect(state.value?.anchored, isFalse);
    expect(repo.fetchCount, 1);
  });

  test('event for a different session_id is ignored (no cross-dispense leak)',
      () async {
    final repo = _FakeVerificationRepository([_unanchored]);
    final container = makeContainer(repo);
    await container.read(verificationProvider('req-1').future);

    events.add(const RealtimeEvent(
      channel: 'user:u1',
      event: 'session.anchored',
      data: {'session_id': 'SOME-OTHER-SESSION', 'anchored_seq': 99},
    ));
    await Future<void>.delayed(Duration.zero);

    final state = container.read(verificationProvider('req-1'));
    expect(state.value?.anchored, isFalse);
    expect(repo.fetchCount, 1);
  });

  test('reconnected signal triggers a refetch', () async {
    final repo =
        _FakeVerificationRepository([_unanchored, _anchoredFromRest]);
    final container = makeContainer(repo);
    await container.read(verificationProvider('req-1').future);
    expect(repo.fetchCount, 1);

    client.fireReconnected();
    await Future<void>.delayed(Duration.zero);

    final state = container.read(verificationProvider('req-1'));
    expect(repo.fetchCount, 2);
    expect(state.value?.anchored, isTrue);
    expect(state.value?.anchoredSeq, 9);
  });

  test(
      'a session.anchored event never crosses between two requestId '
      'family instances sharing the same user realtime channel', () async {
    final repo = _KeyedFakeRepository({
      'req-A': _unanchored, // linked to session S1
      'req-B': _unanchoredS2, // linked to session S2
    });
    final container = makeContainer(repo);

    await container.read(verificationProvider('req-A').future);
    await container.read(verificationProvider('req-B').future);

    // Both requests share one `user:<id>` channel; an S1 event must only
    // ever touch req-A's provider instance.
    events.add(const RealtimeEvent(
      channel: 'user:u1',
      event: 'session.anchored',
      data: {'session_id': 'S1', 'anchored_seq': 7},
    ));
    await Future<void>.delayed(Duration.zero);

    final stateA = container.read(verificationProvider('req-A'));
    final stateB = container.read(verificationProvider('req-B'));
    expect(stateA.value?.anchored, isTrue);
    expect(stateA.value?.anchoredSeq, 7);
    expect(stateB.value?.anchored, isFalse); // untouched by the S1 event
    expect(repo.fetchCounts['req-A'], 1);
    expect(repo.fetchCounts['req-B'], 1);
  });
}
