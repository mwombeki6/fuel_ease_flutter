// Basic widget test for FuelEase app

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/core/services/push_notification_service.dart';
import 'package:fuel_ease_flutter/core/providers/account_state_reset.dart';
import 'package:fuel_ease_flutter/main.dart';

void main() {
  testWidgets('FuelEase app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseMessagingAvailableProvider.overrideWithValue(false),
          accountStateResetProvider.overrideWithValue(() async {}),
        ],
        child: const FuelEaseApp(),
      ),
    );

    // Pump past splash animations to let their timers fire.
    await tester.pump(const Duration(seconds: 1));

    // Verify that the app builds without errors
    // We just check that the MaterialApp is created
    expect(find.byType(MaterialApp), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });
}
