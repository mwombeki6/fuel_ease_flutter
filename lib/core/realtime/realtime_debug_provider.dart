import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/core/realtime/realtime_client.dart';

class RealtimeDebugState {
  const RealtimeDebugState({
    this.events = const [],
  });

  final List<Map<String, dynamic>> events;
}

class RealtimeDebugNotifier extends StateNotifier<RealtimeDebugState> {
  RealtimeDebugNotifier(this._client) : super(const RealtimeDebugState()) {
    _subscription = _client.stream.listen(_handleEvent);
  }

  final RealtimeClient _client;
  StreamSubscription<Map<String, dynamic>>? _subscription;

  void _handleEvent(Map<String, dynamic> event) {
    final updated = [...state.events, event];
    const maxEvents = 12;
    final trimmed =
        updated.length > maxEvents ? updated.sublist(updated.length - maxEvents) : updated;
    state = RealtimeDebugState(events: trimmed);
  }

  void clear() {
    state = const RealtimeDebugState();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final realtimeDebugProvider =
    StateNotifierProvider.autoDispose<RealtimeDebugNotifier, RealtimeDebugState>(
  (ref) {
    final client = ref.watch(realtimeClientProvider);
    return RealtimeDebugNotifier(client);
  },
);
