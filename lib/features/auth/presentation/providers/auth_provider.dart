import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'package:fuel_ease_flutter/core/api/api_error.dart';
import 'package:fuel_ease_flutter/core/realtime/realtime_client.dart';
import 'package:fuel_ease_flutter/core/storage/secure_storage.dart';
import 'package:fuel_ease_flutter/features/auth/data/models/login_payload.dart';
import 'package:fuel_ease_flutter/features/auth/data/models/register_payload.dart';
import 'package:fuel_ease_flutter/features/auth/data/repositories/auth_repository.dart';
import 'package:fuel_ease_flutter/features/auth/presentation/providers/auth_state.dart';
import 'package:fuel_ease_flutter/shared/models/user.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authRepository, this._secureStorage, this._realtime)
      : super(const AuthState.initial()) {
    _init();
  }

  final AuthRepository _authRepository;
  final SecureStorage _secureStorage;
  final RealtimeClient _realtime;
  final Logger _logger = Logger();

  Future<void> _init() async {
    state = const AuthState.loading();
    try {
      final hasValidToken = await _secureStorage.hasValidToken();
      if (hasValidToken) {
        final user = await _authRepository.getCurrentUser();
        if (user.isCustomer) {
          state = AuthState.authenticated(user);
          _realtime.connect();
        } else {
          await logout();
          state = const AuthState.error('This app is for customers only.');
        }
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      _logger.e('Auth init failed', error: e);
      await _secureStorage.clearAuth();
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthState.loading();
    try {
      final payload = LoginPayload(email: email, password: password);
      final response = await _authRepository.login(payload);

      if (!response.user.isCustomer) {
        state = const AuthState.error('This app is for customers only.');
        return;
      }

      await _saveSession(response.user, response.tokens.accessToken,
          response.tokens.refreshToken, response.tokens.expiresAt, response.sessionId);

      state = AuthState.authenticated(response.user);
      _registerFcmToken();
      _realtime.connect();
    } catch (e) {
      _logger.e('Login failed', error: e);
      state = AuthState.error(e is ApiError ? e.message : e.toString());
    }
  }

  Future<void> register(RegisterPayload payload) async {
    state = const AuthState.loading();
    try {
      final response = await _authRepository.register(payload);

      await _saveSession(response.user, response.tokens.accessToken,
          response.tokens.refreshToken, response.tokens.expiresAt, response.sessionId);

      state = AuthState.authenticated(response.user);
      _registerFcmToken();
      _realtime.connect();
    } catch (e) {
      _logger.e('Registration failed', error: e);
      state = AuthState.error(e is ApiError ? e.message : e.toString());
    }
  }

  Future<void> logout() async {
    _realtime.disconnect();
    final sessionId = await _secureStorage.read('session_id');
    await _secureStorage.clearAuth();
    state = const AuthState.unauthenticated();
    if (sessionId != null) {
      // Best-effort — don't block logout on network failure
      () async {
        try {
          await _authRepository.logout(sessionId);
        } catch (e) {
          _logger.w('Server logout failed (ignored): $e');
        }
      }();
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;
    try {
      final updatedUser = await _authRepository.updateProfile(updates);
      await _secureStorage.saveUser(updatedUser.toJson());
      state = AuthState.authenticated(updatedUser);
    } catch (e) {
      _logger.e('Profile update failed', error: e);
    }
  }

  Future<void> registerPushToken(String token, String platform) async {
    await _authRepository.registerPushToken(token, platform);
  }

  void _registerFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      final platform = Platform.isIOS ? 'ios' : 'android';
      await _authRepository.registerPushToken(token, platform);
    } catch (e) {
      _logger.w('FCM token registration skipped: $e');
    }
  }

  /// Save all session data. expiresAt is Unix seconds — multiply by 1000 for ms.
  Future<void> _saveSession(User user, String accessToken, String refreshToken,
      int expiresAtSeconds, String sessionId) async {
    await _secureStorage.saveToken(accessToken);
    await _secureStorage.saveRefreshToken(refreshToken);
    await _secureStorage.saveExpiresAt(expiresAtSeconds * 1000);
    await _secureStorage.saveUser(user.toJson());
    await _secureStorage.save('session_id', sessionId);
  }

  void clearError() {
    if (state is AuthError) {
      state = const AuthState.unauthenticated();
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final realtime = ref.watch(realtimeClientProvider);
  return AuthNotifier(authRepository, secureStorage, realtime);
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.maybeWhen(authenticated: (_) => true, orElse: () => false);
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.maybeWhen(authenticated: (user) => user, orElse: () => null);
});
