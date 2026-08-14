import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fuel_ease_flutter/core/services/push_notification_service.dart';

const _validOptions = FirebaseOptions(
  apiKey: 'api-key',
  appId: 'app-id',
  messagingSenderId: 'sender-id',
  projectId: 'project-id',
);

const _placeholderOptions = FirebaseOptions(
  apiKey: 'PLACEHOLDER',
  appId: 'PLACEHOLDER',
  messagingSenderId: 'PLACEHOLDER',
  projectId: 'PLACEHOLDER',
);

void main() {
  test(
    'placeholder configuration disables push without platform calls',
    () async {
      var firebaseCalls = 0;
      final result = await initializePushNotifications(
        enabled: true,
        releaseMode: false,
        options: _placeholderOptions,
        initializeFirebase: (_) async => firebaseCalls++,
        initializeMessaging: () async => fail('Messaging must not initialize'),
      );

      expect(result, isFalse);
      expect(firebaseCalls, 0);
    },
  );

  test('release requires configuration when Firebase is enabled', () async {
    await expectLater(
      initializePushNotifications(
        enabled: true,
        releaseMode: true,
        options: _placeholderOptions,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('explicitly disabled Firebase skips all setup in release', () async {
    final result = await initializePushNotifications(
      enabled: false,
      releaseMode: true,
      initializeFirebase: (_) async => fail('Firebase must not initialize'),
      initializeMessaging: () async => fail('Messaging must not initialize'),
    );

    expect(result, isFalse);
  });

  test(
    'successful setup is reported only after messaging initializes',
    () async {
      final calls = <String>[];
      final result = await initializePushNotifications(
        enabled: true,
        releaseMode: false,
        options: _validOptions,
        initializeFirebase: (_) async => calls.add('firebase'),
        initializeMessaging: () async => calls.add('messaging'),
        registerBackgroundHandler: () => calls.add('background'),
      );

      expect(result, isTrue);
      expect(calls, ['firebase', 'messaging', 'background']);
    },
  );

  test('debug startup does not fake success when setup fails', () async {
    final result = await initializePushNotifications(
      enabled: true,
      releaseMode: false,
      options: _validOptions,
      initializeFirebase: (_) async {},
      initializeMessaging: () async => throw StateError('no credentials'),
      registerBackgroundHandler: () => fail('Must not register on failure'),
    );

    expect(result, isFalse);
  });
}
