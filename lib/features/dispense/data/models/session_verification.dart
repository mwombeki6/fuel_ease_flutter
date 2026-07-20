/// Snapshot of a dispense request's underlying fuel-session verification
/// state, as returned by `GET /dispense/:id/verification` and kept live by
/// `session.recorded`/`session.anchored` realtime events.
///
/// `linked:false` (no session recorded yet for this request) leaves every
/// other field absent/default — see [fromJson].
class SessionVerification {
  const SessionVerification({
    required this.linked,
    required this.anchored,
    this.sessionId,
    this.classification,
    this.deviceId,
    this.startSeq,
    this.endSeq,
    this.volumeMl,
    this.anchoredSeq,
  });

  final bool linked;

  /// Not part of the brief's minimal model, but present in the backend
  /// response and needed by [VerificationController] to check that an
  /// incoming WS event's `session_id` actually belongs to this request
  /// before merging it — otherwise a user with two concurrent dispenses
  /// could leak one session's events into the other's provider. See
  /// verification_provider.dart for how this is used.
  final String? sessionId;
  final String? classification;
  final String? deviceId;
  final int? startSeq;
  final int? endSeq;
  final int? volumeMl;
  final bool anchored;
  final int? anchoredSeq;

  factory SessionVerification.fromJson(Map<String, dynamic> j) =>
      SessionVerification(
        linked: (j['linked'] as bool?) ?? true,
        sessionId: j['session_id'] as String?,
        classification: j['classification'] as String?,
        deviceId: j['device_id'] as String?,
        startSeq: (j['start_seq'] as num?)?.toInt(),
        endSeq: (j['end_seq'] as num?)?.toInt(),
        volumeMl: (j['volume_ml'] as num?)?.toInt(),
        anchored: (j['anchored'] as bool?) ?? false,
        anchoredSeq: (j['anchored_seq'] as num?)?.toInt(),
      );

  SessionVerification copyWith({bool? anchored, int? anchoredSeq}) =>
      SessionVerification(
        linked: linked,
        sessionId: sessionId,
        classification: classification,
        deviceId: deviceId,
        startSeq: startSeq,
        endSeq: endSeq,
        volumeMl: volumeMl,
        anchored: anchored ?? this.anchored,
        anchoredSeq: anchoredSeq ?? this.anchoredSeq,
      );
}
