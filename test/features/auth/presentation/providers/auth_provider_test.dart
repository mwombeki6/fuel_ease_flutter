import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fuel_ease_flutter/core/api/api_client.dart';
import 'package:fuel_ease_flutter/core/api/token_refresh_service.dart';
import 'package:fuel_ease_flutter/core/realtime/realtime_client.dart';
import 'package:fuel_ease_flutter/core/services/push_notification_service.dart';
import 'package:fuel_ease_flutter/core/storage/secure_storage.dart';
import 'package:fuel_ease_flutter/features/auth/data/repositories/auth_repository.dart';
import 'package:fuel_ease_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fuel_ease_flutter/features/auth/presentation/providers/auth_state.dart';
import 'package:fuel_ease_flutter/shared/models/user.dart';

const _user = User(
  id: 'user-id',
  email: 'customer@example.com',
  role: 'customer',
  firstName: 'Fuel',
  lastName: 'Customer',
);

class _MemorySecureStorage extends SecureStorage {
  _MemorySecureStorage({required this.validToken})
    : super(const FlutterSecureStorage());

  bool validToken;
  final values = <String, String>{};
  final events = <String>[];
  Map<String, dynamic>? cachedUser;

  @override
  Future<bool> hasValidToken() async => validToken;

  @override
  Future<String?> getToken() async => values['token'];

  @override
  Future<String?> getRefreshToken() async => values['refresh'];

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> saveUser(Map<String, dynamic> userData) async {
    cachedUser = userData;
  }

  @override
  Future<Map<String, dynamic>?> getUser() async => cachedUser;

  @override
  Future<void> clearAuth() async {
    events.add('clear');
    values.clear();
  }
}

class _FakeTokenRefreshService extends TokenRefreshService {
  _FakeTokenRefreshService(super.storage, {required this.result});

  final String? result;
  Object? error;
  int calls = 0;
  int invalidations = 0;

  @override
  Future<void> beginSession() async {
    // Tests control refresh behavior directly through [result].
  }

  @override
  Future<String?> refreshAccessToken() async {
    calls++;
    if (error != null) throw error!;
    return result;
  }

  @override
  Future<void> invalidateSession() async {
    invalidations++;
  }
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository(SecureStorage storage, {this.logoutError})
    : _storage = storage,
      super(ApiClient(storage));

  final SecureStorage _storage;
  final Object? logoutError;
  final events = <String>[];

  @override
  Future<User> getCurrentUser() async => _user;

  @override
  Future<void> logout(String sessionId) async {
    events.add('server:${await _storage.getToken()}');
    if (logoutError != null) throw logoutError!;
  }
}

class _FakeRealtimeClient extends RealtimeClient {
  _FakeRealtimeClient(SecureStorage storage)
    : super(storage, ApiClient(storage));

  String? connectedUserId;
  bool sessionCleared = false;

  @override
  void ensureConnected(String userId) => connectedUserId = userId;

  @override
  void clearSession() => sessionCleared = true;
}

AuthNotifier _notifier({
  required _MemorySecureStorage storage,
  required _FakeTokenRefreshService refresh,
  required _FakeAuthRepository repository,
  required _FakeRealtimeClient realtime,
  required Future<void> Function() reset,
}) {
  return AuthNotifier(
    repository,
    storage,
    refresh,
    realtime,
    const PushNotificationService(isAvailable: false),
    reset,
  );
}

void main() {
  test(
    'startup refreshes an expired access token before loading the user',
    () async {
      final storage = _MemorySecureStorage(validToken: false)
        ..values.addAll({
          'token': 'expired-access',
          'refresh': 'refresh-token',
          'session_id': 'session-id',
        });
      final refresh = _FakeTokenRefreshService(storage, result: 'new-access');
      final repository = _FakeAuthRepository(storage);
      final realtime = _FakeRealtimeClient(storage);
      final notifier = _notifier(
        storage: storage,
        refresh: refresh,
        repository: repository,
        realtime: realtime,
        reset: () async {},
      );
      addTearDown(notifier.dispose);

      await notifier.initialized;

      expect(refresh.calls, 1);
      expect(notifier.state, const AuthState.authenticated(_user));
      expect(realtime.connectedUserId, _user.id);
      expect(storage.events, isEmpty);
    },
  );

  test(
    'startup keeps a cached session on a transient refresh failure',
    () async {
      final storage = _MemorySecureStorage(validToken: false)
        ..cachedUser = _user.toJson()
        ..values.addAll({
          'refresh': 'refresh-token',
          'session_id': 'session-id',
        });
      final refresh = _FakeTokenRefreshService(storage, result: null)
        ..error = StateError('offline');
      final repository = _FakeAuthRepository(storage);
      final realtime = _FakeRealtimeClient(storage);
      final notifier = _notifier(
        storage: storage,
        refresh: refresh,
        repository: repository,
        realtime: realtime,
        reset: () async {},
      );
      addTearDown(notifier.dispose);

      await notifier.initialized;

      expect(notifier.state, const AuthState.authenticated(_user));
      expect(storage.events, isEmpty);
    },
  );

  test(
    'logout calls server while authenticated, then clears local state',
    () async {
      final storage = _MemorySecureStorage(validToken: true)
        ..values.addAll({'token': 'access-token', 'session_id': 'session-id'});
      final refresh = _FakeTokenRefreshService(storage, result: null);
      final repository = _FakeAuthRepository(storage);
      final realtime = _FakeRealtimeClient(storage);
      var resets = 0;
      final notifier = _notifier(
        storage: storage,
        refresh: refresh,
        repository: repository,
        realtime: realtime,
        reset: () async => resets++,
      );
      addTearDown(notifier.dispose);
      await notifier.initialized;

      await notifier.logout();

      expect(repository.events, ['server:access-token']);
      expect(storage.events, ['clear']);
      expect(storage.values, isEmpty);
      expect(realtime.sessionCleared, isTrue);
      expect(refresh.invalidations, 1);
      expect(resets, 1);
      expect(notifier.state, const AuthState.unauthenticated());
    },
  );

  test('logout still clears local state when server logout fails', () async {
    final storage = _MemorySecureStorage(validToken: true)
      ..values.addAll({'token': 'access-token', 'session_id': 'session-id'});
    final refresh = _FakeTokenRefreshService(storage, result: null);
    final repository = _FakeAuthRepository(
      storage,
      logoutError: StateError('offline'),
    );
    final realtime = _FakeRealtimeClient(storage);
    var resets = 0;
    final notifier = _notifier(
      storage: storage,
      refresh: refresh,
      repository: repository,
      realtime: realtime,
      reset: () async => resets++,
    );
    addTearDown(notifier.dispose);
    await notifier.initialized;

    await expectLater(notifier.logout(), throwsStateError);

    expect(repository.events, ['server:access-token']);
    expect(storage.values, isEmpty);
    expect(resets, 1);
    expect(notifier.state, const AuthState.unauthenticated());
  });
}
