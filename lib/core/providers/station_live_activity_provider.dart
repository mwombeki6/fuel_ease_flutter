import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/core/realtime/realtime_pump_status_provider.dart';

/// Returns the set of station IDs that have at least one pump actively
/// dispensing fuel right now (based on WebSocket events within the last 5 min).
final stationLiveActivityProvider = Provider<Set<String>>((ref) {
  final pumpState = ref.watch(realtimePumpStatusProvider);
  final cutoff = DateTime.now().subtract(const Duration(minutes: 5));

  return pumpState.byPump.values
      .where((p) =>
          p.stationId != null &&
          p.receivedAt.isAfter(cutoff) &&
          (p.status == 'DISPENSING' || p.eventType == 'dispensing_progress'))
      .map((p) => p.stationId!)
      .toSet();
});
