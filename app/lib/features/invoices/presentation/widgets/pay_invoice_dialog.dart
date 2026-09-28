import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../accounts/data/models/account.dart';
import '../../../categories/data/models/category.dart';
import '../../data/models/invoice.dart';

class PayInvoiceResult {
  final double amount;
  final String accountId;
  final DateTime date;

  const PayInvoiceResult({
    required this.amount,
    required this.accountId,
    required this.date,
  });
}

/// Payment dialog for an invoice. The amount is prefilled with the invoice
/// amount but editable, since the real amount may differ. The category is
/// fixed (it comes from the service) so the expense is always classified
/// correctly.
class PayInvoiceDialog extends StatefulWidget {
  final Invoice invoice;
  final String serviceName;
  final Category category;
  final List<Account> accounts;
  final String currency;

  const PayInvoiceDialog({
    super.key,
    required this.invoice,
    required this.serviceName,
    required this.category,
    required this.accounts,
    required this.currency,
  });

  @override
  State<PayInvoiceDialog> createState() => _PayInvoiceDialogState();
}

class _PayInvoiceDialogState extends State<PayInvoiceDialog> {
  late final TextEditingController _amountController;
  Account? _selectedAccount;
  String? _amountError;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.invoice.amount.toStringAsFixed(2),
    );
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _confirm() {
    final amount =
        double.tryParse(_amountController.text.trim().replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      setState(() => _amountError = 'Ingresá un monto válido');
      return;
    }
    if (_selectedAccount == null) return;

    Navigator.of(context).pop(
      PayInvoiceResult(
        amount: amount,
        accountId: _selectedAccount!.id,
        date: _selectedDate,
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
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

  static const _fieldDecoration = InputDecoration(
    filled: true,
    fillColor: AppColors.authCardFill,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: AppColors.authCardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: AppColors.authCardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: AppColors.authAccent),
    ),
    hintStyle: TextStyle(color: AppColors.authTextFooter),
  );

  @override
  Widget build(BuildContext context) {
    final accounts = widget.accounts;

    return AlertDialog(
      backgroundColor: AppColors.authBackgroundTop,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.authCardBorder),
      ),
      title: const Text(
        'Registrar pago',
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
              '${widget.serviceName} · ${widget.category.name}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.authTextPrimary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Monto a pagar',
              style: TextStyle(color: AppColors.authTextSecondary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.authTextPrimary),
              decoration: _fieldDecoration.copyWith(
                prefixText: '€ ',
                prefixStyle: const TextStyle(color: AppColors.authTextPrimary),
                errorText: _amountError,
                errorStyle: const TextStyle(color: AppColors.authExpense),
              ),
              onChanged: (_) {
                if (_amountError != null) {
                  setState(() => _amountError = null);
                }
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Cuenta con la que se paga',
              style: TextStyle(color: AppColors.authTextSecondary),
            ),
            const SizedBox(height: 8),
            if (accounts.isEmpty)
              const Text(
                'No hay cuentas activas — creá una antes de registrar el '
                'pago.',
                style: TextStyle(color: AppColors.authExpense),
              )
            else
              DropdownButtonFormField<Account>(
                initialValue: _selectedAccount,
                dropdownColor: AppColors.authBackgroundBottom,
                style: const TextStyle(color: AppColors.authTextPrimary),
                decoration: _fieldDecoration,
                hint: const Text(
                  'Seleccioná una cuenta',
                  style: TextStyle(color: AppColors.authTextSecondary),
                ),
                items: accounts
                    .map((a) => DropdownMenuItem(
                          value: a,
                          child: Text(
                            '${a.name} - ${formatCurrency(a.balance, widget.currency)}',
                          ),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedAccount = value),
              ),
            const SizedBox(height: 20),
            const Text(
              'Fecha de pago',
              style: TextStyle(color: AppColors.authTextSecondary),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: _fieldDecoration.copyWith(
                  suffixIcon: const Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: AppColors.authTextSecondary,
                  ),
                ),
                child: Text(
                  '${_selectedDate.day.toString().padLeft(2, '0')}/'
                  '${_selectedDate.month.toString().padLeft(2, '0')}/'
                  '${_selectedDate.year}',
                  style: const TextStyle(color: AppColors.authTextPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Volver',
            style: TextStyle(color: AppColors.authTextSecondary),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.authAccent,
            foregroundColor: AppColors.authBackgroundBottom,
            disabledBackgroundColor:
                AppColors.authAccent.withValues(alpha: 0.6),
            disabledForegroundColor:
                AppColors.authBackgroundBottom.withValues(alpha: 0.6),
          ),
          onPressed: accounts.isEmpty ? null : _confirm,
          child: const Text('Confirmar pago'),
        ),
      ],
    );
  }
}
