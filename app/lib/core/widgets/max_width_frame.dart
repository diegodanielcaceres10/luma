import 'package:flutter/material.dart';

/// Widest the app content grows on large screens (web, PWA, tablets).
const double kAppMaxContentWidth = 720;

/// Widest a dialog grows on large screens; narrower than the content so it
/// reads as a modal on top of it.
const double kDialogMaxWidth = 560;

/// Centers [child] and caps its width at [maxWidth]; on narrower viewports it
/// is a no-op. The space left on the sides is painted with [sideDecoration].
class MaxWidthFrame extends StatelessWidget {
  final double maxWidth;
  final Decoration? sideDecoration;
  final Widget child;

  const MaxWidthFrame({
    super.key,
    this.maxWidth = kAppMaxContentWidth,
    this.sideDecoration,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: sideDecoration ?? const BoxDecoration(),
      child: Align(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
