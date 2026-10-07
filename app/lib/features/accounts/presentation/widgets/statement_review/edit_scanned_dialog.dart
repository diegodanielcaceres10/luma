import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/date_format.dart';
import '../../../../../core/widgets/input_text_field.dart';
import '../../../../categories/data/models/category.dart';
import '../../../../categories/presentation/view_models/category_view_model.dart';
import '../../../data/models/scanned_movement.dart';
import '../pending_movements_section.dart';

class EditScannedResult {
  final ScannedMovement movement;
  final Category? category;

  const EditScannedResult(this.movement, this.category);
}

class EditScannedDialog extends StatefulWidget {
  final ScannedMovement movement;
  final Category? category;
  final CategoryViewModel categoryViewModel;
  final DateTimeRange range;

  const EditScannedDialog({
    super.key,
    required this.movement,
    required this.category,
    required this.categoryViewModel,
    required this.range,
  });

  @override
  State<EditScannedDialog> createState() => _EditScannedDialogState();
}

class _EditScannedDialogState extends State<EditScannedDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  late String _type = widget.movement.type;
  late DateTime _date = widget.movement.date ?? widget.range.end;
  late Category? _category = widget.category;

  @override
  void initState() {
    super.initState();
    // The sign of the amount is the only thing that defines the type.
    _amountController = TextEditingController(
      text: widget.movement.signedAmount.toStringAsFixed(2),
    )..addListener(_onAmountChanged);
    _descriptionController = TextEditingController(
      text: widget.movement.description ?? '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    final type = typeFromAmountText(_amountController.text);
    if (type == _type) return;

    setState(() {
      _type = type;
      // A category only fits the type it was created for.
      if (_category?.type != type) _category = null;
    });
  }

  Future<void> _pickDate() async {
    // Keep the current date selectable even if it falls outside the range,
    // so the picker never receives an initialDate outside [first, last].
    final first = widget.range.start;
    final last = widget.range.end;
    final initial = _date.isBefore(first)
        ? first
        : (_date.isAfter(last) ? last : _date);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
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
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final signed = parseSignedAmount(_amountController.text)!;
    final description = _descriptionController.text.trim();

    Navigator.of(context).pop(
      EditScannedResult(
        ScannedMovement(
          type: typeFromAmountText(_amountController.text),
          amount: signed.abs(),
          date: _date,
          description: description.isEmpty ? null : description,
        ),
        _category,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.categoryViewModel.categories
        .where((c) => c.type == _type)
        .toList();

    return AlertDialog(
      backgroundColor: AppColors.authBackgroundTop,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.authCardBorder),
      ),
      title: const Text(
        'Corregir movimiento',
        style: TextStyle(
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
              const Text('Monto', style: kMovementDialogLabelStyle),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^-?\d*[.,]?\d{0,2}'),
                  ),
                ],
                style: const TextStyle(color: AppColors.authTextPrimary),
                decoration: kMovementDialogFieldDecoration.copyWith(
                  hintText: '0,00',
                  helperText: 'Negativo es gasto, positivo es ingreso',
                  helperStyle: const TextStyle(
                    color: AppColors.authTextSecondary,
                    fontSize: 12,
                  ),
                ),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return 'Ingresa un monto';
                  final parsed = parseSignedAmount(text);
                  if (parsed == null || parsed == 0) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InputTextField(
                controller: _descriptionController,
                label: 'Descripción',
                compact: true,
              ),
              const SizedBox(height: 16),
              const Text('Fecha', style: kMovementDialogLabelStyle),
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
                        formatDate(_date),
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
              if (categories.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Categoría (opcional)',
                  style: kMovementDialogLabelStyle,
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<Category?>(
                  // initialValue is only read once; the key forces a rebuild
                  // when the type (and so the item list) changes.
                  key: ValueKey(_type),
                  initialValue: _category,
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
                  onChanged: (value) => setState(() => _category = value),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.authTextSecondary),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.authAccent,
            foregroundColor: AppColors.authBackgroundBottom,
          ),
          onPressed: _save,
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
