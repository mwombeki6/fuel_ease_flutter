/// A single realtime event delivered over the app-wide WebSocket connection.
///
/// Deliberately feature-agnostic: [channel] and [event] are plain strings and
/// [data] is an untyped payload. Individual features (e.g. fuel-session
/// verification) decode `data` however they need — this type does not know
/// about any specific event names.
class RealtimeEvent {
  const RealtimeEvent({
    required this.channel,
    required this.event,
    required this.data,
  });

  /// Parses the Go WebHub wire envelope: `{"channel":..., "event":...,
  /// "data":...}`. `event` is the primary field; `type` is tolerated as a
  /// fallback for producers that still use the older key. Missing fields
  /// default to empty rather than throwing, since a malformed/legacy frame
  /// should degrade gracefully instead of crashing the event stream.
  factory RealtimeEvent.fromWire(Map<String, dynamic> json) => RealtimeEvent(
    channel: (json['channel'] ?? '') as String,
    event: (json['event'] ?? json['type'] ?? '') as String,
    data: (json['data'] as Map<String, dynamic>?) ?? const {},
  );

  final String channel;
  final String event;
  final Map<String, dynamic> data;
}
