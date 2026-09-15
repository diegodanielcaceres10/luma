import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/view_models/account_view_model.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../view_models/transaction_view_model.dart';

/// type: 'income' o 'expense'. Fija el tipo de transacción que se va a crear;
/// no hay selector de tipo en el formulario a propósito, porque se llega acá
/// desde el botón correspondiente ("Añadir ingreso" / "Añadir gasto").
class AddTransactionScreen extends StatefulWidget {
  final String type;
  final String userId;
  final AccountViewModel accountViewModel;
  final CategoryViewModel categoryViewModel;
  final TransactionViewModel transactionViewModel;

  const AddTransactionScreen({
    super.key,
    required this.type,
    required this.userId,
    required this.accountViewModel,
    required this.categoryViewModel,
    required this.transactionViewModel,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  Category? _selectedCategory;
  Account? _selectedAccount;
  DateTime _selectedDate = DateTime.now();

  bool get _isIncome => widget.type == 'income';
  Color get _accentColor =>
      _isIncome ? AppColors.authIncome : AppColors.authExpense;

  static const _labelStyle = TextStyle(color: AppColors.authTextSecondary);

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
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
    if (_selectedCategory == null || _selectedAccount == null) return;

    final amount = double.parse(_amountController.text.replaceAll(',', '.'));

    final success = await widget.transactionViewModel.createTransaction(
      userId: widget.userId,
      accountId: _selectedAccount!.id,
      categoryId: _selectedCategory!.id,
      type: widget.type,
      amount: amount,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      date: _selectedDate,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.transactionViewModel.errorMessage ??
                'No se pudo guardar la transacción.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.categoryViewModel.byType(widget.type);
    final accounts = widget.accountViewModel.accounts;

    _selectedCategory ??= categories.isNotEmpty ? categories.first : null;
    _selectedAccount ??= accounts.isNotEmpty ? accounts.first : null;

    return Scaffold(
      backgroundColor: AppColors.authBackgroundBottom,
      appBar: AppBar(
        backgroundColor: AppColors.authBackgroundBottom,
        elevation: 0,
        title: Text(
          _isIncome ? 'Añadir ingreso' : 'Añadir gasto',
          style: const TextStyle(
            color: AppColors.authTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.authTextPrimary),
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
                const Text('Monto', style: _labelStyle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  style: const TextStyle(color: AppColors.authTextPrimary),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: _fieldDecoration.copyWith(hintText: '0.00'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa un monto';
                    }
                    final parsed = double.tryParse(value.replaceAll(',', '.'));
                    if (parsed == null || parsed <= 0) {
                      return 'Monto inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const Text('Categoría', style: _labelStyle),
                const SizedBox(height: 8),
                if (widget.categoryViewModel.isLoading)
                  const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.authAccent),
                  )
                else if (categories.isEmpty)
                  Text(
                    _isIncome
                        ? 'No hay categorías de ingreso todavía.'
                        : 'No hay categorías de gasto todavía.',
                    style: const TextStyle(color: AppColors.authExpense),
                  )
                else
                  DropdownButtonFormField<Category>(
                    initialValue: _selectedCategory,
                    dropdownColor: AppColors.authBackgroundBottom,
                    style: const TextStyle(color: AppColors.authTextPrimary),
                    decoration: _fieldDecoration,
                    items: categories
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c.name)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedCategory = value),
                  ),
                const SizedBox(height: 20),
                const Text('Cuenta', style: _labelStyle),
                const SizedBox(height: 8),
                if (widget.accountViewModel.isLoading)
                  const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.authAccent),
                  )
                else if (accounts.isEmpty)
                  const Text(
                    'No hay cuentas todavía.',
                    style: TextStyle(color: AppColors.authExpense),
                  )
                else
                  DropdownButtonFormField<Account>(
                    initialValue: _selectedAccount,
                    dropdownColor: AppColors.authBackgroundBottom,
                    style: const TextStyle(color: AppColors.authTextPrimary),
                    decoration: _fieldDecoration,
                    items: accounts
                        .map((a) => DropdownMenuItem(
                              value: a,
                              child: Text('${a.name} (${a.currency})'),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedAccount = value),
                  ),
                const SizedBox(height: 20),
                const Text('Descripción (opcional)', style: _labelStyle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(color: AppColors.authTextPrimary),
                  decoration:
                      _fieldDecoration.copyWith(hintText: 'Ej: Mercadona'),
                ),
                const SizedBox(height: 20),
                const Text('Fecha', style: _labelStyle),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: _fieldDecoration,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_selectedDate.day.toString().padLeft(2, '0')}/'
                          '${_selectedDate.month.toString().padLeft(2, '0')}/'
                          '${_selectedDate.year}',
                          style:
                              const TextStyle(color: AppColors.authTextPrimary),
                        ),
                        const Icon(Icons.calendar_today_rounded,
                            size: 18, color: AppColors.authTextSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: AppColors.authBackgroundBottom,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: widget.transactionViewModel.isSubmitting ||
                            categories.isEmpty ||
                            accounts.isEmpty
                        ? null
                        : _submit,
                    child: widget.transactionViewModel.isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.authBackgroundBottom,
                            ),
                          )
                        : Text(_isIncome ? 'Guardar ingreso' : 'Guardar gasto'),
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
