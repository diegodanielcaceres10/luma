import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'text_action_button.dart';

/// Asks the user to confirm before continuing, e.g. before saving a record.
///
/// Resolves to `true` only when "Sí" is pressed. Pressing "No" or tapping
/// outside the dialog resolves to `false`, so nothing is saved by accident.
Future<bool> showConfirmDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.authBackgroundTop,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.authCardBorder),
      ),
      title: const Text(
        '¿Estás seguro?',
        style: TextStyle(
          color: AppColors.authTextPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: const Text(
        '¿Seguro que querés continuar?',
        style: TextStyle(color: AppColors.authTextSecondary),
      ),
      actions: [
        TextActionButton(
          label: 'No',
          onPressed: () => Navigator.of(dialogContext).pop(false),
        ),
        TextActionButton(
          label: 'Sí',
          color: AppColors.authAccent,
          fontWeight: FontWeight.w700,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
