import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'browser_history_stub.dart'
    if (dart.library.js_interop) 'browser_history_web.dart';

/// App-wide "back" (form arrows, save-when-done, etc.), behaving exactly
/// like the browser/device back button:
///
/// - Web: `history.back()`. A plain `context.pop()` removes the screen but
///   ADDS a browser history entry, so the next back returned to the screen
///   just closed.
/// - Android / iOS / desktop: plain `pop()`, like the system back button.
/// - With no in-app history (e.g. opened directly by URL): goes to the
///   Dashboard.
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
