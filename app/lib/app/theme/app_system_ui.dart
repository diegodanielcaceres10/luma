import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Estilo del status bar para toda la app.
///
/// Todas las pantallas (login, el shell principal con dashboard/
/// movimientos/estadísticas/perfil, las pantallas apiladas de
/// `RoutedScreenScaffold`, el 404 y [UpdateRequiredScreen]) usan el mismo
/// gradiente oscuro de marca detrás del status bar, así que un solo
/// estilo (íconos claros) alcanza para toda la app — no hay ninguna
/// pantalla con fondo claro ahí que necesite lo contrario.
const appStatusBarStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light, // Android
  statusBarBrightness: Brightness.dark, // iOS
);
