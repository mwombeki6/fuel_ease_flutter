import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/features/wallet/data/models/fuel_session.dart';
import 'package:fuel_ease_flutter/features/wallet/data/repositories/wallet_repository.dart';

/// Provider for active fuel sessions
final activeSessionsProvider = FutureProvider<List<FuelSession>>((ref) async {
  final repository = ref.watch(walletRepositoryProvider);
  return await repository.getActiveSessions();
});

/// Provider for a specific session by ID
final sessionByIdProvider =
    FutureProvider.family<FuelSession, String>((ref, sessionId) async {
  final repository = ref.watch(walletRepositoryProvider);
  return await repository.getSessionById(sessionId);
});
