// Secure Storage Service
// Handles secure storage of sensitive data like tokens and biometric preferences

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Keys for stored data
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _lastLoginEmailKey = 'last_login_email';
  static const String _biometricAuthDataKey = 'biometric_auth_data';

  /// Store access token securely
  static Future<void> setAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  /// Retrieve access token
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Store refresh token securely
  static Future<void> setRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  /// Retrieve refresh token
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Set biometric authentication preference
  static Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  /// Check if biometric authentication is enabled
  static Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  /// Store last login email for biometric auth
  static Future<void> setLastLoginEmail(String email) async {
    await _storage.write(key: _lastLoginEmailKey, value: email);
  }

  /// Retrieve last login email
  static Future<String?> getLastLoginEmail() async {
    return await _storage.read(key: _lastLoginEmailKey);
  }

  /// Store biometric authentication data (encrypted)
  static Future<void> setBiometricAuthData(String data) async {
    await _storage.write(key: _biometricAuthDataKey, value: data);
  }

  /// Retrieve biometric authentication data
  static Future<String?> getBiometricAuthData() async {
    return await _storage.read(key: _biometricAuthDataKey);
  }

  /// Clear all secure storage (logout)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Clear specific key
  static Future<void> clearKey(String key) async {
    await _storage.delete(key: key);
  }
}