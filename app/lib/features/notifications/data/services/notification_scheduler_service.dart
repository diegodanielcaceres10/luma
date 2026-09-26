import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

import '../../../../core/config/app_env.dart';
import '../../../invoices/data/repositories/invoice_repository.dart';
import '../../../invoices/data/services/invoice_service.dart';
import '../../../preferences/data/repositories/preferences_repository.dart';
import '../../../services/data/repositories/service_repository.dart';
import '../../../services/data/services/service_service.dart';
import 'local_notifications_service.dart';

/// Nombre único de la tarea periódica ante Workmanager/WorkManager
/// (Android). Al registrar dos veces la misma tarea con
/// `ExistingPeriodicWorkPolicy.keep`, la segunda llamada es un no-op — así
/// evitamos reiniciar el conteo de 24hs en cada arranque de la app.
const String kDailyInvoiceCheckTaskUniqueName =
    'luma.notifications.daily_invoice_due_check';

const String _dailyInvoiceCheckTaskName = 'dailyInvoiceDueCheck';

bool get _isAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Registra/cancela ante WorkManager la rutina diaria que revisa si hay
/// facturas que vencen hoy y, de haberlas, dispara una notificación local.
///
/// Solo tiene efecto en Android: es la única plataforma pedida para esta
/// feature, y además es la única con soporte real en el plugin
/// `workmanager` (iOS lo tiene parcial vía BGTaskScheduler, sin garantía
/// de periodicidad diaria; desktop/web no tienen background tasks). En
/// cualquier otra plataforma, todos los métodos de esta clase son no-ops.
class NotificationSchedulerService {
  NotificationSchedulerService._();

  /// Hay que llamarlo una sola vez apenas arranca la app (ver
  /// `NotificationsViewModel.initialize`), antes de [enable]/[disable].
  /// Registra [callbackDispatcher] como punto de entrada que el lado
  /// nativo de Android va a invocar en un isolate de background separado
  /// del de la UI — por eso ese callback no puede depender de nada que
  /// viva en memoria de este isolate (ver su propio comentario).
  static Future<void> initialize() async {
    if (!_isAndroid) return;
    await Workmanager().initialize(callbackDispatcher);
  }

  /// Agenda la tarea para correr aproximadamente cada 24hs. Android decide
  /// el momento exacto dentro de esa ventana (Doze/optimización de
  /// batería) — no hay garantía de que corra siempre a la misma hora, pero
  /// sí de que corre una vez por día mientras la app siga instalada y la
  /// preferencia activada.
  static Future<void> enable() async {
    if (!_isAndroid) return;
    await Workmanager().registerPeriodicTask(
      kDailyInvoiceCheckTaskUniqueName,
      _dailyInvoiceCheckTaskName,
      frequency: const Duration(hours: 24),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  /// Desagenda la tarea. Se llama cuando el usuario apaga "Notificaciones
  /// habilitadas" en Preferencias.
  static Future<void> disable() async {
    if (!_isAndroid) return;
    await Workmanager().cancelByUniqueName(kDailyInvoiceCheckTaskUniqueName);
  }
}

/// Punto de entrada que WorkManager invoca, en Android, en un isolate de
/// background nuevo — no es el mismo isolate de `main()`/`LumaApp`, así
/// que no hay `Supabase.instance` ni ningún view model ya armado para
/// reusar: todo lo que la tarea necesita se arma desde cero acá adentro.
///
/// Tiene que ser una función top-level (no un método de clase) y llevar
/// este `@pragma` para que el compilador no la elimine en modo release
/// (tree shaking) — Workmanager la busca por nombre desde el lado nativo.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == _dailyInvoiceCheckTaskName) {
      // Cualquier error (sin sesión guardada, sin conexión, Supabase caído,
      // etc.) no debería hacer que WorkManager reintente en loop: total, la
      // próxima corrida periódica vuelve a evaluar todo en 24hs.
      try {
        await _checkInvoicesDueToday();
      } catch (_) {
        // Silenciado a propósito, ver comentario de arriba.
      }
    }
    return Future.value(true);
  });
}

Future<void> _checkInvoicesDueToday() async {
  if (AppEnv.supabaseUrl.isEmpty || AppEnv.supabasePublishableKey.isEmpty) {
    return;
  }

  // Cada corrida es un isolate nuevo: no hay sesión de Supabase en memoria
  // para reusar, hay que restaurarla desde el storage local del
  // dispositivo — mismo mecanismo que usa la sesión de la UI al abrir la
  // app normalmente.
  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    publishableKey: AppEnv.supabasePublishableKey,
  );

  final client = Supabase.instance.client;
  // Sin sesión (nunca se logueó en este dispositivo, o cerró sesión) no
  // hay nada para chequear.
  if (client.auth.currentSession == null) return;

  final invoiceRepository = InvoiceRepository(InvoiceService(client));
  final dueToday = await invoiceRepository.getDueToday();
  if (dueToday.isEmpty) return;

  final serviceRepository = ServiceRepository(ServiceService(client));
  final services = await serviceRepository.getAll();
  final servicesById = {for (final service in services) service.id: service};

  final preferences = await PreferencesRepository().load();
  final notifications = LocalNotificationsService();

  for (final invoice in dueToday) {
    final serviceName = servicesById[invoice.serviceId]?.name ?? 'Servicio';
    await notifications.showInvoiceDueToday(
      // & 0x7fffffff: el id de notificación de Android es un int de 32
      // bits con signo; el hash de un String puede superar ese rango.
      id: invoice.id.hashCode & 0x7fffffff,
      serviceName: serviceName,
      amount: invoice.amount,
      currencyCode: preferences.currencyCode,
    );
  }
}
