import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Estilo del status bar para toda la app.
///
/// Todas las pantallas (login, el shell principal con dashboard/
/// movimientos/estadísticas/perfil, las pantallas apiladas de
/// `RoutedScreenScaffold`, `LockScreen` y el 404) usan el mismo gradiente
/// oscuro de marca detrás del status bar, así que un solo estilo (íconos
/// claros) alcanza para toda la app — no hay ninguna pantalla con fondo
/// claro ahí que necesite lo contrario.
///
/// Se aplica con `AnnotatedRegion<SystemUiOverlayStyle>` (en el `builder`
/// de `LumaApp` y en `UpdateRequiredScreen`, que corre en su propio
/// `MaterialApp` separado), NO con `SystemChrome.setSystemUIOverlayStyle`
/// suelto en `main()`: `MaterialApp` calcula su propio
/// `SystemUiOverlayStyle` a partir del `brightness` del theme y lo vuelve
/// a aplicar en cada frame, pisando cualquier valor fijado antes de que
/// se construya — un `AnnotatedRegion` anidado más adentro que el de
/// `MaterialApp` es lo único que gana (ver
/// https://github.com/flutter/flutter/issues/171344).
const appStatusBarStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light, // Android
  statusBarBrightness: Brightness.dark, // iOS
);
