import 'package:flutter/foundation.dart';

import '../../../../core/diagnostics/crashlytics_error_reporter.dart';
import '../../../../core/diagnostics/error_reporter.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../../auth/presentation/view_models/preferences_view_model.dart';
import '../../data/services/foreground_push_presenter.dart';
import '../../data/services/local_notifications_service.dart';
import '../../data/services/push_token_registrar.dart';

/// Mantiene las notificaciones push sincronizadas con la preferencia
/// "Notificaciones habilitadas" (`AppPreferences.notificationsEnabled`) y la
/// sesión: pide el permiso del sistema, registra el token del dispositivo
/// (ver `PushTokenRegistrar`) y muestra los push recibidos con la app abierta
/// (ver `ForegroundPushPresenter`).
///
/// En web no hay notificaciones locales: el permiso lo pide el navegador al
/// registrar el token.
///
/// No es un `ChangeNotifier`: a diferencia de `AppLockViewModel`, ninguna
/// pantalla necesita leer estado de acá — solo hay que reaccionar a los
/// cambios de `PreferencesViewModel` y de la sesión.
class NotificationsViewModel {
  final PreferencesViewModel _preferencesViewModel;
  final AuthViewModel _authViewModel;
  final PushTokenRegistrar _pushTokenRegistrar;
  final ForegroundPushPresenter _foregroundPushPresenter;
  final LocalNotificationsService _localNotificationsService;
  final bool _isWeb;
  final Future<ErrorReporter> Function() _reporter;

  NotificationsViewModel({
    required PreferencesViewModel preferencesViewModel,
    required AuthViewModel authViewModel,
    required PushTokenRegistrar pushTokenRegistrar,
    required ForegroundPushPresenter foregroundPushPresenter,
    LocalNotificationsService? localNotificationsService,
    Future<ErrorReporter> Function()? reporter,
    // Only tests change this; `kIsWeb` is a constant there.
    bool isWeb = kIsWeb,
  })  : _isWeb = isWeb,
        _preferencesViewModel = preferencesViewModel,
        _authViewModel = authViewModel,
        _pushTokenRegistrar = pushTokenRegistrar,
        _foregroundPushPresenter = foregroundPushPresenter,
        _reporter = reporter ?? CrashlyticsErrorReporter.create,
        _localNotificationsService =
            localNotificationsService ?? LocalNotificationsService() {
    _preferencesViewModel.addListener(_onChanged);
    _authViewModel.addListener(_onChanged);
  }

  /// The system permission is asked once each time notifications are turned
  /// on (not on every unrelated preference change).
  bool _permissionAsked = false;

  /// Whether the push token is (or is about to be) registered. Set before
  /// the call is queued, so repeated notifications never queue it twice.
  bool _pushActive = false;

  /// Push calls run one after another: switching notifications on and off in
  /// a row must not make `stopAndRemove` overlap a `start` still in flight.
  Future<void> _pushQueue = Future.value();

  /// Se llama una sola vez al arrancar la app (ver `app.dart`), después de
  /// crear este view model. Aplica el estado de la preferencia ya cargada (o
  /// su default, si `PreferencesViewModel` todavía no terminó de cargar —
  /// [_onChanged] corrige el valor apenas la carga real termine).
  Future<void> initialize() => _sync();

  void _onChanged() {
    _sync();
  }

  /// The system permission comes first, so the push token is registered
  /// after it. A later change that arrives while the permission dialog is
  /// still open does not wait for it. Push is queued even if the permission
  /// step fails.
  Future<void> _sync() async {
    try {
      await _ensureSystemPermission();
    } finally {
      _syncPush();
    }
  }

  Future<void> _ensureSystemPermission() async {
    if (_isWeb) return;
    if (!_preferencesViewModel.preferences.notificationsEnabled) {
      _permissionAsked = false;
      return;
    }
    if (_permissionAsked) return;
    _permissionAsked = true;

    try {
      // On Android 13+ this shows the system dialog; it is also what lets
      // push messages appear while the app is in the background.
      await _localNotificationsService.requestPermission();
    } catch (error, stackTrace) {
      try {
        final reporter = await _reporter();
        await reporter.recordError(
          error,
          stackTrace,
          reason: 'Notification permission',
        );
      } catch (_) {}
    }
  }

  /// Push is wanted when notifications are on and there is a session.
  void _syncPush() {
    final wanted = _preferencesViewModel.preferences.notificationsEnabled &&
        _authViewModel.isAuthenticated;
    if (wanted == _pushActive) return;
    _pushActive = wanted;

    if (wanted) {
      _enqueuePush(() async {
        await _pushTokenRegistrar.start();
        await _foregroundPushPresenter.start();
      });
    } else if (_authViewModel.isAuthenticated) {
      // The user switched notifications off: the row can still be deleted.
      _enqueuePush(() async {
        await _foregroundPushPresenter.stop();
        await _pushTokenRegistrar.stopAndRemove();
      });
    } else {
      // Session ended: without it the row cannot be deleted.
      _enqueuePush(() async {
        await _foregroundPushPresenter.stop();
        await _pushTokenRegistrar.release();
      });
    }
  }

  void _enqueuePush(Future<void> Function() action) {
    _pushQueue = _pushQueue.then((_) => action()).catchError((_) {});
  }

  void dispose() {
    _preferencesViewModel.removeListener(_onChanged);
    _authViewModel.removeListener(_onChanged);
    _pushTokenRegistrar.dispose();
    _foregroundPushPresenter.dispose();
  }
}
