import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/app_clock.dart';
import '../../../../../core/utils/date_format.dart';
import '../../../../../core/widgets/input_text_field.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../core/widgets/text_action_button.dart';
import '../../../../categories/data/models/category.dart';
import '../../../../categories/presentation/view_models/category_view_model.dart';
import 'movement_dialog_style.dart';
import 'pending_movement.dart';

class AddMovementDialog extends StatefulWidget {
  final CategoryViewModel categoryViewModel;

  final String categoryType;

  final void Function(PendingMovement movement) onSave;

  final DateTimeRange? dateRange;

  /// Movement being edited; its amount, date, description and category
  /// (when it fits [categoryType]) prefill the form.
  final PendingMovement? initial;

  const AddMovementDialog({
    super.key,
    required this.categoryViewModel,
    required this.categoryType,
    required this.onSave,
    this.dateRange,
    this.initial,
  });

  @override
  State<AddMovementDialog> createState() => _AddMovementDialogState();
}

class _AddMovementDialogState extends State<AddMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  Category? _selectedCategory;
  late DateTime _selectedDate =
      initialMovementDialogDate(widget.initial?.date, widget.dateRange);

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial == null) return;

    _amountController.text = initial.amount.abs().toStringAsFixed(2);
    _descriptionController.text = initial.description ?? '';

    final previous = switch (initial) {
      CategoryPendingMovement(:final category) => category,
      InvoicePendingMovement(:final category) => category,
      _ => null,
    };
    // Look it up again so the dropdown gets the instance it lists, and only
    // keep it when it fits the (possibly changed) type.
    final match = previous == null
        ? null
        : widget.categoryViewModel.categoryById(previous.id);
    if (match != null && match.type == widget.categoryType) {
      _selectedCategory = match;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: widget.dateRange?.start ?? DateTime(2020),
      lastDate: widget.dateRange?.end ?? nowLocal(),
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
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final rawAmount = double.parse(_amountController.text.replaceAll(',', '.'));
    final signedAmount =
        widget.categoryType == 'expense' ? -rawAmount : rawAmount;

    widget.onSave(
      CategoryPendingMovement(
        amount: signedAmount,
        type: widget.categoryType,
        category: _selectedCategory,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        date: _selectedDate,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.categoryViewModel.categories
        .where((c) => c.type == widget.categoryType)
        .toList();
    final categoryTypeLabel =
        widget.categoryType == 'income' ? 'ingreso' : 'gasto';

    return AlertDialog(
      backgroundColor: AppColors.authBackgroundTop,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.authCardBorder),
      ),
      title: Text(
        widget.initial == null ? 'Agregar movimiento' : 'Editar movimiento',
        style: const TextStyle(
          color: AppColors.authTextPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InputTextField(
                controller: _amountController,
                label: 'Monto',
                hintText: '0,00',
                compact: true,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*[.,]?\d{0,2}'),
                  ),
                ],
                validator: (value) {
                  final text = (value ?? '').trim().replaceAll(',', '.');
                  if (text.isEmpty) return 'Ingresa un monto';
                  final parsed = double.tryParse(text);
                  if (parsed == null || parsed <= 0) {
                    return 'Monto inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Categoría (opcional)',
                style: kMovementDialogLabelStyle,
              ),
              const SizedBox(height: 6),
              if (widget.categoryViewModel.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.authAccent,
                    ),
                  ),
                )
              else if (categories.isEmpty)
                Text(
                  'No hay categorías de $categoryTypeLabel todavía. '
                  'El movimiento se guardará sin categoría.',
                  style: const TextStyle(
                    color: AppColors.authTextSecondary,
                    fontSize: 13,
                  ),
                )
              else
                DropdownButtonFormField<Category?>(
                  initialValue: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: AppColors.authBackgroundBottom,
                  style: const TextStyle(color: AppColors.authTextPrimary),
                  decoration: kMovementDialogFieldDecoration,
                  items: [
                    const DropdownMenuItem<Category?>(
                      value: null,
                      child: Text('Sin categoría'),
                    ),
                    ...categories.map(
                      (c) => DropdownMenuItem<Category?>(
                        value: c,
                        child: Text(c.name, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value),
                ),
              const SizedBox(height: 16),
              InputTextField(
                controller: _descriptionController,
                label: 'Descripción (opcional)',
                hintText: 'Ej: Retiro en efectivo',
                compact: true,
              ),
              const SizedBox(height: 16),
              const Text(
                'Fecha',
                style: kMovementDialogLabelStyle,
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: kMovementDialogFieldDecoration,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatDate(_selectedDate),
                        style:
                            const TextStyle(color: AppColors.authTextPrimary),
                      ),
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: AppColors.authTextSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextActionButton(
          label: 'Cancelar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        PrimaryButton(
          label: 'Agregar',
          onPressed: _save,
        ),
      ],
    );
  }
}
