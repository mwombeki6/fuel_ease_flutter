import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'package:fuel_ease_flutter/core/storage/secure_storage.dart';
import 'package:fuel_ease_flutter/features/auth/data/models/login_payload.dart';
import 'package:fuel_ease_flutter/features/auth/data/models/register_payload.dart';
import 'package:fuel_ease_flutter/features/auth/data/repositories/auth_repository.dart';
import 'package:fuel_ease_flutter/features/auth/presentation/providers/auth_state.dart';
import 'package:fuel_ease_flutter/shared/models/user.dart';

/// StateNotifier for managing authentication state
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(
    this._authRepository,
    this._secureStorage,
  ) : super(const AuthState.initial()) {
    _init();
  }

  final AuthRepository _authRepository;
  final SecureStorage _secureStorage;
  final Logger _logger = Logger();

  /// Initialize auth state by checking for existing session
  Future<void> _init() async {
    state = const AuthState.loading();

    try {
      // Check if we have a valid token
      final hasValidToken = await _secureStorage.hasValidToken();

      if (hasValidToken) {
        // Try to get current user
        final user = await _authRepository.getCurrentUser();

        // Validate that user is a customer (mobile app is customer-only)
        if (user.isCustomer) {
          state = AuthState.authenticated(user);
          _logger.i('User authenticated: ${user.email}');
        } else {
          // User has wrong role for this app
          await logout();
          state = const AuthState.error(
            'This app is for customers only. Please use the web portal.',
          );
        }
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      _logger.e('Auth initialization failed', error: e);
      await _secureStorage.clearAuth();
      state = const AuthState.unauthenticated();
    }
  }

  /// Login with email and password
  Future<void> login(String email, String password) async {
    state = const AuthState.loading();

    try {
      final payload = LoginPayload(email: email, password: password);
      final response = await _authRepository.login(payload);

      // Validate user role
      if (!response.user.isCustomer) {
        state = const AuthState.error(
          'This app is for customers only. Please use the web portal.',
        );
        return;
      }

      // Save session data
      await _secureStorage.saveToken(response.token);
      await _secureStorage.saveUser(response.user.toJson());
      await _secureStorage.saveExpiresAt(response.expiresAt);

      state = AuthState.authenticated(response.user);
      _logger.i('Login successful: ${response.user.email}');
    } catch (e) {
      _logger.e('Login failed', error: e);
      state = AuthState.error(e.toString());
    }
  }

  /// Register new customer account
  Future<void> register(RegisterPayload payload) async {
    state = const AuthState.loading();

    try {
      final response = await _authRepository.register(payload);

      // Save session data
      await _secureStorage.saveToken(response.token);
      await _secureStorage.saveUser(response.user.toJson());
      await _secureStorage.saveExpiresAt(response.expiresAt);

      state = AuthState.authenticated(response.user);
      _logger.i('Registration successful: ${response.user.email}');
    } catch (e) {
      _logger.e('Registration failed', error: e);
      state = AuthState.error(e.toString());
    }
  }

  /// Logout current user
  Future<void> logout() async {
    await _secureStorage.clearAuth();
    state = const AuthState.unauthenticated();
    _logger.i('User logged out');
  }

  /// Update user profile
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final currentState = state;

    // Only update if currently authenticated
    if (currentState is! AuthAuthenticated) return;

    try {
      final updatedUser = await _authRepository.updateProfile(updates);

      // Update user in storage and state
      await _secureStorage.saveUser(updatedUser.toJson());
      state = AuthState.authenticated(updatedUser);
      _logger.i('Profile updated: ${updatedUser.email}');
    } catch (e) {
      _logger.e('Profile update failed', error: e);
      // Keep current state, just log the error
    }
  }

  /// Update push notification token
  Future<void> updatePushToken(String token, String platform) async {
    try {
      await _authRepository.updatePushToken(token, platform);
      _logger.i('Push token updated');
    } catch (e) {
      _logger.w('Push token update failed', error: e);
      // Don't fail - push token update is non-critical
    }
  }

  /// Clear error state
  void clearError() {
    if (state is AuthError) {
      state = const AuthState.unauthenticated();
    }
  }
}

/// Provider for AuthNotifier
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthNotifier(authRepository, secureStorage);
});

/// Convenience provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.maybeWhen(
    authenticated: (_) => true,
    orElse: () => false,
  );
});

/// Convenience provider to get current user
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.maybeWhen(
    authenticated: (user) => user,
    orElse: () => null,
  );
});
