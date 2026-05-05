import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/features/wallet/data/models/fuel_session.dart';

/// Stub provider — sessions replaced by dispense requests in Wave 4.
final activeSessionsProvider =
    FutureProvider<List<FuelSession>>((ref) async => []);

final sessionByIdProvider =
    FutureProvider.family<FuelSession, String>((ref, sessionId) async {
  throw UnimplementedError('Use dispense provider');
});
