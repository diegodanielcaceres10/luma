import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../buttons/text_action_button.dart';

/// Asks the user to confirm before continuing, e.g. before saving a record.
///
/// Resolves to `true` only when "Sí" is pressed. Pressing "No" or tapping
/// outside the dialog resolves to `false`, so nothing is saved by accident.
Future<bool> showConfirmDialog(
  BuildContext context, {
  String title = '¿Estás seguro?',
  String message = '¿Seguro que querés continuar?',
  String confirmLabel = 'Sí',
  String cancelLabel = 'No',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.authBackgroundBottom,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.authCardBorder),
      ),
      icon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.authAccent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.authAccent.withValues(alpha: 0.25),
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.help_outline_rounded,
            color: AppColors.authAccent,
            size: 24,
          ),
        ),
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.authTextPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.authTextSecondary,
          fontSize: 14,
        ),
      ),
      actions: [
        TextActionButton(
          label: cancelLabel,
          onPressed: () => Navigator.of(dialogContext).pop(false),
        ),
        TextActionButton(
          label: confirmLabel,
          color: AppColors.authAccent,
          fontWeight: FontWeight.w700,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
