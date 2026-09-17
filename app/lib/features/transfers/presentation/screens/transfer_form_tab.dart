import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/view_models/account_view_model.dart';
import '../../../transactions/presentation/view_models/transaction_view_model.dart';

/// Contenido de la pestaña "Transferencia entre cuentas". No tiene
/// Scaffold propio — vive dentro del Scaffold del HomeShell, que es quien
/// pone el header y el bottomNavigationBar.
///
/// Al guardar, se crean dos transacciones tipo 'transfer' (sin
/// categoría): una en la cuenta de origen y otra en la de destino, ambas
/// con el mismo monto y fecha de hoy. La fecha no es editable a
/// propósito — no se pidió ese campo para esta entrega.
class TransferFormTab extends StatefulWidget {
  final String? userId;
  final AccountViewModel accountViewModel;
  final TransactionViewModel transactionViewModel;

  /// Se llama al volver atrás o al guardar con éxito.
  final VoidCallback onDone;

  const TransferFormTab({
    super.key,
    required this.userId,
    required this.accountViewModel,
    required this.transactionViewModel,
    required this.onDone,
  });

  @override
  State<TransferFormTab> createState() => _TransferFormTabState();
}

class _TransferFormTabState extends State<TransferFormTab> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  String? _originAccountId;
  String? _destinationAccountId;

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_originAccountId == null || _destinationAccountId == null) return;

    final amount = double.parse(_amountController.text.replaceAll(',', '.'));
    final accounts = widget.accountViewModel.activeAccounts;
    final originName =
        accounts.firstWhere((a) => a.id == _originAccountId).name;
    final destinationName =
        accounts.firstWhere((a) => a.id == _destinationAccountId).name;

    final success = await widget.transactionViewModel.createTransfer(
      userId: widget.userId ?? '',
      originAccountId: _originAccountId!,
      destinationAccountId: _destinationAccountId!,
      amount: amount,
      date: DateTime.now(),
      originDescription: 'Transferencia a $destinationName',
      destinationDescription: 'Transferencia desde $originName',
    );

    if (!mounted) return;

    if (success) {
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListenableBuilder(
        listenable:
            Listenable.merge([widget.accountViewModel, widget.transactionViewModel]),
        builder: (context, _) {
          final accounts = widget.accountViewModel.activeAccounts;
          final isSubmitting = widget.transactionViewModel.isSubmitting;

          // Cada select excluye la cuenta ya elegida en el otro — así no
          // se puede transferir una cuenta a sí misma. Si la cuenta
          // elegida en un select deja de estar disponible en el otro
          // (porque la acaban de elegir ahí), se limpia para no dejar un
          // valor que ya no está entre las opciones.
          final originOptions = accounts
              .where((Account a) => a.id != _destinationAccountId)
              .toList();
          final destinationOptions = accounts
              .where((Account a) => a.id != _originAccountId)
              .toList();

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: widget.onDone,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.arrow_back_rounded,
                            color: AppColors.authTextPrimary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Transferencia entre cuentas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.authTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (accounts.length < 2)
                  const Text(
                    'Necesitás al menos dos cuentas activas para transferir '
                    'entre ellas.',
                    style: TextStyle(color: AppColors.authExpense),
                  )
                else ...[
                  const Text('Cuenta de origen',
                      style: TextStyle(color: AppColors.authTextSecondary)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: _originAccountId,
                    dropdownColor: AppColors.authBackgroundBottom,
                    style: const TextStyle(color: AppColors.authTextPrimary),
                    hint: const Text(
                      'Seleccioná la cuenta de origen',
                      style: TextStyle(color: AppColors.authTextSecondary),
                    ),
                    decoration: _fieldDecoration,
                    items: originOptions
                        .map(
                          (Account a) => DropdownMenuItem<String?>(
                            value: a.id,
                            child: Text(a.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() {
                      _originAccountId = value;
                      if (value != null && value == _destinationAccountId) {
                        _destinationAccountId = null;
                      }
                    }),
                  ),
                  const SizedBox(height: 20),
                  const Text('Cuenta de destino',
                      style: TextStyle(color: AppColors.authTextSecondary)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: _destinationAccountId,
                    dropdownColor: AppColors.authBackgroundBottom,
                    style: const TextStyle(color: AppColors.authTextPrimary),
                    hint: const Text(
                      'Seleccioná la cuenta de destino',
                      style: TextStyle(color: AppColors.authTextSecondary),
                    ),
                    decoration: _fieldDecoration,
                    items: destinationOptions
                        .map(
                          (Account a) => DropdownMenuItem<String?>(
                            value: a.id,
                            child: Text(a.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() {
                      _destinationAccountId = value;
                      if (value != null && value == _originAccountId) {
                        _originAccountId = null;
                      }
                    }),
                  ),
                  const SizedBox(height: 20),
                  const Text('Monto a transferir',
                      style: TextStyle(color: AppColors.authTextSecondary)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    style: const TextStyle(color: AppColors.authTextPrimary),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: _fieldDecoration.copyWith(hintText: '0.00'),
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
                              _originAccountId == null ||
                              _destinationAccountId == null
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
          );
        },
      ),
    );
  }
}
