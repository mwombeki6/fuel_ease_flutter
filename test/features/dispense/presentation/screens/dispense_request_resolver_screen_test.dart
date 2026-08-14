import 'package:flutter_test/flutter_test.dart';

import 'package:fuel_ease_flutter/features/dispense/data/models/dispense_request.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/screens/dispense_request_resolver_screen.dart';

DispenseRequest _request(String status) => DispenseRequest(
  id: 'request-id',
  cardId: 'card-id',
  stationId: 'station-id',
  requestedLiters: 10,
  pricePerLiterTzs: 3000,
  status: status,
  createdAt: DateTime(2026),
);

void main() {
  test('pending direct links resolve to safe token status', () {
    expect(
      destinationForDispenseRequest(_request('pending')),
      DispenseRequestDestination.token,
    );
  });

  test('approved and active direct links resolve to live state', () {
    expect(
      destinationForDispenseRequest(_request('approved')),
      DispenseRequestDestination.live,
    );
    expect(
      destinationForDispenseRequest(_request('active')),
      DispenseRequestDestination.live,
    );
  });

  test('terminal direct links resolve by server status', () {
    expect(
      destinationForDispenseRequest(_request('completed')),
      DispenseRequestDestination.complete,
    );
    expect(
      destinationForDispenseRequest(_request('cancelled')),
      DispenseRequestDestination.cancelled,
    );
    expect(
      destinationForDispenseRequest(_request('rejected')),
      DispenseRequestDestination.cancelled,
    );
    expect(
      destinationForDispenseRequest(_request('expired')),
      DispenseRequestDestination.cancelled,
    );
  });
}
