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
        SnackBar(content: Text(vm.errorMessage ?? 'No se pudo guardar.')),
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
    // Custom colors can be very light, so pick the check color by brightness.
    final checkColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.light
            ? Colors.black87
            : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: AppColors.authTextPrimary, width: 2)
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
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
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
    required IconData icon,
    required Color color,
  }) {
    return InkWell(
      onTap: () => _selectType(type),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.authCardFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.authCardBorder),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withValues(alpha: 0.18),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.authTextPrimary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.authTextSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChooser() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            title: 'Nueva categoría',
            size: ScreenHeaderSize.compact,
            onBack: widget.onDone,
          ),
          const SizedBox(height: 20),
          const Text(
            '¿Es una categoría de gastos o de ingresos?',
            style: TextStyle(color: AppColors.authTextSecondary),
          ),
          const SizedBox(height: 16),
          _buildTypeOption(
            type: 'expense',
            label: 'Gasto',
            icon: Icons.trending_down_rounded,
            color: AppColors.authExpense,
          ),
          const SizedBox(height: 12),
          _buildTypeOption(
            type: 'income',
            label: 'Ingreso',
            icon: Icons.trending_up_rounded,
            color: AppColors.authIncome,
          ),
        ],
      ),
    );
  }

  Widget _buildForm(bool isSubmitting) {
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                ScreenHeader(
                  title: _isEditing ? 'Editar categoría' : 'Nueva categoría',
                  size: ScreenHeaderSize.compact,
                  onBack: widget.onDone,
                  backEnabled: !isSubmitting,
                ),
                const SizedBox(height: 20),
                InputTextField(
                  controller: _nameController,
                  label: 'Nombre',
                  hintText: 'Ej: Suscripciones',
                  enabled: !isSubmitting,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa un nombre'
                      : null,
                ),
                const SizedBox(height: 20),
                const Text('Color',
                    style: TextStyle(color: AppColors.authTextSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final hex in kCategoryColors)
                      _buildColorDot(
                        hex: hex,
                        onTap: isSubmitting
                            ? null
                            : () => setState(() => _selectedColor = hex),
                      ),
                    // Custom color outside the quick palette: shown as selected
                    // and reopens the picker when tapped.
                    if (!kCategoryColors.contains(_selectedColor))
                      _buildColorDot(
                        hex: _selectedColor,
                        onTap: isSubmitting ? null : _openCustomColorPicker,
                      ),
                    _buildAddColorButton(
                      onTap: isSubmitting ? null : _openCustomColorPicker,
                    ),
                  ],
                ),
                if (_type == 'expense') ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Presupuesto mensual',
                            style:
                                TextStyle(color: AppColors.authTextSecondary)),
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
                    InputTextField(
                      controller: _budgetController,
                      hintText: '0.00',
                      enabled: !isSubmitting,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
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
                  child: PrimaryButton(
                    label: _isEditing ? 'Guardar cambios' : 'Crear categoría',
                    disabledAlpha: 0.6,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    isLoading: isSubmitting,
                    onPressed: isSubmitting ? null : _submit,
                  ),
                ),
              ],
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
