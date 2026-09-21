import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Versión para Web: hace exactamente lo mismo que el botón "atrás" del
/// navegador (`window.history.back()`). Devuelve `true` si lo ejecutó.
bool browserHistoryBack() {
  final history = globalContext.getProperty<JSObject?>('history'.toJS);
  if (history == null) return false;
  history.callMethod<JSAny?>('back'.toJS);
  return true;
}
