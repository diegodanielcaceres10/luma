import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Secondary action next to a [PrimaryButton]: outlined, with the app's card
/// border. The defaults give the plain look; the optional parameters cover the
/// variations the app already uses ([padding], [borderRadius], [labelStyle]
/// and [foregroundColor]). [disabledAlpha] fades text and border while the
/// button is disabled; without it Material's disabled look applies.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final TextStyle? labelStyle;
  final Color foregroundColor;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final double? disabledAlpha;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.labelStyle,
    this.foregroundColor = AppColors.authTextPrimary,
    this.padding,
    this.borderRadius,
    this.disabledAlpha,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius;
    final alpha = disabledAlpha;

    var style = OutlinedButton.styleFrom(
      foregroundColor: foregroundColor,
      disabledForegroundColor:
          alpha == null ? null : foregroundColor.withValues(alpha: alpha),
      side: const BorderSide(color: AppColors.authCardBorder),
      padding: padding,
      shape: radius == null
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
    );
    if (alpha != null) {
      style = style.copyWith(
        side: WidgetStateProperty.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.disabled)
                ? AppColors.authCardBorder.withValues(alpha: alpha)
                : AppColors.authCardBorder,
          ),
        ),
      );
    }

    return OutlinedButton(
      style: style,
      onPressed: onPressed,
      child: Text(label, style: labelStyle),
    );
  }
}
