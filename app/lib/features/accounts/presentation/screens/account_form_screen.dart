import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/account_visuals.dart';
import '../../../../core/utils/category_visuals.dart'
    show colorFromHex, kCategoryColors;
import '../../data/models/account.dart';
import '../view_models/account_view_model.dart';

/// Si [account] viene nulo, es un alta nueva (con saldo inicial editable).
/// Si viene con valor, es edición — el saldo no se toca desde acá, se
/// mantiene a través de los movimientos.
class AccountFormScreen extends StatefulWidget {
  final String userId;
  final AccountViewModel accountViewModel;
  final Account? account;

  const AccountFormScreen({
    super.key,
    required this.userId,
    required this.accountViewModel,
    this.account,
  });

  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
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
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage ?? 'No se pudo guardar.')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.authBackgroundBottom,
        title: const Text('Eliminar cuenta',
            style: TextStyle(color: AppColors.authTextPrimary)),
        content: Text(
          '¿Seguro que quieres eliminar "${widget.account!.name}"? '
          'Las transacciones asociadas se conservan, pero la cuenta ya '
          'no va a aparecer en tus listados.',
          style: const TextStyle(color: AppColors.authTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.authTextSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar',
                style: TextStyle(color: AppColors.authExpense)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success =
        await widget.accountViewModel.deleteAccount(widget.account!.id);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.accountViewModel.errorMessage ??
                'No se pudo eliminar la cuenta.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = widget.accountViewModel.isSubmitting;

    return Scaffold(
      backgroundColor: AppColors.authBackgroundBottom,
      appBar: AppBar(
        backgroundColor: AppColors.authBackgroundBottom,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.authTextPrimary),
        title: Text(
          _isEditing ? 'Editar cuenta' : 'Nueva cuenta',
          style: const TextStyle(
            color: AppColors.authTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: isSubmitting ? null : _confirmDelete,
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.authExpense),
            ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.authBackgroundTop,
              AppColors.authBackgroundBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
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
                            color:
                                isSelected ? accent : AppColors.authCardBorder,
                          ),
                        ),
                        child: Icon(
                          entry.value,
                          color:
                              isSelected ? accent : AppColors.authTextSecondary,
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
        ),
      ),
    );
  }
}
