import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fuel_ease_flutter/core/api/api_client.dart';
import 'package:fuel_ease_flutter/core/api/token_refresh_service.dart';
import 'package:fuel_ease_flutter/core/storage/secure_storage.dart';

class _MemorySecureStorage extends SecureStorage {
  _MemorySecureStorage() : super(const FlutterSecureStorage());

  final values = <String, String>{};
  Completer<void>? saveRefreshStarted;
  Future<void>? saveRefreshBarrier;

  @override
  Future<void> saveToken(String token) async => values['token'] = token;

  @override
  Future<String?> getToken() async => values['token'];

  @override
  Future<bool> hasValidToken() async => values['token'] != null;

  @override
  Future<void> saveRefreshToken(String refreshToken) async {
    values['refresh'] = refreshToken;
    saveRefreshStarted?.complete();
    await saveRefreshBarrier;
  }

  @override
  Future<String?> getRefreshToken() async => values['refresh'];

  @override
  Future<void> saveExpiresAt(int expiresAt) async =>
      values['expires'] = '$expiresAt';

  @override
  Future<void> save(String key, String value) async => values[key] = value;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> clearAuth() async => values.clear();

  @override
  Future<void> saveUser(Map<String, dynamic> userData) async {}
}

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter({
    this.includeRotatedSession = true,
    this.protectedResponseDelay = Duration.zero,
  });

  final bool includeRotatedSession;
  final Duration protectedResponseDelay;
  int refreshCount = 0;
  int protectedCount = 0;
  final protectedAuthorizations = <String?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/auth/refresh') {
      refreshCount++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return _jsonResponse(200, {
        'data': {
          'tokens': {
            'access_token': 'new-access',
            if (includeRotatedSession) 'refresh_token': 'new-refresh',
            'expires_at': 2000000000,
          },
          if (includeRotatedSession) 'session_id': 'new-session',
        },
      });
    }

    protectedCount++;
    final authorization = options.headers['Authorization']?.toString();
    protectedAuthorizations.add(authorization);
    if (authorization != 'Bearer new-access') {
      await Future<void>.delayed(protectedResponseDelay);
      return _jsonResponse(401, {
        'error': {'message': 'expired'},
      });
    }
    return _jsonResponse(200, {
      'data': {'ok': true},
    });
  }

  ResponseBody _jsonResponse(int status, Map<String, dynamic> body) {
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiClient _client(_MemorySecureStorage storage, _ScriptedAdapter adapter) {
  final refreshDio = Dio()..httpClientAdapter = adapter;
  final refreshService = TokenRefreshService(storage, dio: refreshDio);
  final requestDio = Dio(
    BaseOptions(
      baseUrl: 'https://example.test',
      validateStatus: apiValidateStatus,
    ),
  )..httpClientAdapter = adapter;
  return ApiClient(
    storage,
    tokenRefreshService: refreshService,
    dio: requestDio,
    enableLogging: false,
  );
}

void main() {
  test('401 is routed through Dio error interceptors', () {
    expect(apiValidateStatus(200), isTrue);
    expect(apiValidateStatus(302), isTrue);
    expect(apiValidateStatus(401), isFalse);
  });

  test('401 refreshes tokens and retries the failed request', () async {
    final storage = _MemorySecureStorage()
      ..values.addAll({
        'token': 'expired-access',
        'refresh': 'refresh-token',
        'session_id': 'session-id',
      });
    final adapter = _ScriptedAdapter();
    final response = await _client(storage, adapter).get('/protected');

    expect(response.statusCode, 200);
    expect(adapter.refreshCount, 1);
    expect(adapter.protectedAuthorizations, [
      'Bearer expired-access',
      'Bearer new-access',
    ]);
    expect(storage.values['token'], 'new-access');
    expect(storage.values['refresh'], 'new-refresh');
    expect(storage.values['session_id'], 'new-session');
  });

  test('concurrent 401s share one refresh and each retry', () async {
    final storage = _MemorySecureStorage()
      ..values.addAll({
        'token': 'expired-access',
        'refresh': 'refresh-token',
        'session_id': 'session-id',
      });
    final adapter = _ScriptedAdapter();
    final client = _client(storage, adapter);

    final responses = await Future.wait([
      client.get('/protected/one'),
      client.get('/protected/two'),
    ]);

    expect(responses.map((response) => response.statusCode), everyElement(200));
    expect(adapter.refreshCount, 1);
    expect(adapter.protectedCount, 4);
    expect(
      adapter.protectedAuthorizations.where(
        (value) => value == 'Bearer new-access',
      ),
      hasLength(2),
    );
  });

  test('refresh accepts an access-only token response', () async {
    final storage = _MemorySecureStorage()
      ..values.addAll({
        'token': 'expired-access',
        'refresh': 'refresh-token',
        'session_id': 'session-id',
      });
    final adapter = _ScriptedAdapter(includeRotatedSession: false);

    final response = await _client(storage, adapter).get('/protected');

    expect(response.statusCode, 200);
    expect(storage.values['refresh'], 'refresh-token');
    expect(storage.values['session_id'], 'session-id');
  });

  test(
    'invalidating a session prevents an in-flight refresh from persisting',
    () async {
      final storage = _MemorySecureStorage()
        ..values.addAll({
          'token': 'expired-access',
          'refresh': 'refresh-token',
          'session_id': 'session-id',
        });
      final adapter = _ScriptedAdapter();
      final refreshDio = Dio()..httpClientAdapter = adapter;
      final service = TokenRefreshService(storage, dio: refreshDio);

      final refresh = service.refreshAccessToken();
      await Future<void>.delayed(Duration.zero);
      final invalidation = service.invalidateSession();
      await refresh;
      await invalidation;

      expect(storage.values['token'], 'expired-access');
      expect(adapter.refreshCount, 1);
    },
  );

  test('an old refresh cannot clear credentials from a new session', () async {
    final saveStarted = Completer<void>();
    final allowSave = Completer<void>();
    final storage = _MemorySecureStorage()
      ..values.addAll({
        'token': 'expired-access',
        'refresh': 'refresh-token',
        'session_id': 'session-id',
      })
      ..saveRefreshStarted = saveStarted
      ..saveRefreshBarrier = allowSave.future;
    final adapter = _ScriptedAdapter();
    final refreshDio = Dio()..httpClientAdapter = adapter;
    final service = TokenRefreshService(storage, dio: refreshDio);

    final refresh = service.refreshAccessToken();
    await saveStarted.future;
    final invalidation = service.invalidateSession();
    allowSave.complete();
    await invalidation;
    await service.beginSession();
    storage.values.addAll({
      'token': 'new-login-access',
      'refresh': 'new-login-refresh',
      'session_id': 'new-login-session',
    });

    expect(await refresh, isNull);
    expect(storage.values['token'], 'new-login-access');
    expect(storage.values['refresh'], 'new-login-refresh');
    expect(storage.values['session_id'], 'new-login-session');
  });

  test('a late 401 cannot restart refresh after logout', () async {
    final storage = _MemorySecureStorage()
      ..values.addAll({
        'token': 'expired-access',
        'refresh': 'refresh-token',
        'session_id': 'session-id',
      });
    final adapter = _ScriptedAdapter(
      protectedResponseDelay: const Duration(milliseconds: 20),
    );
    final refreshDio = Dio()..httpClientAdapter = adapter;
    final service = TokenRefreshService(storage, dio: refreshDio);
    final requestDio = Dio(
      BaseOptions(
        baseUrl: 'https://example.test',
        validateStatus: apiValidateStatus,
      ),
    )..httpClientAdapter = adapter;
    final client = ApiClient(
      storage,
      tokenRefreshService: service,
      dio: requestDio,
      enableLogging: false,
    );

    final request = client.get('/protected');
    await Future<void>.delayed(Duration.zero);
    await service.invalidateSession();
    await storage.clearAuth();

    await expectLater(request, throwsA(isA<DioException>()));
    expect(adapter.refreshCount, 0);
    expect(storage.values, isEmpty);
  });
}
