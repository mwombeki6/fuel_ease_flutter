import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fuel_ease_flutter/features/dispense/data/models/dispense_request.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/providers/dispense_provider.dart';
import 'package:fuel_ease_flutter/features/dispense/presentation/screens/dispense_history_screen.dart';

// ---------------------------------------------------------------------------
// Fake notifiers — must extend DispenseNotifier so overrideWith type-checks.
// ---------------------------------------------------------------------------

class _FakeDispenseNotifier extends DispenseNotifier {
  final List<DispenseRequest> _data;
  _FakeDispenseNotifier(this._data);

  @override
  Future<List<DispenseRequest>> build() async => _data;

  @override
  Future<void> refresh() async => state = AsyncData(_data);
}

// ---------------------------------------------------------------------------
// Sample data
// ---------------------------------------------------------------------------

DispenseRequest _makeRequest({
  String id = 'req-001',
  String status = 'pending',
  double requestedLiters = 2.0,
  double? actualLiters,
}) =>
    DispenseRequest(
      id: id,
      cardId: 'card-001',
      stationId: 'station-001',
      requestedLiters: requestedLiters,
      pricePerLiterTzs: 4000,
      status: status,
      createdAt: DateTime(2026, 5, 10, 8, 0),
      actualLiters: actualLiters,
    );

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

Widget _buildScreen(List<DispenseRequest> data) => ProviderScope(
      overrides: [
        dispenseProvider.overrideWith(() => _FakeDispenseNotifier(data)),
      ],
      child: const MaterialApp(home: DispenseHistoryScreen()),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('DispenseHistoryScreen — empty state', () {
    testWidgets('shows empty placeholder when no requests', (tester) async {
      await tester.pumpWidget(_buildScreen([]));
      await tester.pump();

      expect(find.text('No dispense requests yet'), findsOneWidget);
    });
  });

  group('DispenseHistoryScreen — list rendering', () {
    testWidgets('shows one card per request', (tester) async {
      final requests = [
        _makeRequest(id: 'req-001', status: 'pending'),
        _makeRequest(id: 'req-002', status: 'completed'),
      ];
      await tester.pumpWidget(_buildScreen(requests));
      await tester.pump();

      // Each card shows the liters
      expect(find.textContaining('2'), findsWidgets);
      // Status badges
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('shows dispensed liters on completed requests', (tester) async {
      final requests = [
        _makeRequest(
          id: 'req-003',
          status: 'completed',
          actualLiters: 1.5,
        ),
      ];
      await tester.pumpWidget(_buildScreen(requests));
      await tester.pump();

      expect(find.textContaining('Dispensed'), findsOneWidget);
    });

    testWidgets('does not show dispensed row for pending requests', (tester) async {
      await tester.pumpWidget(_buildScreen([_makeRequest()]));
      await tester.pump();

      expect(find.textContaining('Dispensed'), findsNothing);
    });
  });

  group('DispenseHistoryScreen — tapping opens detail sheet', () {
    testWidgets('tapping a list item opens the detail bottom sheet', (tester) async {
      await tester.pumpWidget(_buildScreen([_makeRequest()]));
      await tester.pump();

      // Tap the first item
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // The detail sheet should be visible — it always shows Request ID section
      expect(find.text('Request ID'), findsOneWidget);
    });

    testWidgets('detail sheet shows correct status label', (tester) async {
      await tester.pumpWidget(_buildScreen([
        _makeRequest(status: 'approved'),
      ]));
      await tester.pump();

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(find.text('Approved'), findsWidgets);
    });

    testWidgets('detail sheet shows Requested row with liters', (tester) async {
      await tester.pumpWidget(_buildScreen([
        _makeRequest(requestedLiters: 3.0),
      ]));
      await tester.pump();

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(find.text('Requested'), findsOneWidget);
      // The value should contain the formatted liters
      expect(find.textContaining('L'), findsWidgets);
    });

    testWidgets('detail sheet shows Dispensed row only when actualLiters is set',
        (tester) async {
      await tester.pumpWidget(_buildScreen([
        _makeRequest(status: 'completed', actualLiters: 2.0),
      ]));
      await tester.pump();

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(find.text('Dispensed'), findsOneWidget);
    });
  });

  group('DispenseHistoryScreen — refresh', () {
    testWidgets('refresh button is present in app bar', (tester) async {
      await tester.pumpWidget(_buildScreen([]));
      await tester.pump();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });

  group('DispenseHistoryScreen — error state', () {
    testWidgets('shows error view and retry button on error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dispenseProvider.overrideWith(
              () => _ErrorDispenseNotifier(),
            ),
          ],
          child: const MaterialApp(home: DispenseHistoryScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('Try Again'), findsOneWidget);
    });
  });
}

class _ErrorDispenseNotifier extends DispenseNotifier {
  @override
  Future<List<DispenseRequest>> build() async =>
      throw Exception('network error');
}
