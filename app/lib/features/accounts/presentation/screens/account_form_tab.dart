import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/account.dart';
import '../view_models/account_view_model.dart'
    show AccountSubmitError, AccountViewModel;

/// Contenido de la pestaña "Nueva cuenta" / "Editar cuenta". No tiene
/// Scaffold propio — se muestra dentro de un RoutedScreenScaffold, debajo
/// del header y encima del bottomNavigationBar que pone AppShellScreen.
///
/// Si [account] viene nulo, es un alta nueva (con saldo inicial editable).
/// Si viene con valor, es edición — el saldo no se toca desde acá, se
/// mantiene a través de los movimientos.
class AccountFormTab extends StatefulWidget {
  final String userId;
  final AccountViewModel accountViewModel;
  final Account? account;

  /// Se llama tras guardar con éxito, o al cancelar, para volver a "Cuentas".
  final VoidCallback onDone;

  const AccountFormTab({
    super.key,
    required this.userId,
    required this.accountViewModel,
    required this.onDone,
    this.account,
  });

  @override
  State<AccountFormTab> createState() => _AccountFormTabState();
}

class _AccountFormTabState extends State<AccountFormTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();

  bool get _isEditing => widget.account != null;

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
  );

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _nameController.text = account?.name ?? '';
    _balanceController.text =
        account != null ? account.balance.toStringAsFixed(2) : '';
    // Re-build whenever isSubmitting or errorMessage changes.
    widget.accountViewModel.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.accountViewModel.removeListener(_onViewModelChanged);
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = widget.accountViewModel;
    final success = _isEditing
        ? await vm.updateAccount(
            id: widget.account!.id,
            name: _nameController.text.trim(),
          )
        : await vm.createAccount(
            userId: widget.userId,
            name: _nameController.text.trim(),
            balance: double.parse(_balanceController.text.trim()),
          );

    if (!mounted) return;

    if (success) {
      widget.onDone();
    } else {
      final isDuplicate = vm.submitError == AccountSubmitError.duplicate;
      if (isDuplicate) {
        // Highlight the name field so the user knows what to change.
        _formKey.currentState!.validate();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isDuplicate
                ? 'Ya existe una cuenta con ese nombre.'
                : 'Ocurrió un error al guardar. Intentá de nuevo.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = widget.accountViewModel.isSubmitting;

    return SafeArea(
      top: false,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Thin progress bar across the top while saving.
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
                  Row(
                    children: [
                      InkWell(
                        onTap: isSubmitting ? null : widget.onDone,
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.arrow_back_rounded,
                              color: AppColors.authTextPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isEditing ? 'Editar cuenta' : 'Nueva cuenta',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.authTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Nombre',
                      style: TextStyle(color: AppColors.authTextSecondary)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    enabled: !isSubmitting,
                    style: const TextStyle(color: AppColors.authTextPrimary),
                    decoration: _fieldDecoration.copyWith(
                      hintText: 'Ej: Cuenta corriente',
                      hintStyle:
                          const TextStyle(color: AppColors.authTextFooter),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Ingresa un nombre'
                        : null,
                  ),
                  if (!_isEditing) ...[
                    const SizedBox(height: 20),
                    const Text('Saldo inicial',
                        style: TextStyle(color: AppColors.authTextSecondary)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _balanceController,
                      enabled: !isSubmitting,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.authTextPrimary),
                      decoration: _fieldDecoration.copyWith(hintText: '0.00'),
                      validator: (value) {
                        final parsed = double.tryParse((value ?? '').trim());
                        return parsed == null
                            ? 'Ingresa un monto válido'
                            : null;
                      },
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.authAccent,
                        foregroundColor: AppColors.authBackgroundBottom,
                        disabledBackgroundColor:
                            AppColors.authAccent.withValues(alpha: 0.6),
                        disabledForegroundColor: AppColors.authBackgroundBottom
                            .withValues(alpha: 0.6),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: isSubmitting ? null : _submit,
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.authBackgroundBottom,
                              ),
                            )
                          : Text(
                              _isEditing ? 'Guardar cambios' : 'Crear cuenta'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
