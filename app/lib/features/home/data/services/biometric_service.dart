import 'package:local_auth/local_auth.dart';

/// Thin wrapper over `local_auth`. Isolates the plugin here so the rest of
/// the app (view model, screen) doesn't depend on its API directly — same
/// reason the other features have a `service` layer separate from the
/// external client (Supabase, in that case).
class BiometricService {
  final LocalAuthentication _auth;

  BiometricService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  /// `true` if the device can authenticate (with biometrics or with some
  /// other OS lock method: PIN/pattern/password). `local_auth` has no
  /// support on Web or Linux — there this returns `false` without throwing.
  Future<bool> isSupported() async {
    try {
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheckBiometrics || isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Prompts the user to authenticate (biometrics, or the device PIN/pattern
  /// as a fallback — `biometricOnly: false`). Returns `true` only if
  /// authentication succeeded; any cancellation, failure or technical error
  /// (missing hardware, etc.) returns `false`.
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Confirmá tu identidad para abrir Luma',
        biometricOnly: false,
      );
    } catch (_) {
      return false;
    }
  }
}
