// Biometric Authentication Service
// Handles Touch ID/Face ID authentication for enhanced security

import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if biometric authentication is available on the device
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException catch (e) {
      print('Biometric availability check failed: ${e.message}');
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      print('Failed to get available biometrics: ${e.message}');
      return [];
    }
  }

  /// Authenticate using biometrics
  Future<bool> authenticate({String? localizedReason}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason ?? 'Authenticate to access your account',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      print('Biometric authentication failed: ${e.message}');
      return false;
    }
  }

  /// Check if device supports strong biometrics (Face ID/Touch ID)
  Future<bool> hasStrongBiometrics() async {
    final availableBiometrics = await getAvailableBiometrics();
    return availableBiometrics.contains(BiometricType.face) ||
        availableBiometrics.contains(BiometricType.fingerprint);
  }
}