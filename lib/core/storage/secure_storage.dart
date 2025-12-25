import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for sensitive data like tokens and user credentials
class SecureStorage {
  SecureStorage(this._storage);

  final FlutterSecureStorage _storage;

  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _expiresAtKey = 'token_expires_at';
  static const String _refreshTokenKey = 'refresh_token';

  /// Save authentication token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Get authentication token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Save user data as JSON
  Future<void> saveUser(Map<String, dynamic> userData) async {
    await _storage.write(key: _userKey, value: jsonEncode(userData));
  }

  /// Get user data as JSON
  Future<Map<String, dynamic>?> getUser() async {
    final userJson = await _storage.read(key: _userKey);
    if (userJson == null) return null;
    return jsonDecode(userJson) as Map<String, dynamic>;
  }

  /// Save token expiry timestamp
  Future<void> saveExpiresAt(int expiresAt) async {
    await _storage.write(key: _expiresAtKey, value: expiresAt.toString());
  }

  /// Get token expiry timestamp
  Future<int?> getExpiresAt() async {
    final expiresAtStr = await _storage.read(key: _expiresAtKey);
    if (expiresAtStr == null) return null;
    return int.tryParse(expiresAtStr);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Check if token is expired
  Future<bool> isTokenExpired() async {
    final expiresAt = await getExpiresAt();
    if (expiresAt == null) return true;

    final now = DateTime.now().millisecondsSinceEpoch;
    return now > expiresAt;
  }

  /// Check if token exists and is valid
  Future<bool> hasValidToken() async {
    final token = await getToken();
    if (token == null) return false;

    final expired = await isTokenExpired();
    return !expired;
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Clear only auth-related data
  Future<void> clearAuth() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _userKey),
      _storage.delete(key: _expiresAtKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }

  /// Save custom key-value pair
  Future<void> save(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Read custom key-value pair
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  /// Delete custom key
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Check if key exists
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }
}

/// Provider for SecureStorage
final secureStorageProvider = Provider<SecureStorage>((ref) {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  return SecureStorage(storage);
});
