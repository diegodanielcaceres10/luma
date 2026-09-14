import 'package:flutter/material.dart' hide Category;

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          _isIncome ? 'Añadir ingreso' : 'Añadir gasto',
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Monto', style: AppTextStyles.subtitle),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: '0.00',
                  border: OutlineInputBorder(),
                ),
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
              const Text('Categoría', style: AppTextStyles.subtitle),
              const SizedBox(height: 8),
              if (widget.categoryViewModel.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (categories.isEmpty)
                Text(
                  _isIncome
                      ? 'No hay categorías de ingreso todavía.'
                      : 'No hay categorías de gasto todavía.',
                  style: AppTextStyles.body.copyWith(color: AppColors.error),
                )
              else
                DropdownButtonFormField<Category>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedCategory = value),
                ),
              const SizedBox(height: 20),
              const Text('Cuenta', style: AppTextStyles.subtitle),
              const SizedBox(height: 8),
              if (widget.accountViewModel.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (accounts.isEmpty)
                Text(
                  'No hay cuentas todavía.',
                  style: AppTextStyles.body.copyWith(color: AppColors.error),
                )
              else
                DropdownButtonFormField<Account>(
                  value: _selectedAccount,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: accounts
                      .map((a) => DropdownMenuItem(
                            value: a,
                            child: Text('${a.name} (${a.currency})'),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedAccount = value),
                ),
              const SizedBox(height: 20),
              const Text('Descripción (opcional)', style: AppTextStyles.subtitle),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Ej: Mercadona',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Fecha', style: AppTextStyles.subtitle),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedDate.day.toString().padLeft(2, '0')}/'
                        '${_selectedDate.month.toString().padLeft(2, '0')}/'
                        '${_selectedDate.year}',
                        style: AppTextStyles.body,
                      ),
                      const Icon(Icons.calendar_today_rounded, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        _isIncome ? AppColors.success : AppColors.error,
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
                            color: Colors.white,
                          ),
                        )
                      : Text(_isIncome ? 'Guardar ingreso' : 'Guardar gasto'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
