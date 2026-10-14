import 'package:flutter/material.dart';

/// Widest the app content grows on large screens (web, PWA, tablets).
const double kAppMaxContentWidth = 480;

/// Centers [child] and caps its width at [maxWidth]; on narrower viewports it
/// is a no-op. The space left on the sides is filled with [sideColor].
class MaxWidthFrame extends StatelessWidget {
  final double maxWidth;
  final Color sideColor;
  final Widget child;

  const MaxWidthFrame({
    super.key,
    this.maxWidth = kAppMaxContentWidth,
    this.sideColor = Colors.transparent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: sideColor,
      child: Align(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
