import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'browser_history_stub.dart'
    if (dart.library.js_interop) 'browser_history_web.dart';

/// "Volver" de la app (flechita del título de los formularios, "guardar"
/// al terminar, etc.). Se comporta exactamente igual que el botón "atrás"
/// del navegador o del dispositivo:
///
/// - Web: dispara `history.back()`. Un `context.pop()` común saca la
///   pantalla de la pila pero AGREGA una entrada nueva al historial del
///   navegador (la URL de la pantalla a la que se vuelve), así que el
///   "atrás" siguiente volvía a la pantalla que acababas de cerrar.
///   Con `history.back()` el historial retrocede de verdad.
/// - Android / iOS / escritorio: `pop()` común, que es lo que ya hace el
///   botón "atrás" del sistema.
/// - Si no hay historial dentro de la app (ej. se entró directo por URL,
///   así que no hay ninguna pantalla debajo): manda al Dashboard.
extension AppBackNavigation on BuildContext {
  void goBack() {
    final router = GoRouter.of(this);
    if (!router.canPop()) {
      router.go('/');
      return;
    }
    if (browserHistoryBack()) return;
    router.pop();
  }
}
