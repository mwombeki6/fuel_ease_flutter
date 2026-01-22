import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/core/realtime/realtime_client.dart';

class PumpRealtimeStatus {
  PumpRealtimeStatus({
    required this.pumpId,
    required this.receivedAt,
    required this.eventType,
    required this.data,
    this.status,
    this.stationId,
  });

  final String pumpId;
  final String? stationId;
  final DateTime receivedAt;
  final String eventType;
  final Map<String, dynamic> data;
  final String? status;
}

class PumpRealtimeState {
  const PumpRealtimeState({this.byPump = const {}});

  final Map<String, PumpRealtimeStatus> byPump;
}

class RealtimePumpStatusNotifier extends StateNotifier<PumpRealtimeState> {
  RealtimePumpStatusNotifier(this._client)
      : super(const PumpRealtimeState()) {
    _subscription = _client.stream.listen(_handleEvent);
  }

  final RealtimeClient _client;
  StreamSubscription<Map<String, dynamic>>? _subscription;

  void _handleEvent(Map<String, dynamic> event) {
    final type = event['type']?.toString();
    if (type == null) return;

    const allowedTypes = {
      'pump_status',
      'dispensing_progress',
      'telemetry',
      'device_command_update',
    };
    if (!allowedTypes.contains(type)) return;

    final pumpId = event['pumpId']?.toString();
    if (pumpId == null || pumpId.isEmpty) return;

    final stationId = event['stationId']?.toString();
    final data = event['data'] is Map
        ? Map<String, dynamic>.from(event['data'] as Map)
        : <String, dynamic>{};

    final status = _resolveStatus(type, data);
    final receivedAt = _parseTimestamp(event['timestamp']?.toString()) ??
        DateTime.now();

    final updated = Map<String, PumpRealtimeStatus>.from(state.byPump);
    updated[pumpId] = PumpRealtimeStatus(
      pumpId: pumpId,
      stationId: stationId,
      receivedAt: receivedAt,
      eventType: type,
      data: data,
      status: status,
    );

    state = PumpRealtimeState(byPump: updated);
  }

  String? _resolveStatus(String type, Map<String, dynamic> data) {
    final dataStatus = data['status']?.toString();
    if (dataStatus != null && dataStatus.isNotEmpty) {
      return dataStatus;
    }
    if (type == 'dispensing_progress') {
      return 'DISPENSING';
    }
    return null;
  }

  DateTime? _parseTimestamp(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final realtimePumpStatusProvider =
    StateNotifierProvider<RealtimePumpStatusNotifier, PumpRealtimeState>(
  (ref) {
    final client = ref.watch(realtimeClientProvider);
    return RealtimePumpStatusNotifier(client);
  },
);
