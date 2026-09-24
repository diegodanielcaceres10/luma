import 'package:local_auth/local_auth.dart';

/// Wrapper fino sobre `local_auth`. Aísla el plugin acá para que el resto
/// de la app (view model, pantalla) no dependa de su API directamente —
/// mismo motivo por el que el resto de los features tiene una capa
/// `service` separada del cliente externo (Supabase, en ese caso).
class BiometricService {
  final LocalAuthentication _auth;

  BiometricService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  /// `true` si el dispositivo puede autenticar (con biometría o con algún
  /// otro método de bloqueo del SO: PIN/patrón/contraseña). `local_auth`
  /// no tiene soporte en Web ni Linux — ahí esto devuelve `false` sin
  /// tirar excepción.
  Future<bool> isSupported() async {
    try {
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheckBiometrics || isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Pide autenticación al usuario (biometría o PIN/patrón del
  /// dispositivo como fallback — `biometricOnly: false`). Devuelve `true`
  /// solo si se autenticó correctamente; cualquier cancelación, fallo o
  /// error técnico (falta de hardware, etc.) devuelve `false`.
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
