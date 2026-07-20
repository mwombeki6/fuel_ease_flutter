import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/core/realtime/realtime_client.dart';
import 'package:fuel_ease_flutter/core/realtime/realtime_event.dart';

// Re-export the client and its provider so feature code can depend on this
// single "realtime" barrel file instead of reaching into realtime_client.dart
// directly. This does not create a second client instance — it's the same
// provider declaration, just visible from both import paths.
export 'package:fuel_ease_flutter/core/realtime/realtime_client.dart'
    show
        RealtimeClient,
        realtimeClientProvider,
        RealtimeStatus,
        RealtimeConnectionState;
export 'package:fuel_ease_flutter/core/realtime/realtime_event.dart'
    show RealtimeEvent;

/// Typed, feature-agnostic bridge over [RealtimeClient.stream].
///
/// Features that want realtime updates should watch/filter this provider
/// (or call `ref.read(realtimeClientProvider).ensureConnected(...)` plus
/// listen to `.stream` directly if they need the raw map) rather than
/// parsing the wire envelope themselves. This provider does not filter by
/// channel or event name — it is a straight typed mirror of every event the
/// client receives.
final realtimeEventsProvider = StreamProvider<RealtimeEvent>((ref) {
  final client = ref.watch(realtimeClientProvider);
  return client.stream.map(RealtimeEvent.fromWire);
});
