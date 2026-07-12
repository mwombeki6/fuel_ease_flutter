import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_ease_flutter/features/dashboard/presentation/providers/pending_actions_provider.dart';
import 'package:fuel_ease_flutter/features/dispense/data/models/dispense_request.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/providers/dispense_provider.dart';
import 'package:fuel_ease_flutter/features/stations/data/models/station_map_pin.dart';
import 'package:fuel_ease_flutter/features/stations/presentation/providers/station_map_provider.dart';

DispenseRequest _req({
  required String id,
  required String status,
  String stationId = 'station-1',
}) =>
    DispenseRequest(
      id: id,
      cardId: 'card-1',
      stationId: stationId,
      requestedLiters: 10.0,
      pricePerLiterTzs: 4000,
      status: status,
      createdAt: DateTime.now(),
    );

StationMapPin _pin(String id, String name) => StationMapPin(
      id: id,
      name: name,
      lat: -6.8,
      lng: 39.2,
      status: 'active',
      region: 'Dar es Salaam',
      district: 'Kinondoni',
      activePumps: 2,
      hasSuspension: false,
    );

class _FakeDispenseNotifier extends DispenseNotifier {
  _FakeDispenseNotifier(this._data);
  final List<DispenseRequest> _data;

  @override
  Future<List<DispenseRequest>> build() async => _data;
}

ProviderContainer _containerWith({
  required List<DispenseRequest> requests,
  List<StationMapPin> pins = const [],
}) {
  final container = ProviderContainer(
    overrides: [
      dispenseProvider.overrideWith(() => _FakeDispenseNotifier(requests)),
      stationMapPinsProvider.overrideWith((ref) async => pins),
    ],
  );
  return container;
}

void main() {
  test('returns a fueling-in-progress action when a request is active',
      () async {
    final container = _containerWith(
      requests: [_req(id: 'r1', status: 'active', stationId: 'station-1')],
      pins: [_pin('station-1', 'Mwenge Fuel Point')],
    );
    addTearDown(container.dispose);

    await container.read(dispenseProvider.future);
    await container.read(stationMapPinsProvider.future);

    final action = container.read(pendingActionsProvider);
    expect(action?.label, 'Fueling in progress at Mwenge Fuel Point');
    expect(action?.type, PendingActionType.fuelingInProgress);
    expect(action?.route, isNotEmpty);
  });

  test(
      'falls back to a truncated station id when the station name is unknown',
      () async {
    final container = _containerWith(
      requests: [
        _req(id: 'r1', status: 'active', stationId: 'station-unknown-123')
      ],
      pins: const [],
    );
    addTearDown(container.dispose);

    await container.read(dispenseProvider.future);
    await container.read(stationMapPinsProvider.future);

    final action = container.read(pendingActionsProvider);
    expect(action?.label, contains('Fueling in progress at Station'));
  });

  test(
      'returns a waiting-for-pump-confirmation action when a request is pending',
      () async {
    final container = _containerWith(
      requests: [_req(id: 'r1', status: 'pending')],
    );
    addTearDown(container.dispose);

    await container.read(dispenseProvider.future);
    await container.read(stationMapPinsProvider.future);

    final action = container.read(pendingActionsProvider);
    expect(action?.label, 'Waiting for pump confirmation');
    expect(action?.type, PendingActionType.awaitingPumpConfirmation);
  });

  test('prioritizes an active request over a pending one', () async {
    final container = _containerWith(
      requests: [
        _req(id: 'r1', status: 'pending'),
        _req(id: 'r2', status: 'active', stationId: 'station-2'),
      ],
      pins: [_pin('station-2', 'Kinondoni Station')],
    );
    addTearDown(container.dispose);

    await container.read(dispenseProvider.future);
    await container.read(stationMapPinsProvider.future);

    final action = container.read(pendingActionsProvider);
    expect(action?.type, PendingActionType.fuelingInProgress);
    expect(action?.label, 'Fueling in progress at Kinondoni Station');
  });

  test('treats an approved request the same as an active one', () async {
    final container = _containerWith(
      requests: [_req(id: 'r1', status: 'approved', stationId: 'station-1')],
      pins: [_pin('station-1', 'Mwenge Fuel Point')],
    );
    addTearDown(container.dispose);

    await container.read(dispenseProvider.future);
    await container.read(stationMapPinsProvider.future);

    final action = container.read(pendingActionsProvider);
    expect(action?.type, PendingActionType.fuelingInProgress);
  });

  test('returns null when there are no active or pending requests', () async {
    final container = _containerWith(
      requests: [
        _req(id: 'r1', status: 'completed'),
        _req(id: 'r2', status: 'cancelled'),
      ],
    );
    addTearDown(container.dispose);

    await container.read(dispenseProvider.future);
    await container.read(stationMapPinsProvider.future);

    expect(container.read(pendingActionsProvider), isNull);
  });

  test('returns null when there are no requests at all', () async {
    final container = _containerWith(requests: const []);
    addTearDown(container.dispose);

    await container.read(dispenseProvider.future);
    await container.read(stationMapPinsProvider.future);

    expect(container.read(pendingActionsProvider), isNull);
  });
}
