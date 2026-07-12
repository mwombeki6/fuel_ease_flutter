import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/core/routing/routes.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/providers/dispense_provider.dart';
import 'package:fuel_ease_flutter/features/stations/presentation/providers/station_map_provider.dart';

/// Kind of action the Home alert banner is surfacing. Kept as an enum (per
/// the spec's `PendingAction { type, label, route }` shape — Section 6 of
/// docs/superpowers/specs/2026-07-12-home-mapfirst-redesign-design.md) so
/// new backend-supported states can be added later without a UI rewrite.
enum PendingActionType {
  /// Backend `DispensingRequest.Status` is `active` (fuel is flowing) or
  /// `approved` (pump has confirmed the PIN; `pin_qr_screen.dart` already
  /// treats `approved` and `active` identically — both leave the "waiting"
  /// screen for the live-dispense screen).
  fuelingInProgress,

  /// Backend `DispensingRequest.Status` is `pending` — PIN/QR generated,
  /// not yet validated by the pump.
  awaitingPumpConfirmation,
}

/// A single actionable item for the Home screen's conditional alert banner.
class PendingAction {
  const PendingAction({
    required this.type,
    required this.label,
    required this.route,
  });

  final PendingActionType type;
  final String label;
  final String route;
}

/// Surfaces the single highest-priority in-flight dispense action for the
/// Home alert banner, or `null` when there's nothing to show.
///
/// **Data source note (see Task 5 investigation):** this watches
/// `dispenseProvider` (`lib/features/dispense/presentation/providers/dispense_provider.dart`),
/// which exposes the current user's real `List<DispenseRequest>` — NOT
/// `activeSessionsProvider`/`FuelSession`
/// (`lib/features/wallet/presentation/providers/fuel_sessions_provider.dart`),
/// which is an explicitly-labelled stub ("sessions replaced by dispense
/// requests in Wave 4") that always resolves to `[]`. `FuelSession` itself
/// also has no station-name field, so it could not have driven the
/// `"Fueling in progress at {stationName}"` copy the spec calls for even if
/// it were live.
///
/// `DispenseRequest.status` already mirrors the backend's
/// `pending -> approved -> active -> completed` lifecycle via
/// `isPending`/`isApproved`/`isActive`/`isCompleted`/`isCancelled` getters
/// (`lib/features/dispense/data/models/dispense_request.dart`), and
/// `pin_qr_screen.dart` already relies on that exact distinction in
/// production code (`_startPolling`: `(request.isActive || request.isApproved)`
/// navigates off the PIN/QR "waiting" screen). So, unlike the brief's
/// caution that a "pending" signal might not exist, a real one does — both
/// priority branches below are wired.
///
/// Station names are resolved via `stationMapPinsProvider`, the same
/// `{id: name}` lookup pattern already used for dispense requests in
/// `card_details_screen.dart`'s `_SessionsSection`, since `DispenseRequest`
/// itself only carries `stationId`.
final pendingActionsProvider = Provider.autoDispose<PendingAction?>((ref) {
  final requests = ref.watch(dispenseProvider).valueOrNull ?? const [];

  // Priority 1 (spec Section 6, item 1): an in-progress dispense. Bucketed
  // together with `approved` since the app's own PIN/QR screen already
  // treats the two as equivalent ("no longer waiting").
  for (final request in requests) {
    if (request.isActive || request.isApproved) {
      return PendingAction(
        type: PendingActionType.fuelingInProgress,
        label: 'Fueling in progress at ${_stationLabel(ref, request.stationId)}',
        route: Routes.dispensingRequestDetails(request.id),
      );
    }
  }

  // Priority 2 (spec Section 6, item 2): PIN/QR generated, not yet
  // validated by the pump.
  for (final request in requests) {
    if (request.isPending) {
      return PendingAction(
        type: PendingActionType.awaitingPumpConfirmation,
        label: 'Waiting for pump confirmation',
        route: Routes.dispensingRequestDetails(request.id),
      );
    }
  }

  // Priorities 3-4 from the spec (low wallet balance / another in-flight
  // action such as an unconfirmed recharge) are intentionally not wired:
  // investigation of lib/features/wallet/presentation/providers/ found no
  // existing low-balance threshold or in-flight-recharge signal to reuse,
  // and the spec explicitly forbids inventing new ones for this delivery.
  // See Task 5 report for what was checked.

  return null;
});

String _stationLabel(Ref ref, String stationId) {
  final pins = ref.watch(stationMapPinsProvider).valueOrNull;
  if (pins != null) {
    for (final pin in pins) {
      if (pin.id == stationId) return pin.name;
    }
  }
  // Fallback mirrors card_details_screen.dart's `_SessionsSection`.
  final tail =
      stationId.length > 8 ? stationId.substring(stationId.length - 8) : stationId;
  return 'Station …$tail';
}
