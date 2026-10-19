import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/input_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../data/models/category.dart';
import '../view_models/category_view_model.dart';
import '../widgets/custom_color_sheet.dart';

/// The type ('expense' or 'income') is not a regular form field: when editing
/// it is fixed to the category's type; when creating, it is chosen first in
/// [_buildTypeChooser] and cannot be changed afterwards.
class CategoryFormScreen extends StatefulWidget {
  final String userId;
  final CategoryViewModel categoryViewModel;
  final Category? category;
  final String initialType;

  final VoidCallback onDone;

  const CategoryFormScreen({
    super.key,
    required this.userId,
    required this.categoryViewModel,
    required this.onDone,
    this.category,
    this.initialType = 'expense',
  });

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _budgetController = TextEditingController();

  late String _type;
  late String _selectedColor;
  late bool _hasBudget;

  /// Whether the form can be shown: always when editing, only after picking
  /// a type in [_buildTypeChooser] when creating.
  late bool _typeSelected;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _nameController.text = category?.name ?? '';
    _type = category?.type ?? widget.initialType;
    _selectedColor = category?.color ?? kCategoryColors.first;
    _hasBudget = category?.hasBudget ?? false;
    _budgetController.text =
        category != null ? (category.budgetAmount ?? 0).toStringAsFixed(2) : '';
    _typeSelected = _isEditing;
    widget.categoryViewModel.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  void _selectType(String type) {
    setState(() {
      _type = type;
      _typeSelected = true;
    });
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

    final confirmed = await showConfirmDialog(context);
    if (!confirmed || !mounted) return;

    final vm = widget.categoryViewModel;
    // Budgets only apply to expenses; ignore the switch for income.
    final effectiveHasBudget = _type == 'expense' && _hasBudget;
    final effectiveBudgetAmount =
        effectiveHasBudget ? double.parse(_budgetController.text.trim()) : null;

    final success = _isEditing
        ? await vm.updateCategory(
            id: widget.category!.id,
            name: _nameController.text.trim(),
            type: _type,
            color: _selectedColor,
            hasBudget: effectiveHasBudget,
            budgetAmount: effectiveBudgetAmount,
          )
        : await vm.createCategory(
            userId: widget.userId,
            name: _nameController.text.trim(),
            type: _type,
            color: _selectedColor,
            hasBudget: effectiveHasBudget,
            budgetAmount: effectiveBudgetAmount,
          );

    if (!mounted) return;

    if (success) {
      widget.onDone();
    } else {
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
                  vm.errorMessage ?? 'No se pudo guardar.',
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

  Future<void> _openCustomColorPicker() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.authBackgroundBottom,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CustomColorSheet(
        initialColor: colorFromHex(_selectedColor),
      ),
    );

    if (picked != null && mounted) {
      setState(() => _selectedColor = picked);
    }
  }

