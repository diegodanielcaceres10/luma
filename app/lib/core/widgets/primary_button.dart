import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Main call-to-action button of forms, dialogs and sheets, styled like the
/// auth-themed screens: accent background with dark text.
///
/// The defaults give the plain look. The optional parameters cover the
/// variations the app already uses:
/// - [isLoading] swaps the label for a spinner. It does not disable the button;
///   pass a null [onPressed] for that.
/// - [disabledAlpha] keeps the accent color, faded, while the button is
///   disabled (otherwise Material's default disabled look applies).
/// - [padding] and [borderRadius] override the theme's defaults.
/// - [icon] shows an icon before the label.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final TextStyle? labelStyle;
  final Color backgroundColor;
  final double? disabledAlpha;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.labelStyle,
    this.backgroundColor = AppColors.authAccent,
    this.disabledAlpha,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius;
    final alpha = disabledAlpha;

    final style = FilledButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: AppColors.authBackgroundBottom,
      disabledBackgroundColor:
          alpha == null ? null : backgroundColor.withValues(alpha: alpha),
      disabledForegroundColor: alpha == null
          ? null
          : AppColors.authBackgroundBottom.withValues(alpha: 0.6),
      padding: padding,
      shape: radius == null
          ? null
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    );

    final content = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.authBackgroundBottom,
            ),
          )
        : Text(label, style: labelStyle);

    final icon = this.icon;
    if (icon != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        style: style,
        icon: Icon(icon),
        label: content,
      );
    }

    return FilledButton(onPressed: onPressed, style: style, child: content);
  }
}
