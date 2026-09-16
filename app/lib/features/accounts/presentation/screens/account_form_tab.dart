import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/account_visuals.dart';
import '../../../../core/utils/category_visuals.dart'
    show colorFromHex, kCategoryColors;
import '../../data/models/account.dart';
import '../view_models/account_view_model.dart';

/// Contenido de la pestaña "Nueva cuenta" / "Editar cuenta". No tiene
/// Scaffold propio — vive dentro del Scaffold del HomeShell, que es quien
/// pone el header y el bottomNavigationBar.
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

  late String _currency;
  late String _selectedColor;
  late String _selectedIcon;

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
        account != null ? account.balance.toStringAsFixed(2) : '0.00';
    _currency = account?.currency ?? kAccountCurrencies.first;
    _selectedColor = account?.color ?? kCategoryColors.first;
    _selectedIcon = account?.icon ?? kAccountIcons.keys.first;
  }

  @override
  void dispose() {
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
            currency: _currency,
            color: _selectedColor,
            icon: _selectedIcon,
          )
        : await vm.createAccount(
            userId: widget.userId,
            name: _nameController.text.trim(),
            currency: _currency,
            balance: double.parse(_balanceController.text.trim()),
            color: _selectedColor,
            icon: _selectedIcon,
          );

    if (!mounted) return;

    if (success) {
      widget.onDone();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage ?? 'No se pudo guardar.')),
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
              style: const TextStyle(color: AppColors.authTextPrimary),
              decoration: _fieldDecoration.copyWith(
                hintText: 'Ej: Cuenta corriente',
                hintStyle: const TextStyle(color: AppColors.authTextFooter),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Ingresa un nombre'
                  : null,
            ),
            const SizedBox(height: 20),
            const Text('Moneda',
                style: TextStyle(color: AppColors.authTextSecondary)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              dropdownColor: AppColors.authBackgroundBottom,
              style: const TextStyle(color: AppColors.authTextPrimary),
              decoration: _fieldDecoration,
              items: kAccountCurrencies
                  .map((code) => DropdownMenuItem(
                        value: code,
                        child: Text(code),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _currency = value);
              },
            ),
            if (!_isEditing) ...[
              const SizedBox(height: 20),
              const Text('Saldo inicial',
                  style: TextStyle(color: AppColors.authTextSecondary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _balanceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.authTextPrimary),
                decoration: _fieldDecoration.copyWith(hintText: '0.00'),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').trim());
                  return parsed == null ? 'Ingresa un monto válido' : null;
                },
              ),
            ],
            const SizedBox(height: 20),
            const Text('Color',
                style: TextStyle(color: AppColors.authTextSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: kCategoryColors.map((hex) {
                final isSelected = hex == _selectedColor;
                return InkWell(
                  onTap: () => setState(() => _selectedColor = hex),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorFromHex(hex),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: AppColors.authTextPrimary, width: 2)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Ícono',
                style: TextStyle(color: AppColors.authTextSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: kAccountIcons.entries.map((entry) {
                final isSelected = entry.key == _selectedIcon;
                final accent = colorFromHex(_selectedColor);
                return InkWell(
                  onTap: () => setState(() => _selectedIcon = entry.key),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accent.withValues(alpha: 0.25)
                          : AppColors.authCardFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? accent : AppColors.authCardBorder,
                      ),
                    ),
                    child: Icon(
                      entry.value,
                      color: isSelected ? accent : AppColors.authTextSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.authAccent,
                  foregroundColor: AppColors.authBackgroundBottom,
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
                    : Text(_isEditing ? 'Guardar cambios' : 'Crear cuenta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
