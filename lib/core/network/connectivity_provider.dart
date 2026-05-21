import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Streams the current connectivity state as a simple bool.
/// true = at least one network interface is up; false = fully offline.
final connectivityProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();
  return connectivity.onConnectivityChanged.map(
    (results) => results.any((r) => r != ConnectivityResult.none),
  );
});

/// Synchronous snapshot — true if last known state was online.
/// Defaults to true (optimistic) so we don't flash a banner before first event.
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).maybeWhen(
        data: (online) => online,
        orElse: () => true,
      );
});
