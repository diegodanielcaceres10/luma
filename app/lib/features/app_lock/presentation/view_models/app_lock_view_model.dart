import 'package:flutter/foundation.dart';

import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../../preferences/presentation/view_models/preferences_view_model.dart';
import '../../data/services/biometric_service.dart';

/// Cuánto tiempo puede estar la app en segundo plano antes de que, al
/// volver, se le vuelva a pedir biometría. Decisión: 30 segundos — ver
/// conversación de diseño del feature.
const Duration kAppLockRelockThreshold = Duration(seconds: 30);

/// Intentos fallidos de autenticación permitidos antes de forzar el cierre
/// de sesión. Decisión: 5 — ver conversación de diseño del feature.
const int kAppLockMaxFailedAttempts = 5;

/// Decide cuándo la app debe mostrar la pantalla de bloqueo
/// ('/lock' — ver router.dart) y maneja el intento de desbloqueo.
///
/// No reemplaza a AuthViewModel: la sesión de Supabase (login) y el
/// bloqueo local (biometría) son gates independientes que se combinan en
/// el `redirect` del router. Ver conversación de diseño: este bloqueo
/// solo tiene sentido si el dispositivo lo soporta Y el usuario lo activó
/// en Preferencias — si cualquiera de las dos no se cumple, nunca se
/// activa `isLocked`, y el comportamiento es el de hoy (sin bloqueo
/// propio, solo el lock del sistema operativo).
class AppLockViewModel extends ChangeNotifier {
  final BiometricService _biometricService;
  final PreferencesViewModel _preferencesViewModel;
  final AuthViewModel _authViewModel;

  AppLockViewModel({
    required BiometricService biometricService,
    required PreferencesViewModel preferencesViewModel,
    required AuthViewModel authViewModel,
  })  : _biometricService = biometricService,
        _preferencesViewModel = preferencesViewModel,
        _authViewModel = authViewModel;

  bool _isSupported = false;
  bool _isLocked = false;
  bool _isAuthenticating = false;
  bool _deviceLostSupport = false;
  int _failedAttempts = 0;
  DateTime? _pausedAt;

  /// `true` si el dispositivo puede autenticar con biometría o con algún
  /// otro método de bloqueo del SO. Se calcula una sola vez en
  /// [initialize] (no cambia durante la vida de la app).
  bool get isSupported => _isSupported;

  bool get isLocked => _isLocked;
  bool get isAuthenticating => _isAuthenticating;
  int get failedAttempts => _failedAttempts;

  /// `true` si, al intentar desbloquear, se detectó que el dispositivo ya
  /// no tiene ningún PIN/patrón/contraseña ni biometría configurada (por
  /// ejemplo, el usuario los borró después de activar el bloqueo). En ese
  /// caso no tiene sentido seguir pidiendo biometría — ver [authenticate].
  bool get deviceLostSupport => _deviceLostSupport;

  bool get _lockPreferenceActive {
    return _isSupported && _preferencesViewModel.preferences.biometricLockEnabled;
  }

  /// Se llama una sola vez al arrancar la app (ver `app.dart`). Chequea
  /// capacidad del dispositivo y, si corresponde, arranca bloqueada
  /// (bloqueo "en frío").
  Future<void> initialize() async {
    _isSupported = await _biometricService.isSupported();
    if (_lockPreferenceActive) {
      _isLocked = true;
    }
    notifyListeners();
  }

  /// Vuelve a chequear si el dispositivo ya tiene biometría o algún
  /// bloqueo de pantalla (PIN/patrón/contraseña) configurado. El chequeo
  /// de [initialize] se hace una sola vez al arrancar y queda cacheado en
  /// [isSupported] — si el usuario configura el bloqueo de pantalla
  /// *mientras la app ya está abierta*, sin este refresh la preferencia
  /// seguiría deshabilitada hasta reiniciar la app. Se llama, por ejemplo,
  /// cada vez que se abre PreferencesScreen.
  Future<void> refreshSupport() async {
    _isSupported = await _biometricService.isSupported();
    notifyListeners();
  }

  /// Se llama desde `didChangeAppLifecycleState` cuando la app pasa a
  /// `paused` (segundo plano).
  void onAppPaused() {
    _pausedAt = DateTime.now();
  }

  /// Se llama desde `didChangeAppLifecycleState` cuando la app vuelve a
  /// `resumed`. Si pasó más de [kAppLockRelockThreshold] desde que se
  /// pausó, se vuelve a bloquear.
  void onAppResumed() {
    final pausedAt = _pausedAt;
    _pausedAt = null;

    if (!_lockPreferenceActive || pausedAt == null) return;

    final elapsed = DateTime.now().difference(pausedAt);
    if (elapsed >= kAppLockRelockThreshold) {
      _isLocked = true;
      notifyListeners();
    }
  }

  /// Dispara el prompt de biometría. Antes de pedirlo, re-chequea que el
  /// dispositivo siga teniendo algún método configurado (PIN/patrón/
  /// contraseña o biometría): si el usuario lo desconfiguró después de
  /// activar el bloqueo, no tiene sentido gastar un intento — directamente
  /// avisamos y desactivamos la preferencia para no volver a trabar la app
  /// la próxima vez (ver [deviceLostSupport] y PreferencesScreen).
  ///
  /// Si el dispositivo sí sigue soportado pero la huella/cara no coincide
  /// o el usuario cancela, cuenta como intento fallido. Al agotar
  /// [kAppLockMaxFailedAttempts], cierra la sesión — reintentar sin límite
  /// en la pantalla de bloqueo no es una opción razonable.
  Future<void> authenticate() async {
    if (_isAuthenticating) return;

    _isAuthenticating = true;
    notifyListeners();

    final stillSupported = await _biometricService.isSupported();
    if (!stillSupported) {
      _deviceLostSupport = true;
      _isAuthenticating = false;
      await _preferencesViewModel.setBiometricLockEnabled(false);
      notifyListeners();
      return;
    }

    final success = await _biometricService.authenticate();

    if (success) {
      _isLocked = false;
      _failedAttempts = 0;
      _isAuthenticating = false;
      notifyListeners();
      return;
    }

    _failedAttempts++;
    _isAuthenticating = false;

    if (_failedAttempts >= kAppLockMaxFailedAttempts) {
      _failedAttempts = 0;
      _isLocked = false;
      notifyListeners();
      await _authViewModel.signOut();
      return;
    }

    notifyListeners();
  }
}
