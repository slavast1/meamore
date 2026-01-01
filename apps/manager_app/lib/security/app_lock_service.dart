import 'package:local_auth/local_auth.dart';
import 'app_lock_method.dart';

class AppLockService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isDeviceSupported() => _auth.isDeviceSupported();

  Future<bool> hasBiometrics() async {
    return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
  }

  Future<bool> authenticate({
    required AppLockMethod method,
    required String reason,
  }) async {
    if (method == AppLockMethod.none) return true;

    final bool biometricOnly;
    switch (method) {
      case AppLockMethod.biometrics:
        biometricOnly = true;
        break;
      case AppLockMethod.deviceCredential:
        biometricOnly = false; // allows device PIN/pattern/password
        break;
      case AppLockMethod.auto:
        biometricOnly = await hasBiometrics(); // prefer biometrics if possible
        break;
      case AppLockMethod.none:
        return true;
    }

    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: biometricOnly,
        sensitiveTransaction: true,
        // "stickyAuth" replacement in 3.0.0:
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
