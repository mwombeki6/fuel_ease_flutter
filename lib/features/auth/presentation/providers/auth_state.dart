import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:fuel_ease_flutter/shared/models/user.dart';

part 'auth_state.freezed.dart';

/// Authentication state using sealed classes for type-safe state handling
@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.authenticated(User user) = AuthAuthenticated;
  const factory AuthState.unauthenticated() = AuthUnauthenticated;
  const factory AuthState.error(String message) = AuthError;
}
