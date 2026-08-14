import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef FirebaseInitializer = Future<void> Function(FirebaseOptions? options);
typedef MessagingInitializer = Future<void> Function();
typedef BackgroundHandlerRegistrar = void Function();

const bool firebaseEnabledByBuild = bool.fromEnvironment(
  'ENABLE_FIREBASE',
  defaultValue: kReleaseMode,
);

bool hasUsableFirebaseOptions(FirebaseOptions options) {
  final requiredValues = [
    options.apiKey,
    options.appId,
    options.messagingSenderId,
    options.projectId,
  ];
  return requiredValues.every(
    (value) =>
        value.isNotEmpty &&
        !value.toUpperCase().contains('PLACEHOLDER') &&
        !value.toUpperCase().contains('YOUR_'),
  );
}

/// Initializes push only when real Firebase configuration is present.
///
/// Push is off by default outside release builds. When enabled, debug/test
/// startup safely disables push on missing configuration; release startup
/// fails unless configured or explicitly disabled.
Future<bool> initializePushNotifications({
  bool enabled = firebaseEnabledByBuild,
  bool releaseMode = kReleaseMode,
  FirebaseOptions? options,
  FirebaseInitializer? initializeFirebase,
  MessagingInitializer? initializeMessaging,
  BackgroundHandlerRegistrar? registerBackgroundHandler,
}) async {
  if (!enabled) return false;

  if (options != null && !hasUsableFirebaseOptions(options)) {
    if (releaseMode) {
      throw StateError(
        'Firebase is enabled for release but credentials are missing. Add '
        'the native Firebase config files or build with '
        '`ENABLE_FIREBASE=false`.',
      );
    }
    return false;
  }

  try {
    // A null options value uses standard native google-services/plist config.
    await (initializeFirebase ?? _initializeFirebase)(options);
    await (initializeMessaging ?? _initializeMessaging)();
    (registerBackgroundHandler ?? _registerBackgroundHandler)();
    return true;
  } catch (error) {
    if (releaseMode) {
      throw StateError('Firebase push initialization failed: $error');
    }
    return false;
  }
}

Future<void> _initializeFirebase(FirebaseOptions? options) async {
  if (options == null) {
    await Firebase.initializeApp();
  } else {
    await Firebase.initializeApp(options: options);
  }
}

Future<void> _initializeMessaging() async {
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
}

void _registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!firebaseEnabledByBuild) return;
  try {
    await Firebase.initializeApp();
  } catch (_) {
    return;
  }
}

class PushNotificationService {
  const PushNotificationService({required this.isAvailable});

  final bool isAvailable;

  Future<String?> getToken() async {
    if (!isAvailable) return null;
    return FirebaseMessaging.instance.getToken();
  }

  Future<RemoteMessage?> getInitialMessage() async {
    if (!isAvailable) return null;
    return FirebaseMessaging.instance.getInitialMessage();
  }

  Stream<RemoteMessage> get onMessage =>
      isAvailable ? FirebaseMessaging.onMessage : const Stream.empty();

  Stream<RemoteMessage> get onMessageOpenedApp =>
      isAvailable ? FirebaseMessaging.onMessageOpenedApp : const Stream.empty();

  String get platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
}

final firebaseMessagingAvailableProvider = Provider<bool>((ref) => false);

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  return PushNotificationService(
    isAvailable: ref.watch(firebaseMessagingAvailableProvider),
  );
});
