import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/core/storage/secure_storage.dart';
import 'package:fuel_ease_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fuel_ease_flutter/features/stations/data/models/station.dart';
import 'package:fuel_ease_flutter/features/stations/data/repositories/stations_repository.dart';
import 'package:fuel_ease_flutter/features/stations/data/repositories/stations_cache.dart';

class StationSelectionState {
  const StationSelectionState({
    this.stationId,
    this.stationName,
    this.stations = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.fromCache = false,
    this.lastUpdated,
    this.error,
  });

  final String? stationId;
  final String? stationName;
  final List<Station> stations;
  final bool isLoading;
  final bool isRefreshing;
  final bool fromCache;
  final DateTime? lastUpdated;
  final String? error;

  StationSelectionState copyWith({
    String? stationId,
    String? stationName,
    List<Station>? stations,
    bool? isLoading,
    bool? isRefreshing,
    bool? fromCache,
    DateTime? lastUpdated,
    String? error,
  }) {
    return StationSelectionState(
      stationId: stationId ?? this.stationId,
      stationName: stationName ?? this.stationName,
      stations: stations ?? this.stations,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      fromCache: fromCache ?? this.fromCache,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      error: error,
    );
  }
}

class StationSelectionNotifier extends StateNotifier<StationSelectionState> {
  StationSelectionNotifier(this._repository, this._storage, this._cache, this._userRole)
      : super(const StationSelectionState()) {
    _loadStations(initialLoad: true);
  }

  final StationsRepository _repository;
  final SecureStorage _storage;
  final StationsCache _cache;
  final String _userRole;

  Future<void> _loadStations({bool initialLoad = false}) async {
    if (initialLoad) {
      final cached = await _cache.getStations();
      if (cached != null && cached.data.isNotEmpty) {
        state = state.copyWith(
          stations: cached.data,
          isLoading: false,
          isRefreshing: false,
          fromCache: true,
          lastUpdated: cached.updatedAt,
          error: null,
        );
      }
    }

    final showLoading = state.stations.isEmpty;
    state = state.copyWith(
      isLoading: showLoading,
      isRefreshing: !showLoading,
      error: null,
    );

    if (initialLoad) {
      final savedStationId = await _storage.getPreferredStationId();
      if (savedStationId != null && savedStationId.isNotEmpty) {
        state = state.copyWith(stationId: savedStationId);
      }

      if (state.stationId != null && state.stations.isNotEmpty) {
        final selected = state.stations.firstWhere(
          (station) => station.id == state.stationId,
          orElse: () => state.stations.first,
        );
        await setStation(selected);
      }
    }

    try {
      final isStationRole = _userRole == 'station_admin' || _userRole == 'station_manager';
      final stations = isStationRole
          ? await _repository.getMyStations()
          : await _repository.getStations();
      await _cache.setStations(stations);
      state = state.copyWith(stations: stations, isLoading: false, error: null);

      if (state.stationId == null && stations.isNotEmpty) {
        await setStation(stations.first);
      } else if (state.stationId != null && stations.isNotEmpty) {
        final selected = stations.firstWhere(
          (station) => station.id == state.stationId,
          orElse: () => stations.first,
        );
        await setStation(selected);
      }
      state = state.copyWith(
        stations: stations,
        isLoading: false,
        isRefreshing: false,
        fromCache: false,
        lastUpdated: DateTime.now(),
        error: null,
      );
    } catch (e) {
      final hasData = state.stations.isNotEmpty;
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: hasData ? null : e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    await _loadStations();
  }

  Future<void> setStation(Station station) async {
    state = state.copyWith(
      stationId: station.id,
      stationName: station.name,
    );
    await _storage.savePreferredStationId(station.id);
  }

  Future<void> clearStation() async {
    state = state.copyWith(stationId: null, stationName: null);
    await _storage.clearPreferredStationId();
  }
}

final stationSelectionProvider =
    StateNotifierProvider<StationSelectionNotifier, StationSelectionState>(
        (ref) {
  final repository = ref.watch(stationsRepositoryProvider);
  final storage = ref.watch(secureStorageProvider);
  final cache = ref.watch(stationsCacheProvider);
  final userRole = ref.watch(authProvider).maybeWhen(
    authenticated: (u) => u.role,
    orElse: () => 'customer',
  );
  return StationSelectionNotifier(repository, storage, cache, userRole);
});
