import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/app_clock.dart';
import '../../../../../core/utils/date_format.dart';
import '../../../../../core/widgets/input_text_field.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../core/widgets/text_action_button.dart';
import '../../../data/models/account.dart';
import '../../view_models/account_view_model.dart';
import 'movement_dialog_style.dart';
import 'pending_movement.dart';

class AddTransferDialog extends StatefulWidget {
  final Account currentAccount;

  final AccountViewModel accountViewModel;

  final void Function(PendingMovement movement) onSave;

  final DateTimeRange? dateRange;

  /// Movement being edited; its amount, direction, date and description
  /// prefill the form.
  final PendingMovement? initial;

  const AddTransferDialog({
    super.key,
    required this.currentAccount,
    required this.accountViewModel,
    required this.onSave,
    this.dateRange,
    this.initial,
  });

  @override
  State<AddTransferDialog> createState() => _AddTransferDialogState();
}

class _AddTransferDialogState extends State<AddTransferDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _otherAccountId;

  bool _isIncoming = true;

  late DateTime _selectedDate =
      initialMovementDialogDate(widget.initial?.date, widget.dateRange);

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial == null) return;

    _amountController.text = initial.amount.abs().toStringAsFixed(2);
    _descriptionController.text = initial.description ?? '';
    _isIncoming = initial.amount > 0;

    if (initial is TransferPendingMovement) {
      final stillAvailable = widget.accountViewModel.activeAccounts.any(
        (a) =>
            a.id == initial.otherAccountId && a.id != widget.currentAccount.id,
      );
      if (stillAvailable) _otherAccountId = initial.otherAccountId;
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
    final otherAccountId = _otherAccountId;
    if (otherAccountId == null) return;

    final otherAccount = widget.accountViewModel.activeAccounts
        .firstWhere((a) => a.id == otherAccountId);

    final rawAmount = double.parse(_amountController.text.replaceAll(',', '.'));
    final signedAmount = _isIncoming ? rawAmount : -rawAmount;

    widget.onSave(
      TransferPendingMovement(
        amount: signedAmount,
        otherAccountId: otherAccount.id,
        otherAccountName: otherAccount.name,
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
    final otherAccounts = widget.accountViewModel.activeAccounts
        .where((a) => a.id != widget.currentAccount.id)
        .toList();

    return AlertDialog(
      backgroundColor: AppColors.authBackgroundTop,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.authCardBorder),
      ),
      title: Text(
        widget.initial == null
            ? 'Agregar transferencia'
            : 'Editar transferencia',
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
              if (otherAccounts.isEmpty)
                const Text(
                  'Necesitás al menos otra cuenta activa para cargar una '
                  'transferencia.',
                  style: TextStyle(color: AppColors.authExpense, fontSize: 13),
                )
              else ...[
                // When editing, the movement's sign already fixes the
                // direction, so it is not offered again.
                if (widget.initial == null) ...[
                  const Text(
                    'Dirección',
                    style: kMovementDialogLabelStyle,
                  ),
                  const SizedBox(height: 6),
                  SegmentedButton<bool>(
                    style: SegmentedButton.styleFrom(
                      backgroundColor: AppColors.authCardFill,
                      foregroundColor: AppColors.authTextSecondary,
                      selectedBackgroundColor: AppColors.authAccent,
                      selectedForegroundColor: AppColors.authBackgroundBottom,
                      side: const BorderSide(color: AppColors.authCardBorder),
                    ),
                    segments: const [
                      ButtonSegment(value: true, label: Text('Entra')),
                      ButtonSegment(value: false, label: Text('Sale')),
                    ],
                    selected: {_isIncoming},
                    onSelectionChanged: (selection) =>
                        setState(() => _isIncoming = selection.first),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  _isIncoming
                      ? 'Otra cuenta (de dónde sale)'
                      : 'Otra cuenta (a dónde va)',
                  style: kMovementDialogLabelStyle,
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _otherAccountId,
                  isExpanded: true,
                  dropdownColor: AppColors.authBackgroundBottom,
                  style: const TextStyle(color: AppColors.authTextPrimary),
                  decoration: kMovementDialogFieldDecoration,
                  hint: const Text(
                    'Seleccioná una cuenta',
                    style: TextStyle(color: AppColors.authTextSecondary),
                  ),
                  items: otherAccounts
                      .map(
                        (a) => DropdownMenuItem(
                          value: a.id,
                          child: Text(a.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _otherAccountId = value),
                  validator: (value) =>
                      value == null ? 'Seleccioná una cuenta' : null,
                ),
                const SizedBox(height: 16),
                InputTextField(
                  controller: _amountController,
                  label: 'Monto',
                  hintText: '0,00',
                  compact: true,
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
                InputTextField(
                  controller: _descriptionController,
                  label: 'Descripción (opcional)',
                  hintText: 'Ej: Traspaso entre cuentas propias',
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
          onPressed: otherAccounts.isEmpty ? null : _save,
        ),
      ],
    );
  }
}
