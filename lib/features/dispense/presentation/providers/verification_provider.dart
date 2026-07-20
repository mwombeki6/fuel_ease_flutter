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
/// - `session.anchored` for the linked session → flip `anchored:true`
///   (+`anchoredSeq` if present) in place, no refetch.
/// - `session.recorded` for the linked session → per its wire contract it
///   always carries `anchored:false`, so it never flips `anchored`; only
///   `anchoredSeq` is defensively applied if present. This also guards
///   against a replayed/out-of-order `recorded` frame (e.g. after a
///   reconnect) regressing an already-anchored session back to false.
/// - Either event while the request isn't linked yet (no session recorded
///   at REST-fetch time) → we can't safely merge (the model has nothing to
///   merge onto, and the WS payload carries no `request_id` to verify
///   ownership), so this triggers a refetch instead of a speculative merge.
/// - `RealtimeClient.reconnected` → always refetch; events may have been
///   missed while offline, so the REST snapshot is the source of truth.
/// - Any event whose `session_id` doesn't match the session this request
///   is already linked to is ignored — the `user:<id>` channel carries
///   every session for that user, not just this request's.
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

    final current = state.valueOrNull;
    if (current == null) return; // nothing to merge onto yet

    if (!current.linked) {
      // No session was linked at REST-fetch time. We can't merge a partial
      // event onto a `SessionVerification` that doesn't carry the other
      // fields (classification/deviceId/etc.), and the event carries no
      // request_id to confirm it's even for this request — so resync via
      // REST instead of guessing.
      unawaited(_refetch());
      return;
    }

    final sessionId = event.data['session_id']?.toString();
    if (sessionId == null || sessionId != _sessionId) {
      return; // event for a different session on this user's channel
    }

    final anchoredSeq = (event.data['anchored_seq'] as num?)?.toInt();

    if (event.event == 'session.anchored') {
      state = AsyncValue.data(
        current.copyWith(
          anchored: true,
          anchoredSeq: anchoredSeq ?? current.anchoredSeq,
        ),
      );
    } else if (anchoredSeq != null) {
      // session.recorded: always anchored:false on the wire, so never touch
      // `anchored` here — only opportunistically pick up anchoredSeq.
      state = AsyncValue.data(current.copyWith(anchoredSeq: anchoredSeq));
    }
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
