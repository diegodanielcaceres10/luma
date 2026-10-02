import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/view_models/account_view_model.dart';
import '../../../accounts/presentation/view_models/monthly_balance_view_model.dart';
import '../../../accounts/presentation/widgets/opening_balance_gate.dart';
import '../view_models/transaction_view_model.dart';

/// Form to register one side of a transfer between own accounts. Saving
/// creates a single row on the chosen account (an expense if money leaves it,
/// an income if money enters it); the other account is only mentioned in the
/// description, so its side must be registered manually (see
/// [TransactionViewModel.createTransfer]).
class TransactionFormTransferScreen extends StatefulWidget {
  final String? userId;
  final AccountViewModel accountViewModel;
  final TransactionViewModel transactionViewModel;
  final MonthlyBalanceViewModel monthlyBalanceViewModel;

  /// Called after saving or going back.
  final VoidCallback onDone;

  const TransactionFormTransferScreen({
    super.key,
    required this.userId,
    required this.accountViewModel,
    required this.transactionViewModel,
    required this.monthlyBalanceViewModel,
    required this.onDone,
  });

  @override
  State<TransactionFormTransferScreen> createState() =>
      _TransactionFormTransferScreenState();
}

class _TransactionFormTransferScreenState
    extends State<TransactionFormTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  String? _accountId;
  String? _otherAccountId;
  bool _isIncoming = false;
  DateTime _selectedDate = DateTime.now();

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
  void dispose() {
    _amountController.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_accountId == null || _otherAccountId == null) return;

    final confirmed = await showConfirmDialog(context);
    if (!confirmed || !mounted) return;

    final amount = double.parse(_amountController.text.replaceAll(',', '.'));
    final otherName = widget.accountViewModel.activeAccounts
        .firstWhere((a) => a.id == _otherAccountId)
        .name;

    final success = await widget.transactionViewModel.createTransfer(
      userId: widget.userId ?? '',
      accountId: _accountId!,
      type: _isIncoming ? 'income' : 'expense',
      amount: amount,
      date: _selectedDate,
      description: _isIncoming
          ? 'Transferencia desde $otherName'
          : 'Transferencia a $otherName',
    );

    if (!mounted) return;

    if (success) {
      // Balances changed server-side; reload accounts to show them.
      await widget.accountViewModel.loadAccounts();
      if (!mounted) return;
      widget.onDone();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.transactionViewModel.errorMessage ??
                'No se pudo guardar la transferencia.',
          ),
        ),
      );
    }
  }

  DropdownMenuItem<String?> _accountItem(Account a) {
    final isPending = widget.monthlyBalanceViewModel.isAccountPending(a.id);
    return DropdownMenuItem<String?>(
      value: a.id,
      enabled: !isPending,
      child: accountOptionLabel(
        '${a.name} - ${formatCurrency(a.balance, widget.accountViewModel.primaryCurrency)}',
        isPending: isPending,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListenableBuilder(
        listenable: Listenable.merge([
          widget.accountViewModel,
          widget.transactionViewModel,
          widget.monthlyBalanceViewModel,
        ]),
        builder: (context, _) {
          final accounts = widget.accountViewModel.activeAccounts;
          final isSubmitting = widget.transactionViewModel.isSubmitting;

          // Each dropdown excludes the account picked in the other one, and a
          // selection that is no longer available is cleared.
          final accountOptions = accounts
              .where((Account a) => a.id != _otherAccountId)
              .toList();
          final otherOptions =
              accounts.where((Account a) => a.id != _accountId).toList();

          return Form(
            key: _formKey,
            child: Column(
              children: [
                if (isSubmitting)
                  const LinearProgressIndicator(
                    backgroundColor: AppColors.authCardBorder,
                    color: AppColors.authAccent,
                    minHeight: 3,
                  ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      ScreenHeader(
                        title: 'Transferencia entre cuentas',
                        size: ScreenHeaderSize.compact,
                        onBack: widget.onDone,
                        backEnabled: !isSubmitting,
                      ),
                      const SizedBox(height: 20),
                      if (accounts.length < 2)
                        const Text(
                          'Necesitás al menos dos cuentas activas para '
                          'transferir entre ellas.',
                          style: TextStyle(color: AppColors.authExpense),
                        )
                      else ...[
                        const Text('Cuenta donde impacta',
                            style:
                                TextStyle(color: AppColors.authTextSecondary)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String?>(
                          initialValue: _accountId,
                          dropdownColor: AppColors.authBackgroundBottom,
                          style:
                              const TextStyle(color: AppColors.authTextPrimary),
                          hint: const Text(
                            'Seleccioná la cuenta',
                            style:
                                TextStyle(color: AppColors.authTextSecondary),
                          ),
                          decoration: _fieldDecoration,
                          items: accountOptions
                              .map(
                                (Account a) => _accountItem(a),
                              )
                              .toList(),
                          onChanged: isSubmitting
                              ? null
                              : (value) => setState(() {
                                    _accountId = value;
                                    if (value != null &&
                                        value == _otherAccountId) {
                                      _otherAccountId = null;
                                    }
                                  }),
                        ),
                        const SizedBox(height: 20),
                        const Text('Sentido',
                            style:
                                TextStyle(color: AppColors.authTextSecondary)),
                        const SizedBox(height: 8),
                        SegmentedButton<bool>(
                          style: SegmentedButton.styleFrom(
                            backgroundColor: AppColors.authCardFill,
                            foregroundColor: AppColors.authTextSecondary,
                            selectedBackgroundColor: AppColors.authAccent,
                            selectedForegroundColor:
                                AppColors.authBackgroundBottom,
                            side:
                                const BorderSide(color: AppColors.authCardBorder),
                          ),
                          segments: const [
                            ButtonSegment(value: false, label: Text('Sale')),
                            ButtonSegment(value: true, label: Text('Entra')),
                          ],
                          selected: {_isIncoming},
                          onSelectionChanged: isSubmitting
                              ? null
                              : (selection) =>
                                  setState(() => _isIncoming = selection.first),
                        ),
                        const SizedBox(height: 20),
                        Text(
                            _isIncoming
                                ? 'Otra cuenta (de dónde sale)'
                                : 'Otra cuenta (a dónde va)',
                            style: const TextStyle(
                                color: AppColors.authTextSecondary)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String?>(
                          initialValue: _otherAccountId,
                          isExpanded: true,
                          dropdownColor: AppColors.authBackgroundBottom,
                          style:
                              const TextStyle(color: AppColors.authTextPrimary),
                          hint: const Text(
                            'Seleccioná la otra cuenta',
                            style:
                                TextStyle(color: AppColors.authTextSecondary),
                          ),
                          decoration: _fieldDecoration,
                          items: otherOptions
                              .map(
                                (Account a) => DropdownMenuItem<String?>(
                                  value: a.id,
                                  child: Text(a.name,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              )
                              .toList(),
                          onChanged: isSubmitting
                              ? null
                              : (value) => setState(() {
                                    _otherAccountId = value;
                                    if (value != null && value == _accountId) {
                                      _accountId = null;
                                    }
                                  }),
                        ),
                        const SizedBox(height: 20),
                        const Text('Monto',
                            style:
                                TextStyle(color: AppColors.authTextSecondary)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _amountController,
                          enabled: !isSubmitting,
                          style:
                              const TextStyle(color: AppColors.authTextPrimary),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration:
                              _fieldDecoration.copyWith(hintText: '0.00'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresá un monto';
                            }
                            final parsed =
                                double.tryParse(value.replaceAll(',', '.'));
                            if (parsed == null || parsed <= 0) {
                              return 'Monto inválido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        const Text('Fecha',
                            style:
                                TextStyle(color: AppColors.authTextSecondary)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: isSubmitting ? null : _pickDate,
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
                              style: const TextStyle(
                                  color: AppColors.authTextPrimary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.authAccent,
                              foregroundColor: AppColors.authBackgroundBottom,
                              disabledBackgroundColor:
                                  AppColors.authAccent.withValues(alpha: 0.3),
                              disabledForegroundColor: AppColors
                                  .authBackgroundBottom
                                  .withValues(alpha: 0.6),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: isSubmitting ||
                                    _accountId == null ||
                                    _otherAccountId == null
                                ? null
                                : _submit,
                            child: isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.authBackgroundBottom,
                                    ),
                                  )
                                : const Text('Transferir'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
