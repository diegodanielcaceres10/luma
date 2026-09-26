import 'dart:ui' show Color;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../../core/utils/currency_format.dart';

/// Wrapper fino sobre `flutter_local_notifications`, mismo criterio que
/// `BiometricService` (feature `app_lock`): aísla el plugin para que el
/// resto de la app no dependa de su API directamente.
///
/// A diferencia de `BiometricService`, esta clase se instancia tanto desde
/// el isolate principal de la UI como desde el isolate de background que
/// dispara Workmanager (ver `NotificationSchedulerService`) — cada isolate
/// tiene su propia copia del plugin, no hay estado compartido entre ellos,
/// por eso [initialize] es idempotente y se llama sola antes de mostrar
/// cualquier notificación.
class LocalNotificationsService {
  final FlutterLocalNotificationsPlugin _plugin;

  LocalNotificationsService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _invoicesChannelId = 'invoices_due';
  static const _invoicesChannelName = 'Vencimientos de facturas';
  static const _invoicesChannelDescription =
      'Avisa cuando una factura vence hoy';

  /// Mismo verde que la hoja del logo (`authAccentDark` en
  /// `AppColors`) — tiñe el círculo detrás del ícono chico en la barra de
  /// estado y en la bandeja de notificaciones.
  static const _brandColor = Color(0xFF1F7A4C);

  bool _initialized = false;

  /// Inicializa el plugin y crea (o actualiza) el canal de notificaciones
  /// en Android. Se puede llamar más de una vez sin problema: si ya se
  /// inicializó en esta instancia, no vuelve a hacer nada.
  ///
  /// El ícono chico usa `@drawable/ic_notification` (silueta blanca de la
  /// hoja del logo, generada a partir de
  /// `android/app/src/main/res/mipmap-*/ic_launcher_foreground.png`) en vez
  /// de `@mipmap/ic_launcher`: Android ignora el color de un ícono de
  /// notificación y solo usa su canal alfa, así que un ícono con fondo
  /// opaco (como `ic_launcher.png`) termina viéndose como un círculo
  /// blanco sin forma.
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings),
    );

    await _androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _invoicesChannelId,
        _invoicesChannelName,
        description: _invoicesChannelDescription,
        importance: Importance.high,
      ),
    );

    _initialized = true;
  }

  /// Pide el permiso de notificaciones (obligatorio en runtime desde
  /// Android 13/API 33 — `POST_NOTIFICATIONS`; en versiones anteriores es
  /// un no-op que no necesita pedirse). Se llama desde el isolate
  /// principal cuando el usuario activa la preferencia — nunca desde la
  /// tarea de background, ahí ya es tarde para pedir permisos.
  Future<bool> requestPermission() async {
    await initialize();
    final granted = await _androidPlugin?.requestNotificationsPermission();
    return granted ?? true;
  }

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  /// Notificación de "esta factura vence hoy". [id] tiene que ser estable
  /// para una misma factura (se usa el hash del uuid) para no duplicar el
  /// aviso si la rutina llegara a correr más de una vez el mismo día.
  Future<void> showInvoiceDueToday({
    required int id,
    required String serviceName,
    required double amount,
    required String currencyCode,
  }) async {
    await initialize();

    final formattedAmount = formatCurrency(amount, currencyCode);
    await _plugin.show(
      id,
      'Vence hoy: $serviceName',
      'La factura de $serviceName vence hoy ($formattedAmount).',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _invoicesChannelId,
          _invoicesChannelName,
          channelDescription: _invoicesChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          color: _brandColor,
          // Ícono grande = el logo completo (a color), a la derecha del
          // texto. El chico (arriba) es la silueta simple para la barra
          // de estado — son recursos Android distintos a propósito.
          largeIcon: DrawableResourceAndroidBitmap('ic_launcher'),
        ),
      ),
    );
  }
}
