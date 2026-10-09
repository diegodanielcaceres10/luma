import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Text-only action used in dialogs and sheets ("Cancelar", "Volver", "Sí").
/// It is muted by default; pass [color] and [fontWeight] to emphasize the
/// main action of a dialog.
class TextActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final FontWeight? fontWeight;

  const TextActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.authTextSecondary,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: fontWeight),
      ),
    );
  }
}
