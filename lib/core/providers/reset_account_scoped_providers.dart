import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/core/realtime/realtime_debug_provider.dart';
import 'package:fuel_ease_flutter/core/realtime/realtime_providers.dart';
import 'package:fuel_ease_flutter/core/realtime/realtime_pump_status_provider.dart';
import 'package:fuel_ease_flutter/core/realtime/realtime_status_provider.dart';
import 'package:fuel_ease_flutter/features/analytics/presentation/providers/analytics_provider.dart';
import 'package:fuel_ease_flutter/features/cards/presentation/providers/cards_provider.dart';
import 'package:fuel_ease_flutter/features/dashboard/presentation/providers/nearest_station_provider.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/providers/dispense_provider.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/providers/live_dispense_provider.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/providers/verification_provider.dart';
import 'package:fuel_ease_flutter/features/stations/data/repositories/stations_cache.dart';
import 'package:fuel_ease_flutter/features/stations/presentation/providers/station_details_provider.dart';
import 'package:fuel_ease_flutter/features/stations/presentation/providers/station_map_provider.dart';
import 'package:fuel_ease_flutter/features/stations/presentation/providers/station_provider.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/providers/fuel_sessions_provider.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/providers/spending_providers.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:fuel_ease_flutter/features/wallet/presentation/providers/wallet_transactions_provider.dart'
    as transaction_providers;

Future<void> resetAccountScopedProviders(Ref ref) async {
  try {
    ref.read(realtimeClientProvider).clearBufferedEvents();
  } catch (_) {}
  ref.invalidate(cardsProvider);
  ref.invalidate(cardByIdProvider);
  ref.invalidate(activeCardsCountProvider);
  ref.invalidate(totalCardsValueProvider);
  ref.invalidate(walletProvider);
  ref.invalidate(walletTransactionsProvider);
  ref.invalidate(availableBalanceProvider);
  ref.invalidate(walletStatusProvider);
  ref.invalidate(weeklySpendProvider);
  ref.invalidate(spendingChartDataProvider);
  ref.invalidate(transaction_providers.walletTransactionsProvider);
  ref.invalidate(transaction_providers.recentTransactionsProvider);
  ref.invalidate(dispenseProvider);
  ref.invalidate(dispenseRequestByIdProvider);
  ref.invalidate(liveDispenseProvider);
  ref.invalidate(verificationProvider);
  ref.invalidate(customerAnalyticsProvider);
  ref.invalidate(activeSessionsProvider);
  ref.invalidate(sessionByIdProvider);

  ref.invalidate(stationSelectionProvider);
  ref.invalidate(stationMapPinsProvider);
  ref.invalidate(stationDetailsProvider);
  ref.invalidate(stationInventoryProvider);
  ref.invalidate(stationPumpsProvider);
  ref.invalidate(nearestOrSelectedStationProvider);
  ref.invalidate(userLocationProvider);

  ref.invalidate(realtimeEventsProvider);
  ref.invalidate(realtimePumpStatusProvider);
  ref.invalidate(realtimeStatusProvider);
  ref.invalidate(realtimeDebugProvider);

  try {
    await ref.read(stationsCacheProvider).clear();
  } catch (_) {
    // In-memory account state is already invalidated if cache IO fails.
  }
}
