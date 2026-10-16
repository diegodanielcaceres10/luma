import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/app_clock.dart';
import '../../../../../core/utils/date_format.dart';
import '../../../../../core/widgets/input_text_field.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../core/widgets/text_action_button.dart';
import '../../../../categories/data/models/category.dart';
import '../../../../invoices/data/models/invoice.dart';
import 'movement_dialog_style.dart';
import 'pending_movement.dart';

class AddInvoiceDialog extends StatefulWidget {
  final Invoice invoice;
  final String serviceName;
  final Category category;
  final void Function(PendingMovement movement) onSave;

  final DateTimeRange? dateRange;

  /// Movement being edited; its amount and date prefill the form instead of
  /// the invoice's own amount, so a statement line keeps what was really
  /// paid and when.
  final PendingMovement? initial;

  const AddInvoiceDialog({
    super.key,
    required this.invoice,
    required this.serviceName,
    required this.category,
    required this.onSave,
    this.dateRange,
    this.initial,
  });

  @override
  State<AddInvoiceDialog> createState() => _AddInvoiceDialogState();
}

class _AddInvoiceDialogState extends State<AddInvoiceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late DateTime _selectedDate =
      initialMovementDialogDate(widget.initial?.date, widget.dateRange);

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: (widget.initial?.amount.abs() ?? widget.invoice.amount)
          .toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
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

    final amount = double.parse(
      _amountController.text.trim().replaceAll(',', '.'),
    );

    widget.onSave(
      InvoicePendingMovement(
        amount: -amount,
        date: _selectedDate,
        invoice: widget.invoice,
        category: widget.category,
        serviceName: widget.serviceName,
        description: 'Factura · ${widget.serviceName}',
      ),
    );
    Navigator.of(context).pop();
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
        'Pagar factura',
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
              Text(
                '${widget.serviceName} · ${widget.category.name}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.authTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              InputTextField(
                controller: _amountController,
                label: 'Monto a pagar',
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
                  if (parsed == null || parsed <= 0) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Fecha de pago',
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
                        style: const TextStyle(
                          color: AppColors.authTextPrimary,
                        ),
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
