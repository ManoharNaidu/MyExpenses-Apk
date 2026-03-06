import 'package:local_auth/local_auth.dart';

import '../auth/auth_provider.dart';
import 'pin_utils.dart';

class AppLockService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  static Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      return canCheck && supported;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticateWithBiometric() async {
    try {
      final canCheck = await canCheckBiometrics();
      if (!canCheck) return false;

      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock My Expenses',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  static bool verifyPin({
    required String enteredPin,
    required String? storedHash,
  }) {
    if (storedHash == null || storedHash.trim().isEmpty) return false;
    return hashPin(enteredPin) == storedHash;
  }

  static Future<void> updateSettings(
    AuthProvider auth, {
    required bool enabled,
    required bool useBiometric,
    required String? pin,
  }) async {
    final pinHash = (pin != null && pin.trim().isNotEmpty)
        ? hashPin(pin)
        : auth.state.appLockPinHash;
    await auth.updateAppLockSettings(
      enabled: enabled,
      useBiometric: useBiometric,
      pinHash: enabled ? pinHash : null,
    );
  }
}
