import 'dart:ui' show Color;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Wrapper fino sobre `flutter_local_notifications`, mismo criterio que
/// `BiometricService` (feature `home`): aísla el plugin para que el
/// resto de la app no dependa de su API directamente.
///
/// Solo se usa para mostrar los push que llegan con la app abierta (Android
/// no los muestra solo) y para pedir el permiso de notificaciones. [initialize]
/// es idempotente y se llama sola antes de cada uso.
class LocalNotificationsService {
  final FlutterLocalNotificationsPlugin _plugin;

  LocalNotificationsService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _invoicesChannelId = 'invoices_due';
  static const _invoicesChannelName = 'Vencimientos de facturas';
  static const _invoicesChannelDescription =
      'Avisa cuando una factura vence hoy, falta cargarla o una cuenta lleva '
      'días sin actualizarse';

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
  /// un no-op que no necesita pedirse). Se llama cuando el usuario activa la
  /// preferencia. También es lo que permite ver los push con la app en
  /// segundo plano.
  Future<bool> requestPermission() async {
    await initialize();
    final granted = await _androidPlugin?.requestNotificationsPermission();
    return granted ?? true;
  }

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  /// Shows a push message received while the app is open, with the same
  /// channel and look as the other notices. [id] must be stable per notice so
  /// a repeated delivery replaces the previous one instead of stacking.
  Future<void> showPush({
    required int id,
    required String title,
    required String body,
  }) async {
    await initialize();

    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _invoicesChannelId,
          _invoicesChannelName,
          channelDescription: _invoicesChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          color: _brandColor,
        ),
      ),
    );
  }
}
