import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

/// Text-only action used in dialogs and sheets ("Cancelar", "Volver", "Sí").
/// It is muted by default; pass [color] and [fontWeight] to emphasize the
/// main action of a dialog. [disabledAlpha] fades the label while the button
/// is disabled; without it the label keeps its color.
class TextActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final FontWeight? fontWeight;
  final double? disabledAlpha;

  const TextActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.authTextSecondary,
    this.fontWeight,
    this.disabledAlpha,
  });

  @override
  Widget build(BuildContext context) {
    final alpha = disabledAlpha;
    final isFaded = onPressed == null && alpha != null;

    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: isFaded ? color.withValues(alpha: alpha) : color,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}
