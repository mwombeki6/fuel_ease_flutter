import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/core/realtime/realtime_providers.dart';
import 'package:fuel_ease_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fuel_ease_flutter/features/dispense/data/models/session_verification.dart';
import 'package:fuel_ease_flutter/features/dispense/data/repositories/verification_repository.dart';

/// Live fuel-session verification state for a single dispense request.
///
/// This mirrors `live_dispense_provider.dart`'s shape — keyed per
/// `requestId` via `.family` so one dispense's results can never leak into
/// another's, watches the shared [realtimeClientProvider] to ensure the
/// socket is connected/subscribed, and merges realtime events on top of a
/// REST snapshot rather than polling.
///
/// It differs in one respect: `live_dispense_provider` is a `StateNotifier`
/// handed an already-open stream because its initial state can be
/// synthesized locally (`connecting`, 0 ml). Here the very first state is
/// only knowable via an *async* REST fetch (`GET
/// /dispense/:id/verification`), which is exactly what `AsyncNotifier.build`
/// is for — so this is a `FamilyAsyncNotifier` exposing `AsyncValue<
/// SessionVerification>` instead.
///
/// Merge contract (see `SessionVerification` re: never synthesizing
/// `anchored:true` client-side):
/// - `session.recorded` → self-sufficient payload that mirrors the REST
///   shape (`session_id`, `classification`, `device_id`, `start_seq`,
///   `end_seq`, `volume_ml`, `anchored:false`), and `fromJson` defaults
///   `linked` to `true` when the key is absent. So the new state is built
///   *directly* from the event via `SessionVerification.fromJson` — no
///   refetch — regardless of whether the request was already linked. A
///   `recorded` event is always a full snapshot, never a delta, which is
///   what makes the awaiting → recorded transition genuinely live instead
///   of racing a REST refetch (whose transient failure could otherwise
///   regress a valid `linked:false` "awaiting" card into an error state).
/// - `session.anchored` for the linked session → its payload is minimal
///   (`{session_id, anchored_seq}`), so it can only be *merged* onto an
///   existing linked snapshot: flip `anchored:true` (+`anchoredSeq` if
///   present) in place, no refetch.
/// - `session.anchored` while the request isn't linked yet (no session
///   recorded at REST-fetch time, or by an earlier `session.recorded`
///   event) → the payload alone can't synthesize a full
///   `SessionVerification`, so this falls back to a refetch instead of a
///   speculative merge.
/// - `RealtimeClient.reconnected` → always refetch; events may have been
///   missed while offline, so the REST snapshot is the source of truth.
/// - Any event whose `session_id` doesn't match the session this request
///   is already linked to is ignored — the `user:<id>` channel carries
///   every session for that user, not just this request's. (`session_id`
///   matching only applies to `session.anchored`; `session.recorded` sets
///   `_sessionId` from its own payload since it's the thing that
///   establishes the link in the first place.)
class VerificationController
    extends FamilyAsyncNotifier<SessionVerification, String> {
  late String _requestId;
  String? _sessionId;

  @override
  Future<SessionVerification> build(String requestId) async {
    _requestId = requestId;
    final repository = ref.watch(verificationRepositoryProvider);
    final client = ref.watch(realtimeClientProvider);

    final userId = ref.read(currentUserProvider)?.id;
    if (userId != null && userId.isNotEmpty) {
      client.ensureConnected(userId);
    }

    // ref.listen inside build() is auto-cleaned-up by Riverpod when this
    // provider instance is rebuilt/disposed — no manual subscription needed
    // for this one (unlike `reconnected` below, which isn't provider-based).
    ref.listen<AsyncValue<RealtimeEvent>>(realtimeEventsProvider, (
      previous,
      next,
    ) {
      final event = next.valueOrNull;
      if (event != null) _handleEvent(event);
    });

    final reconnectSub = client.reconnected.listen((_) => _refetch());
    ref.onDispose(reconnectSub.cancel);

    final verification = await repository.fetch(requestId);
    _sessionId = verification.sessionId;
    return verification;
  }

  void _handleEvent(RealtimeEvent event) {
    if (event.event != 'session.recorded' && event.event != 'session.anchored') {
      return;
    }

    if (!state.hasValue) return; // initial REST fetch hasn't resolved yet

    if (event.event == 'session.recorded') {
      // Self-sufficient payload — build the new state directly from the
      // event, whether or not we were previously linked. See the merge
      // contract above for why this must never fall back to a refetch.
      final verification = SessionVerification.fromJson(event.data);
      _sessionId = verification.sessionId;
      state = AsyncValue.data(verification);
      return;
    }

    // session.anchored: minimal payload, only mergeable onto an existing
    // linked snapshot.
    final current = state.valueOrNull;
    if (current == null || !current.linked) {
      // No session linked yet locally — the anchored payload alone can't
      // synthesize a full SessionVerification, so resync via REST instead
      // of guessing.
      unawaited(_refetch());
      return;
    }

    final sessionId = event.data['session_id']?.toString();
    if (sessionId == null || sessionId != _sessionId) {
      return; // event for a different session on this user's channel
    }

    final anchoredSeq = (event.data['anchored_seq'] as num?)?.toInt();
    state = AsyncValue.data(
      current.copyWith(
        anchored: true,
        anchoredSeq: anchoredSeq ?? current.anchoredSeq,
      ),
    );
  }

  Future<void> _refetch() async {
    final repository = ref.read(verificationRepositoryProvider);
    final result = await AsyncValue.guard(() => repository.fetch(_requestId));
    result.whenData((verification) => _sessionId = verification.sessionId);
    state = result;
  }
}

final verificationProvider = AsyncNotifierProvider.family<
    VerificationController, SessionVerification, String>(
  VerificationController.new,
);
