import 'dart:js_interop';
import 'dart:js_interop_unsafe';

bool browserHistoryBack() {
  final history = globalContext.getProperty<JSObject?>('history'.toJS);
  if (history == null) return false;
  history.callMethod<JSAny?>('back'.toJS);
  return true;
}
