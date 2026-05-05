import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/core/realtime/realtime_client.dart';

class RealtimeStatusNotifier extends StateNotifier<RealtimeStatus> {
  RealtimeStatusNotifier(this._client) : super(_client.status) {
    _subscription = _client.statusStream.listen((status) {
      state = status;
    });
  }

  final RealtimeClient _client;
  StreamSubscription<RealtimeStatus>? _subscription;

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}

final realtimeStatusProvider =
    StateNotifierProvider<RealtimeStatusNotifier, RealtimeStatus>(
  (ref) {
    final client = ref.watch(realtimeClientProvider);
    return RealtimeStatusNotifier(client);
  },
);
