import 'package:flutter/foundation.dart';

import '../../../../core/diagnostics/crashlytics_error_reporter.dart';
import '../../../auth/presentation/view_models/preferences_view_model.dart';
import '../../data/repositories/notification_log_repository.dart';
import '../../data/services/local_notifications_service.dart';
import '../../data/services/notification_health_monitor.dart';
import '../../data/services/notification_scheduler_service.dart';

/// Mantiene la tarea diaria de "facturas que vencen hoy" (Android, ver
/// `NotificationSchedulerService`) sincronizada con la preferencia
/// "Notificaciones habilitadas" (`AppPreferences.notificationsEnabled`).
///
/// No es un `ChangeNotifier`: a diferencia de `AppLockViewModel`, ninguna
/// pantalla necesita leer estado de acá — solo hay que reaccionar a los
/// cambios de `PreferencesViewModel` y, en consecuencia, registrar o
/// cancelar la tarea ante WorkManager.
class NotificationsViewModel {
  final PreferencesViewModel _preferencesViewModel;
  final LocalNotificationsService _localNotificationsService;
  late final NotificationHealthMonitor _healthMonitor;

  NotificationsViewModel({
    required PreferencesViewModel preferencesViewModel,
    LocalNotificationsService? localNotificationsService,
    NotificationHealthMonitor? healthMonitor,
  })  : _preferencesViewModel = preferencesViewModel,
        _localNotificationsService =
            localNotificationsService ?? LocalNotificationsService() {
    _healthMonitor = healthMonitor ??
        NotificationHealthMonitor(
          log: NotificationLogRepository(),
          notificationsAllowed:
              _localNotificationsService.areNotificationsEnabled,
          reporter: CrashlyticsErrorReporter.create,
        );
    _preferencesViewModel.addListener(_onPreferencesChanged);
  }

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Último valor de `notificationsEnabled` ya aplicado a WorkManager.
  /// Evita registrar/cancelar la tarea de nuevo cada vez que cambia
  /// cualquier otra preferencia (moneda, tema, etc.) — `PreferencesViewModel`
  /// notifica a todos sus listeners por cualquier cambio, no solo el de
  /// notificaciones.
  bool? _lastSyncedEnabled;

  /// Se llama una sola vez al arrancar la app (ver `app.dart`), después de
  /// crear este view model. Registra Workmanager y aplica el estado de la
  /// preferencia ya cargada (o su default, si `PreferencesViewModel`
  /// todavía no terminó de cargar — [_onPreferencesChanged] corrige el
  /// valor apenas la carga real termine).
  Future<void> initialize() async {
    await NotificationSchedulerService.initialize();
    await _sync();
  }

  void _onPreferencesChanged() {
    _sync();
  }

  Future<void> _sync() async {
    final enabled = _preferencesViewModel.preferences.notificationsEnabled;
    if (enabled == _lastSyncedEnabled) return;
    final wasEnabled = _lastSyncedEnabled == true;
    _lastSyncedEnabled = enabled;

    if (enabled) {
      // Se pide acá (y no antes) porque es el momento en que la
      // preferencia pasa a estar activa — en Android 13+ esto dispara el
      // diálogo del sistema para `POST_NOTIFICATIONS`.
      await _localNotificationsService.requestPermission();
      await NotificationSchedulerService.enable();
      // Detects what the background task cannot report by itself: blocked
      // permission or no run for too long. Result goes to the log.
      if (_isAndroid) await _healthMonitor.check();
    } else {
      await NotificationSchedulerService.disable();
      // Only a real switch-off restarts the stale clock; the first sync runs
      // with the default (off) before the saved preferences are loaded.
      if (wasEnabled) await _healthMonitor.reset();
    }
  }

  void dispose() {
    _preferencesViewModel.removeListener(_onPreferencesChanged);
  }
}
