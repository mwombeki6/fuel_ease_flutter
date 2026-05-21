import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_ease_flutter/features/cards/presentation/providers/card_sessions_provider.dart';
import 'package:fuel_ease_flutter/features/dispense/data/models/dispense_request.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/providers/dispense_provider.dart';

DispenseRequest _req(String id, String cardId, DateTime createdAt) =>
    DispenseRequest(
      id: id,
      cardId: cardId,
      stationId: 'station-1',
      requestedLiters: 10.0,
      pricePerLiterTzs: 4000,
      status: 'completed',
      createdAt: createdAt,
    );

void main() {
  test('cardSessionsProvider filters by cardId and sorts most-recent first', () async {
    final now = DateTime.now();
    final allRequests = [
      _req('r1', 'card-A', now.subtract(const Duration(hours: 5))),
      _req('r2', 'card-B', now.subtract(const Duration(hours: 2))),
      _req('r3', 'card-A', now.subtract(const Duration(hours: 1))),
    ];

    final container = ProviderContainer(
      overrides: [
        dispenseProvider.overrideWith(
          () => _FakeDispenseNotifier(allRequests),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(dispenseProvider.future);
    final sessions = container.read(cardSessionsProvider('card-A'));
    expect(sessions.length, 2);
    expect(sessions.first.id, 'r3'); // most recent first
    expect(sessions.last.id, 'r1');
  });

  test('cardSessionsProvider returns empty list when dispenseProvider loading', () {
    final container = ProviderContainer(
      overrides: [
        dispenseProvider.overrideWith(() => _LoadingDispenseNotifier()),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(cardSessionsProvider('card-A')), isEmpty);
  });
}

class _FakeDispenseNotifier extends DispenseNotifier {
  _FakeDispenseNotifier(this._data);
  final List<DispenseRequest> _data;

  @override
  Future<List<DispenseRequest>> build() async => _data;
}

class _LoadingDispenseNotifier extends DispenseNotifier {
  @override
  Future<List<DispenseRequest>> build() => Completer<List<DispenseRequest>>().future;
}
