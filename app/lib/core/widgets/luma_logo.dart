import 'package:flutter/material.dart';

/// Leaf mark used as the Luma brand logo.
class LumaLogo extends StatelessWidget {
  final double size;

  const LumaLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
