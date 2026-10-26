import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/currency_format.dart';
import '../../../../../core/widgets/inputs/input_text_field.dart';
import '../../../../../core/widgets/buttons/text_action_button.dart';
import '../../../../categories/data/models/category.dart';
import '../../../../categories/presentation/view_models/category_view_model.dart';
import '../../../data/models/transaction_entry.dart';

class EditMovementResult {
  final String? categoryId;
  final String? description;

  const EditMovementResult({
    required this.categoryId,
    required this.description,
  });
}

/// Edit dialog. Account, amount and date are never editable: the first two
/// affect `accounts.balance`.
///
/// A regular movement allows editing its category and description.
/// Transfers and service payments only allow editing the description, since
/// their category is managed by the action that created them.
class EditMovementDialog extends StatefulWidget {
  final TransactionEntry movement;
  final CategoryViewModel categoryViewModel;

  /// Whether the movement is the payment of a paid invoice.
  final bool isServicePayment;
  final String currency;

  const EditMovementDialog({
    super.key,
    required this.movement,
    required this.categoryViewModel,
    required this.isServicePayment,
    required this.currency,
  });

  @override
  State<EditMovementDialog> createState() => _EditMovementDialogState();
}

class _EditMovementDialogState extends State<EditMovementDialog> {
  late final TextEditingController _descriptionController;
  Category? _selectedCategory;

  TransactionEntry get _movement => widget.movement;

  bool get _isLocked => _movement.isTransfer || widget.isServicePayment;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: _movement.description ?? '',
    );
    _selectedCategory =
        widget.categoryViewModel.categoryById(_movement.category.id);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _confirm() {
    final text = _descriptionController.text.trim();
    Navigator.of(context).pop(
      EditMovementResult(
        // Locked movements keep their category as is.
        categoryId: _isLocked ? _movement.category.id : _selectedCategory?.id,
        description: text.isEmpty ? null : text,
      ),
    );
  }

  static const _labelStyle = TextStyle(color: AppColors.authTextSecondary);

  @override
  Widget build(BuildContext context) {
    final sign = _movement.isIncome ? '+' : '-';

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
              '${_movement.account.name} · '
              '$sign${formatCurrency(_movement.amount, widget.currency)}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.authTextPrimary,
              ),
            ),
            const SizedBox(height: 20),
            if (_isLocked) ...[
              Text(
                _movement.isTransfer
                    ? 'Transferencia. Solo se puede editar la descripción.'
                    : 'Pago de servicio. Solo se puede editar la descripción.',
                style: const TextStyle(
                  color: AppColors.authTextSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
            ] else
              ..._buildCategoryField(),
            InputTextField(
              controller: _descriptionController,
              label: 'Descripción',
              hintText: 'Opcional',
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

  List<Widget> _buildCategoryField() {
    final categories = widget.categoryViewModel.byType(_movement.type);
    return [
      const Text('Categoría', style: _labelStyle),
      const SizedBox(height: 8),
      if (categories.isEmpty)
        const Text(
          'No hay categorías de este tipo. Se guardará sin categoría.',
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
              (c) => DropdownMenuItem<Category>(value: c, child: Text(c.name)),
            ),
          ],
          onChanged: (value) => setState(() => _selectedCategory = value),
        ),
      const SizedBox(height: 20),
    ];
  }
}
