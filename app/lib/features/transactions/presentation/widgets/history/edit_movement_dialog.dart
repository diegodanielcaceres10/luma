import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/app_clock.dart';
import '../../../../../core/utils/currency_format.dart';
import '../../../../../core/utils/date_format.dart';
import '../../../../../core/widgets/input_text_field.dart';
import '../../../../../core/widgets/text_action_button.dart';
import '../../../../categories/data/models/category.dart';
import '../../../../categories/presentation/view_models/category_view_model.dart';
import '../../../data/models/transaction_entry.dart';

class EditMovementResult {
  final String? categoryId;
  final String? description;
  final DateTime date;

  const EditMovementResult({
    required this.categoryId,
    required this.description,
    required this.date,
  });
}

/// Edit dialog: only category, description and date are editable. Account
/// and amount are read-only because they affect `accounts.balance`.
/// Transfers have no category selector.
class EditMovementDialog extends StatefulWidget {
  final TransactionEntry movement;
  final CategoryViewModel categoryViewModel;
  final String currency;

  const EditMovementDialog({
    super.key,
    required this.movement,
    required this.categoryViewModel,
    required this.currency,
  });

  @override
  State<EditMovementDialog> createState() => _EditMovementDialogState();
}

class _EditMovementDialogState extends State<EditMovementDialog> {
  late final TextEditingController _descriptionController;
  late DateTime _selectedDate;
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.movement.description ?? '',
    );
    _selectedDate = widget.movement.date;
    _selectedCategory =
        widget.categoryViewModel.categoryById(widget.movement.category.id);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: nowLocal(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.authAccent,
            onPrimary: AppColors.authBackgroundBottom,
            surface: AppColors.authBackgroundBottom,
            onSurface: AppColors.authTextPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _confirm() {
    Navigator.of(context).pop(
      EditMovementResult(
        categoryId: _selectedCategory?.id,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        date: _selectedDate,
      ),
    );
  }

  static const _labelStyle = TextStyle(color: AppColors.authTextSecondary);

  @override
  Widget build(BuildContext context) {
    final movement = widget.movement;
    final categories = movement.isTransfer
        ? const <Category>[]
        : widget.categoryViewModel.byType(movement.type);
    final sign = movement.isIncome ? '+' : '-';

    return AlertDialog(
      backgroundColor: AppColors.authBackgroundTop,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.authCardBorder),
      ),
      title: const Text(
        'Editar movimiento',
        style: TextStyle(
          color: AppColors.authTextPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${movement.account.name} · '
              '$sign${formatCurrency(movement.amount, widget.currency)}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.authTextPrimary,
              ),
            ),
            const SizedBox(height: 20),
            if (!movement.isTransfer) ...[
              const Text('Categoría', style: _labelStyle),
              const SizedBox(height: 8),
              if (categories.isEmpty)
                const Text(
                  'No hay categorías de este tipo. Se guardará sin '
                  'categoría.',
                  style: TextStyle(color: AppColors.authTextSecondary),
                )
              else
                DropdownButtonFormField<Category>(
                  initialValue: _selectedCategory,
                  dropdownColor: AppColors.authBackgroundBottom,
                  style: const TextStyle(color: AppColors.authTextPrimary),
                  decoration: InputTextField.formDecoration,
                  hint: const Text(
                    'Sin categoría',
                    style: TextStyle(color: AppColors.authTextSecondary),
                  ),
                  items: [
                    const DropdownMenuItem<Category>(
                      value: null,
                      child: Text(
                        'Sin categoría',
                        style: TextStyle(color: AppColors.authTextSecondary),
                      ),
                    ),
                    ...categories.map(
                      (c) => DropdownMenuItem<Category>(
                        value: c,
                        child: Text(c.name),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value),
                ),
              const SizedBox(height: 20),
            ],
            InputTextField(
              controller: _descriptionController,
              label: 'Descripción',
              hintText: 'Opcional',
            ),
            const SizedBox(height: 20),
            const Text('Fecha', style: _labelStyle),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: InputTextField.formDecoration,
                child: Text(
                  formatDate(_selectedDate),
                  style: const TextStyle(color: AppColors.authTextPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextActionButton(
          label: 'Cancelar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextActionButton(
          label: 'Guardar',
          color: AppColors.authAccent,
          fontWeight: FontWeight.w700,
          onPressed: _confirm,
        ),
      ],
    );
  }
}
