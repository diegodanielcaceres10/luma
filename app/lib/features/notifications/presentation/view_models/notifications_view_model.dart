import '../../../preferences/presentation/view_models/preferences_view_model.dart';
import '../../data/services/local_notifications_service.dart';
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

  NotificationsViewModel({
    required PreferencesViewModel preferencesViewModel,
    LocalNotificationsService? localNotificationsService,
  })  : _preferencesViewModel = preferencesViewModel,
        _localNotificationsService =
            localNotificationsService ?? LocalNotificationsService() {
    _preferencesViewModel.addListener(_onPreferencesChanged);
  }

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
    _lastSyncedEnabled = enabled;

    if (enabled) {
      // Se pide acá (y no antes) porque es el momento en que la
      // preferencia pasa a estar activa — en Android 13+ esto dispara el
      // diálogo del sistema para `POST_NOTIFICATIONS`.
      await _localNotificationsService.requestPermission();
      await NotificationSchedulerService.enable();
    } else {
      await NotificationSchedulerService.disable();
    }
  }

  void dispose() {
    _preferencesViewModel.removeListener(_onPreferencesChanged);
  }
}