  Widget _buildColorDot({required String hex, required VoidCallback? onTap}) {
    final color = colorFromHex(hex);
    final isSelected = hex == _selectedColor;
    final checkColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.light
            ? Colors.black87
            : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.authTextPrimary : Colors.transparent,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? Icon(Icons.check_rounded, color: checkColor, size: 20)
            : null,
      ),
    );
  }

  Widget _buildAddColorButton({required VoidCallback? onTap}) {
    return Tooltip(
      message: 'Color personalizado',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.authAccent.withValues(alpha: 0.08),
            border: Border.all(
              color: AppColors.authAccent.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.add_rounded,
            color: AppColors.authAccent,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeOption({
    required String type,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectType(type),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: color.withValues(alpha: 0.32),
                    ),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.authTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.authTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.authTextSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChooser() {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            ScreenHeader(
              title: 'Nueva categoría',
              subtitle: 'Selecciona el tipo de movimiento para comenzar.',
              size: ScreenHeaderSize.compact,
              onBack: widget.onDone,
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                '¿Es una categoría de gastos o de ingresos?',
                style: TextStyle(
                  color: AppColors.authTextSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            _buildTypeOption(
              type: 'expense',
              label: 'Gasto',
              subtitle:
                  'Para compras, servicios, suscripciones y salidas habituales.',
              icon: Icons.trending_down_rounded,
              color: AppColors.authExpense,
            ),
            const SizedBox(height: 14),
            _buildTypeOption(
              type: 'income',
              label: 'Ingreso',
              subtitle: 'Para sueldos, inversiones, transferencias o cobros.',
              icon: Icons.trending_up_rounded,
              color: AppColors.authIncome,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(bool isSubmitting) {
    final catColor = colorFromHex(
      _selectedColor,
      fallback: AppColors.authTextFooter,
    );
    final isExpense = _type == 'expense';
    final typeColor = isExpense ? AppColors.authExpense : AppColors.authIncome;

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
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    ScreenHeader(
                      title:
                          _isEditing ? 'Editar categoría' : 'Nueva categoría',
                      subtitle: _isEditing
                          ? 'Modifica los detalles y preferencias de la categoría.'
                          : 'Personaliza el nombre, color y presupuesto de la categoría.',
                      size: ScreenHeaderSize.compact,
                      onBack: widget.onDone,
                      backEnabled: !isSubmitting,
                    ),
                    const SizedBox(height: 20),
                    // Tarjeta 1: Datos de la categoría
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
                                  color: catColor.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: catColor.withValues(alpha: 0.32),
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: catColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              catColor.withValues(alpha: 0.45),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Datos de la categoría',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.authTextPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: typeColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: typeColor.withValues(alpha: 0.28),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isExpense
                                          ? Icons.trending_down_rounded
                                          : Icons.trending_up_rounded,
                                      size: 13,
                                      color: typeColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isExpense ? 'Gasto' : 'Ingreso',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: typeColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          InputTextField(
                            controller: _nameController,
                            label: 'Nombre',
                            hintText: 'Ej: Suscripciones',
                            enabled: !isSubmitting,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Ingresa un nombre'
                                    : null,
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'Color identificador',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.authTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final hex in kCategoryColors)
                                _buildColorDot(
                                  hex: hex,
                                  onTap: isSubmitting
                                      ? null
                                      : () => setState(
                                          () => _selectedColor = hex),
                                ),
                              if (!kCategoryColors.contains(_selectedColor))
                                _buildColorDot(
                                  hex: _selectedColor,
                                  onTap: isSubmitting
                                      ? null
                                      : _openCustomColorPicker,
                                ),
                              _buildAddColorButton(
                                onTap: isSubmitting
                                    ? null
                                    : _openCustomColorPicker,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isExpense) ...[
                      const SizedBox(height: 16),
                      // Tarjeta 2: Presupuesto mensual
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
                                    Icons.savings_outlined,
                                    size: 20,
                                    color: AppColors.authAccent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Presupuesto mensual',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.authTextPrimary,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: _hasBudget,
                                  activeThumbColor: AppColors.authAccent,
                                  onChanged: isSubmitting
                                      ? null
                                      : (value) =>
                                          setState(() => _hasBudget = value),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 2),
                              child: Text(
                                'Establece un límite mensual de gasto para supervisar desvíos.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.authTextFooter,
                                ),
                              ),
                            ),
                            if (_hasBudget) ...[
                              const SizedBox(height: 16),
                              InputTextField(
                                controller: _budgetController,
                                label: 'Monto mensual',
                                hintText: '0.00',
                                enabled: !isSubmitting,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: (value) {
                                  if (!_hasBudget) return null;
                                  final parsed =
                                      double.tryParse((value ?? '').trim());
                                  if (parsed == null || parsed <= 0) {
                                    return 'Ingresa un monto válido';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        label:
                            _isEditing ? 'Guardar cambios' : 'Crear categoría',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = widget.categoryViewModel.isSubmitting;

    return SafeArea(
      top: false,
      child: _typeSelected ? _buildForm(isSubmitting) : _buildTypeChooser(),
    );
  }
}
