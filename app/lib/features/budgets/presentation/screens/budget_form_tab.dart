import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';

/// Contenido de la pestaña "Nuevo presupuesto" / "Editar presupuesto". No
/// tiene Scaffold propio — vive dentro del Scaffold del HomeShell.
///
/// Solo se pueden presupuestar categorías de gasto, y cada categoría admite
/// un único presupuesto (es un dato de la propia categoría: `has_budget` +
/// `budget_amount`). El picker excluye categorías ya presupuestadas.
///
/// Si [category] viene nulo, es alta: se elige a qué categoría sin
/// presupuesto asignarle uno. Si viene con valor, es edición — la
/// categoría queda fija (para reasignarla hay que quitar el presupuesto y
/// crearlo de nuevo en la otra categoría) y solo se edita el monto, con la
/// opción de quitar el presupuesto.
class BudgetFormTab extends StatefulWidget {
  final CategoryViewModel categoryViewModel;
  final Category? category;
  final VoidCallback onDone;

  const BudgetFormTab({
    super.key,
    required this.categoryViewModel,
    required this.onDone,
    this.category,
  });

  @override
  State<BudgetFormTab> createState() => _BudgetFormTabState();
}

class _BudgetFormTabState extends State<BudgetFormTab> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  String? _selectedCategoryId;

  bool get _isEditing => widget.category != null;

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
    final category = widget.category;
    _amountController.text =
        category != null ? (category.budgetAmount ?? 0).toStringAsFixed(2) : '';
    _selectedCategoryId = category?.id;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  /// Categorías de gasto sin presupuesto todavía (para el alta).
  List<Category> get _availableCategories {
    final budgeted = widget.categoryViewModel.budgetedCategoryIds;
    return widget.categoryViewModel
        .byType('expense')
        .where((c) => !budgeted.contains(c.id))
        .toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final categoryId = _selectedCategoryId;
    if (categoryId == null) return;

    final vm = widget.categoryViewModel;
    final amount = double.parse(_amountController.text.trim());
    final success = await vm.setCategoryBudget(
      categoryId: categoryId,
      amount: amount,
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

  Future<void> _removeBudget() async {
    final category = widget.category;
    if (category == null) return;

    final vm = widget.categoryViewModel;
    final success = await vm.clearCategoryBudget(category.id);

    if (!mounted) return;

    if (success) {
      widget.onDone();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(vm.errorMessage ?? 'No se pudo quitar el presupuesto.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = widget.categoryViewModel.isSubmitting;
    final categories = _availableCategories;

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
                  _isEditing ? 'Editar presupuesto' : 'Nuevo presupuesto',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.authTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Categoría',
                style: TextStyle(color: AppColors.authTextSecondary)),
            const SizedBox(height: 8),
            if (_isEditing)
              // La categoría queda fija en edición: reasignar implica
              // quitar el presupuesto y crearlo de nuevo en otra.
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.authCardFill,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.authCardBorder),
                ),
                child: Text(
                  widget.category!.name,
                  style: const TextStyle(color: AppColors.authTextPrimary),
                ),
              )
            else if (categories.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No hay categorías de gasto disponibles. Todas ya tienen '
                  'un presupuesto, o todavía no creaste ninguna.',
                  style: TextStyle(color: AppColors.authTextSecondary),
                ),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                dropdownColor: AppColors.authBackgroundBottom,
                style: const TextStyle(color: AppColors.authTextPrimary),
                decoration: _fieldDecoration,
                items: categories
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedCategoryId = value),
                validator: (value) =>
                    value == null ? 'Elegí una categoría' : null,
              ),
            const SizedBox(height: 20),
            const Text('Monto',
                style: TextStyle(color: AppColors.authTextSecondary)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.authTextPrimary),
              decoration: _fieldDecoration.copyWith(hintText: '0.00'),
              validator: (value) {
                final parsed = double.tryParse((value ?? '').trim());
                if (parsed == null) return 'Ingresa un monto válido';
                if (parsed <= 0) return 'El monto debe ser mayor a 0';
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
                        _isEditing ? 'Guardar cambios' : 'Crear presupuesto'),
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: isSubmitting ? null : _removeBudget,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.authExpense,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Quitar presupuesto'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
