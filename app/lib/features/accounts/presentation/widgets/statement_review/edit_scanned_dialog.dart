import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/input_text_field.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../core/widgets/text_action_button.dart';

/// Lets the user fix the description of a line read from a statement. Amount,
/// date and category come from the statement and are not editable. Pops the
/// trimmed text (empty when cleared) or null when cancelled.
class EditScannedDialog extends StatefulWidget {
  final String? description;

  const EditScannedDialog({super.key, required this.description});

  @override
  State<EditScannedDialog> createState() => _EditScannedDialogState();
}

class _EditScannedDialogState extends State<EditScannedDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.description ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.authBackgroundTop,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.authCardBorder),
      ),
      title: const Text(
        'Corregir descripción',
        style: TextStyle(
          color: AppColors.authTextPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SingleChildScrollView(
        child: InputTextField(
          controller: _controller,
          label: 'Descripción',
          compact: true,
        ),
      ),
      actions: [
        TextActionButton(
          label: 'Cancelar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        PrimaryButton(
          label: 'Listo',
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
        ),
      ],
    );
  }
}
