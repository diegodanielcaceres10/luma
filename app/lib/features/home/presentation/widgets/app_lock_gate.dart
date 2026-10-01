import 'package:flutter/material.dart';

/// Shows the lock layer on top of the app while [isLocked] returns `true`.
///
/// The layer is not a route: the content below is only hidden, so the
/// navigation stack, forms in progress and scroll positions are exactly as
/// the user left them once the app is unlocked. It is meant to wrap the
/// router in `MaterialApp.router`'s `builder`, so it also covers dialogs and
/// bottom sheets opened on the root navigator.
class AppLockGate extends StatelessWidget {
  /// Rebuilds the gate when it notifies; [isLocked] is read on each rebuild.
  final Listenable listenable;
  final bool Function() isLocked;
  final WidgetBuilder lockBuilder;
  final Widget child;

  const AppLockGate({
    super.key,
    required this.listenable,
    required this.isLocked,
    required this.lockBuilder,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) {
        final locked = isLocked();

        // `Offstage` keeps the state but skips painting, hit testing and
        // semantics; `ExcludeFocus` also closes the keyboard.
        return Stack(
          fit: StackFit.expand,
          children: [
            ExcludeFocus(
              excluding: locked,
              child: Offstage(offstage: locked, child: child),
            ),
            if (locked) lockBuilder(context),
          ],
        );
      },
    );
  }
}
