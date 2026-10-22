import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/input_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../data/models/account.dart';
import '../view_models/account_view_model.dart'
    show AccountSubmitError, AccountViewModel;

class AccountFormScreen extends StatefulWidget {
  final String userId;
  final AccountViewModel accountViewModel;
  final Account? account;

  final VoidCallback onDone;

  const AccountFormScreen({
    super.key,
    required this.userId,
    required this.accountViewModel,
    required this.onDone,
    this.account,
  });

  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();

  bool get _isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _nameController.text = account?.name ?? '';
    _balanceController.text =
        account != null ? account.balance.toStringAsFixed(2) : '';
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

    final confirmed = await showConfirmDialog(context);
    if (!confirmed || !mounted) return;

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
        _formKey.currentState!.validate();
      }
      final message = isDuplicate
          ? 'Ya existe una cuenta con ese nombre.'
          : 'Ocurrió un error al guardar. Intentá de nuevo.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1E2922),
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(
              color: AppColors.authCardBorder,
              width: 1,
            ),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.authTextPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
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
            if (isSubmitting)
              const LinearProgressIndicator(
                backgroundColor: AppColors.authCardBorder,
                color: AppColors.authAccent,
                minHeight: 3,
              ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      ScreenHeader(
                        title: _isEditing ? 'Editar cuenta' : 'Nueva cuenta',
                        subtitle: _isEditing
                            ? 'Modifica el nombre de tu cuenta.'
                            : 'Registra una cuenta para llevar tu saldo.',
                        size: ScreenHeaderSize.compact,
                        onBack: widget.onDone,
                        backEnabled: !isSubmitting,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppColors.authCardFill,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.authCardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.16),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.authAccent
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.authAccent
                                          .withValues(alpha: 0.30),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_rounded,
                                    size: 20,
                                    color: AppColors.authAccent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Datos de la cuenta',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.authTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            InputTextField(
                              controller: _nameController,
                              label: 'Nombre',
                              hintText: 'Ej: Cuenta corriente',
                              enabled: !isSubmitting,
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'Ingresa un nombre'
                                      : null,
                            ),
                            if (!_isEditing) ...[
                              const SizedBox(height: 20),
                              InputTextField(
                                controller: _balanceController,
                                label: 'Saldo inicial',
                                hintText: '0.00',
                                enabled: !isSubmitting,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: (value) {
                                  final parsed =
                                      double.tryParse((value ?? '').trim());
                                  return parsed == null
                                      ? 'Ingresa un monto válido'
                                      : null;
                                },
                              ),
                              const SizedBox(height: 8),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  'Este será el saldo de partida para registrar tus movimientos.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.authTextFooter,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          label: _isEditing ? 'Guardar cambios' : 'Crear cuenta',
                          disabledAlpha: 0.6,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          isLoading: isSubmitting,
                          onPressed: isSubmitting ? null : _submit,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
