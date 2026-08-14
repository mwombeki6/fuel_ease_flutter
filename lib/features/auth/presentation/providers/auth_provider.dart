import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/core/api/api_error.dart';
import 'package:fuel_ease_flutter/core/api/token_refresh_service.dart';
import 'package:fuel_ease_flutter/core/providers/account_state_reset.dart';
import 'package:fuel_ease_flutter/core/realtime/realtime_client.dart';
import 'package:fuel_ease_flutter/core/services/push_notification_service.dart';
import 'package:fuel_ease_flutter/core/storage/secure_storage.dart';
import 'package:fuel_ease_flutter/features/auth/data/models/login_payload.dart';
import 'package:fuel_ease_flutter/features/auth/data/models/register_payload.dart';
import 'package:fuel_ease_flutter/features/auth/data/repositories/auth_repository.dart';
import 'package:fuel_ease_flutter/features/auth/presentation/providers/auth_state.dart';
import 'package:fuel_ease_flutter/shared/models/user.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(
    this._authRepository,
    this._secureStorage,
    this._tokenRefreshService,
    this._realtime,
    this._pushNotifications,
    this._resetAccountState,
  ) : super(const AuthState.initial()) {
    initialized = _init();
  }

  final AuthRepository _authRepository;
  final SecureStorage _secureStorage;
  final TokenRefreshService _tokenRefreshService;
  final RealtimeClient _realtime;
  final PushNotificationService _pushNotifications;
  final AccountStateReset _resetAccountState;
  late final Future<void> initialized;

  Future<void> _init() async {
    await _tokenRefreshService.beginSession();
    state = const AuthState.loading();
    try {
      if (!await _secureStorage.hasValidToken()) {
        String? refreshToken;
        String? sessionId;
        try {
          refreshToken = await _secureStorage.getRefreshToken();
          sessionId = await _secureStorage.read('session_id');
        } catch (_) {}
        if (refreshToken == null ||
            refreshToken.isEmpty ||
            sessionId == null ||
            sessionId.isEmpty) {
          try {
            await _secureStorage.clearAuth();
          } catch (_) {}
          state = const AuthState.unauthenticated();
          return;
        }
        String? refreshedToken;
        try {
          refreshedToken = await _tokenRefreshService.refreshAccessToken();
        } catch (error) {
          if (TokenRefreshService.isSessionRejection(error) ||
              error is FormatException) {
            rethrow;
          }
          final cachedUser = await _cachedCustomer();
          if (cachedUser != null) {
            state = AuthState.authenticated(cachedUser);
            try {
              _realtime.ensureConnected(cachedUser.id);
            } catch (_) {}
            return;
          }
          state = const AuthState.unauthenticated();
          return;
        }
        if (refreshedToken == null) {
          try {
            await _secureStorage.clearAuth();
          } catch (_) {}
          state = const AuthState.unauthenticated();
          return;
        }
      }

      final user = await _authRepository.getCurrentUser();
      if (!user.isCustomer) {
        try {
          await logout();
        } catch (_) {}
        state = const AuthState.error('This app is for customers only.');
        return;
      }
      try {
        await _secureStorage.saveUser(user.toJson());
      } catch (_) {}
      state = AuthState.authenticated(user);
      _registerFcmToken();
      try {
        _realtime.ensureConnected(user.id);
      } catch (_) {}
    } catch (error) {
      if (_isRejectedSession(error)) {
        try {
          await _secureStorage.clearAuth();
        } catch (_) {}
        state = const AuthState.unauthenticated();
        return;
      }
      final cachedUser = await _cachedCustomer();
      if (cachedUser != null) {
        state = AuthState.authenticated(cachedUser);
        try {
          _realtime.ensureConnected(cachedUser.id);
        } catch (_) {}
        return;
      }
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    final refreshInvalidated = _tokenRefreshService.invalidateSession();
    try {
      _realtime.clearSession();
    } catch (_) {}
    state = const AuthState.loading();
    try {
      final payload = LoginPayload(email: email, password: password);
      final response = await _authRepository.login(payload);

      if (!response.user.isCustomer) {
        await _saveSession(
          response.user,
          response.tokens.accessToken,
          response.tokens.refreshToken,
          response.tokens.expiresAt,
          response.sessionId,
        );
        try {
          await _authRepository.logout(response.sessionId);
        } catch (_) {}
        await _secureStorage.clearAuth();
        state = const AuthState.error('This app is for customers only.');
        return;
      }

      await refreshInvalidated;
      await _tokenRefreshService.beginSession();
      await _saveSession(
        response.user,
        response.tokens.accessToken,
        response.tokens.refreshToken,
        response.tokens.expiresAt,
        response.sessionId,
      );
      await _resetAccountStateSilently();

      state = AuthState.authenticated(response.user);
      _registerFcmToken();
      try {
        _realtime.ensureConnected(response.user.id);
      } catch (_) {}
    } catch (e) {
      await refreshInvalidated;
      await _tokenRefreshService.invalidateSession();
      try {
        await _secureStorage.clearAuth();
      } catch (_) {}
      state = AuthState.error(e is ApiError ? e.message : e.toString());
    }
  }

  Future<void> register(RegisterPayload payload) async {
    final refreshInvalidated = _tokenRefreshService.invalidateSession();
    try {
      _realtime.clearSession();
    } catch (_) {}
    state = const AuthState.loading();
    try {
      final response = await _authRepository.register(payload);

      if (!response.user.isCustomer) {
        await _saveSession(
          response.user,
          response.tokens.accessToken,
          response.tokens.refreshToken,
          response.tokens.expiresAt,
          response.sessionId,
        );
        try {
          await _authRepository.logout(response.sessionId);
        } catch (_) {}
        await _secureStorage.clearAuth();
        state = const AuthState.error('This app is for customers only.');
        return;
      }

      await refreshInvalidated;
      await _tokenRefreshService.beginSession();
      await _saveSession(
        response.user,
        response.tokens.accessToken,
        response.tokens.refreshToken,
        response.tokens.expiresAt,
        response.sessionId,
      );
      await _resetAccountStateSilently();

      state = AuthState.authenticated(response.user);
      _registerFcmToken();
      try {
        _realtime.ensureConnected(response.user.id);
      } catch (_) {}
    } catch (e) {
      await refreshInvalidated;
      await _tokenRefreshService.invalidateSession();
      try {
        await _secureStorage.clearAuth();
      } catch (_) {}
      state = AuthState.error(e is ApiError ? e.message : e.toString());
    }
  }

  Future<void> logout() async {
    String? sessionId;
    Object? serverError;
    StackTrace? serverStackTrace;
    final refreshInvalidated = _tokenRefreshService.invalidateSession();
    try {
      try {
        sessionId = await _secureStorage.read('session_id');
      } catch (_) {
        sessionId = null;
      }
      if (sessionId != null && sessionId.isNotEmpty) {
        await _authRepository.logout(sessionId);
      }
    } catch (error, stackTrace) {
      serverError = error;
      serverStackTrace = stackTrace;
      // Local logout must succeed even when the server cannot be reached.
    } finally {
      await refreshInvalidated;
      try {
        _realtime.clearSession();
      } catch (_) {}
      try {
        await _secureStorage.clearAuth();
      } catch (_) {}
      state = const AuthState.unauthenticated();
      try {
        await _resetAccountState();
      } catch (_) {
        // Credentials are already gone; logout must remain locally complete.
      }
    }
    if (serverError != null) {
      Error.throwWithStackTrace(serverError, serverStackTrace!);
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;
    try {
      final updatedUser = await _authRepository.updateProfile(updates);
      await _secureStorage.saveUser(updatedUser.toJson());
      state = AuthState.authenticated(updatedUser);
    } catch (_) {
      // Keep the last confirmed profile when an update fails.
    }
  }

  Future<void> registerPushToken(String token, String platform) async {
    await _authRepository.registerPushToken(token, platform);
  }

  Future<void> _registerFcmToken() async {
    try {
      final token = await _pushNotifications.getToken();
      if (token == null) return;
      await _authRepository.registerPushToken(
        token,
        _pushNotifications.platform,
      );
    } catch (_) {}
  }

  /// Save all session data. expiresAt is Unix seconds — multiply by 1000 for ms.
  Future<void> _saveSession(
    User user,
    String accessToken,
    String refreshToken,
    int expiresAtSeconds,
    String sessionId,
  ) async {
    await _secureStorage.saveRefreshToken(refreshToken);
    await _secureStorage.saveExpiresAt(expiresAtSeconds * 1000);
    await _secureStorage.saveUser(user.toJson());
    await _secureStorage.save('session_id', sessionId);
    // Write access last so a partial save cannot look like a valid session.
    await _secureStorage.saveToken(accessToken);
  }

  void clearError() {
    if (state is AuthError) {
      state = const AuthState.unauthenticated();
    }
  }

  bool _isRejectedSession(Object error) {
    if (error is ApiError) return error.isAuthError;
    if (TokenRefreshService.isSessionRejection(error)) return true;
    return error is FormatException;
  }

  Future<User?> _cachedCustomer() async {
    try {
      final cachedUser = await _secureStorage.getUser();
      if (cachedUser == null) return null;
      final user = User.fromJson(cachedUser);
      return user.isCustomer ? user : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _resetAccountStateSilently() async {
    try {
      await _resetAccountState();
    } catch (_) {}
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final tokenRefreshService = ref.watch(tokenRefreshServiceProvider);
  final realtime = ref.watch(realtimeClientProvider);
  final pushNotifications = ref.watch(pushNotificationServiceProvider);
  final resetAccountState = ref.watch(accountStateResetProvider);
  return AuthNotifier(
    authRepository,
    secureStorage,
    tokenRefreshService,
    realtime,
    pushNotifications,
    resetAccountState,
  );
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.maybeWhen(authenticated: (_) => true, orElse: () => false);
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.maybeWhen(authenticated: (user) => user, orElse: () => null);
});
