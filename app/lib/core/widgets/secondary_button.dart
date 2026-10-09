import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Secondary action next to a [PrimaryButton]: outlined, with the app's card
/// border. The defaults give the plain look; the optional parameters cover the
/// variations the app already uses ([padding], [borderRadius], [labelStyle]
/// and [foregroundColor]).
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final TextStyle? labelStyle;
  final Color foregroundColor;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.labelStyle,
    this.foregroundColor = AppColors.authTextPrimary,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: foregroundColor,
        side: const BorderSide(color: AppColors.authCardBorder),
        padding: padding,
        shape: radius == null
            ? null
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
      ),
      onPressed: onPressed,
      child: Text(label, style: labelStyle),
    );
  }
}
