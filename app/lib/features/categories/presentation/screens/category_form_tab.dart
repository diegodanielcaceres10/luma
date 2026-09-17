import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../data/models/category.dart';
import '../view_models/category_view_model.dart';

/// Contenido de la pestaña "Nueva categoría" / "Editar categoría". No tiene
/// Scaffold propio — vive dentro del Scaffold del HomeShell, que es quien
/// pone el header y el bottomNavigationBar.
///
/// Si [category] viene nulo, es un alta nueva (con [initialType] fijo).
/// Si viene con valor, es edición — el tipo se puede seguir cambiando.
class CategoryFormTab extends StatefulWidget {
  final String userId;
  final CategoryViewModel categoryViewModel;
  final Category? category;
  final String initialType;

  /// Se llama tras guardar o eliminar con éxito, o al cancelar, para volver
  /// a "Categorías".
  final VoidCallback onDone;

  const CategoryFormTab({
    super.key,
    required this.userId,
    required this.categoryViewModel,
    required this.onDone,
    this.category,
    this.initialType = 'expense',
  });

  @override
  State<CategoryFormTab> createState() => _CategoryFormTabState();
}

class _CategoryFormTabState extends State<CategoryFormTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _budgetController = TextEditingController();

  late String _type;
  late String _selectedColor;
  late String _selectedIcon;
  late bool _hasBudget;

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
    _nameController.text = category?.name ?? '';
    _type = category?.type ?? widget.initialType;
    _selectedColor = category?.color ?? kCategoryColors.first;
    _selectedIcon = category?.icon ?? kCategoryIcons.keys.first;
    _hasBudget = category?.hasBudget ?? false;
    _budgetController.text =
        category != null ? (category.budgetAmount ?? 0).toStringAsFixed(2) : '';
    widget.categoryViewModel.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.categoryViewModel.removeListener(_onViewModelChanged);
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = widget.categoryViewModel;
    // El presupuesto solo aplica a gastos — si el tipo es 'income', se
    // ignora aunque el switch haya quedado prendido de un cambio previo.
    final effectiveHasBudget = _type == 'expense' && _hasBudget;
    final effectiveBudgetAmount =
        effectiveHasBudget ? double.parse(_budgetController.text.trim()) : null;

    final success = _isEditing
        ? await vm.updateCategory(
            id: widget.category!.id,
            name: _nameController.text.trim(),
            type: _type,
            color: _selectedColor,
            icon: _selectedIcon,
            hasBudget: effectiveHasBudget,
            budgetAmount: effectiveBudgetAmount,
          )
        : await vm.createCategory(
            userId: widget.userId,
            name: _nameController.text.trim(),
            type: _type,
            color: _selectedColor,
            icon: _selectedIcon,
            hasBudget: effectiveHasBudget,
            budgetAmount: effectiveBudgetAmount,
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
    final isSubmitting = widget.categoryViewModel.isSubmitting;

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
                      Expanded(
                        child: Text(
                          _isEditing ? 'Editar categoría' : 'Nueva categoría',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.authTextPrimary,
                          ),
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
                      hintText: 'Ej: Suscripciones',
                      hintStyle:
                          const TextStyle(color: AppColors.authTextFooter),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Ingresa un nombre'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  const Text('Tipo',
                      style: TextStyle(color: AppColors.authTextSecondary)),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    style: SegmentedButton.styleFrom(
                      backgroundColor: AppColors.authCardFill,
                      foregroundColor: AppColors.authTextSecondary,
                      selectedBackgroundColor: AppColors.authAccent,
                      selectedForegroundColor: AppColors.authBackgroundBottom,
                      side: const BorderSide(color: AppColors.authCardBorder),
                    ),
                    segments: const [
                      ButtonSegment(value: 'expense', label: Text('Gasto')),
                      ButtonSegment(value: 'income', label: Text('Ingreso')),
                    ],
                    selected: {_type},
                    onSelectionChanged: isSubmitting
                        ? null
                        : (selection) =>
                            setState(() => _type = selection.first),
                  ),
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
                        onTap: isSubmitting
                            ? null
                            : () => setState(() => _selectedColor = hex),
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
                    children: kCategoryIcons.entries.map((entry) {
                      final isSelected = entry.key == _selectedIcon;
                      final accent = colorFromHex(_selectedColor);
                      return InkWell(
                        onTap: isSubmitting
                            ? null
                            : () => setState(() => _selectedIcon = entry.key),
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
                              color: isSelected
                                  ? accent
                                  : AppColors.authCardBorder,
                            ),
                          ),
                          child: Icon(
                            entry.value,
                            color: isSelected
                                ? accent
                                : AppColors.authTextSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (_type == 'expense') ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Presupuesto mensual',
                              style: TextStyle(
                                  color: AppColors.authTextSecondary)),
                        ),
                        Switch(
                          value: _hasBudget,
                          activeThumbColor: AppColors.authAccent,
                          onChanged: isSubmitting
                              ? null
                              : (value) => setState(() => _hasBudget = value),
                        ),
                      ],
                    ),
                    if (_hasBudget) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _budgetController,
                        enabled: !isSubmitting,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style:
                            const TextStyle(color: AppColors.authTextPrimary),
                        decoration: _fieldDecoration.copyWith(
                          hintText: '0.00',
                          hintStyle:
                              const TextStyle(color: AppColors.authTextFooter),
                        ),
                        validator: (value) {
                          if (!_hasBudget) return null;
                          final parsed = double.tryParse((value ?? '').trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Ingresa un monto válido';
                          }
                          return null;
                        },
                      ),
                    ],
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
                          : Text(_isEditing
                              ? 'Guardar cambios'
                              : 'Crear categoría'),
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
