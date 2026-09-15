import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../data/models/category.dart';
import '../view_models/category_view_model.dart';

/// Si [category] viene nulo, es un alta nueva (con [initialType] fijo).
/// Si viene con valor, es edición — el tipo se puede seguir cambiando.
class CategoryFormScreen extends StatefulWidget {
  final String userId;
  final CategoryViewModel categoryViewModel;
  final Category? category;
  final String initialType;

  const CategoryFormScreen({
    super.key,
    required this.userId,
    required this.categoryViewModel,
    this.category,
    this.initialType = 'expense',
  });

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  late String _type;
  late String _selectedColor;
  late String _selectedIcon;

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = widget.categoryViewModel;
    final success = _isEditing
        ? await vm.updateCategory(
            id: widget.category!.id,
            name: _nameController.text.trim(),
            type: _type,
            color: _selectedColor,
            icon: _selectedIcon,
          )
        : await vm.createCategory(
            userId: widget.userId,
            name: _nameController.text.trim(),
            type: _type,
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
        title: const Text('Eliminar categoría',
            style: TextStyle(color: AppColors.authTextPrimary)),
        content: Text(
          '¿Seguro que quieres eliminar "${widget.category!.name}"? '
          'Las transacciones que la usaban van a quedar sin categoría.',
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
        await widget.categoryViewModel.deleteCategory(widget.category!.id);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.categoryViewModel.errorMessage ??
                'No se pudo eliminar la categoría.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = widget.categoryViewModel.isSubmitting;

    return Scaffold(
      backgroundColor: AppColors.authBackgroundBottom,
      appBar: AppBar(
        backgroundColor: AppColors.authBackgroundBottom,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.authTextPrimary),
        title: Text(
          _isEditing ? 'Editar categoría' : 'Nueva categoría',
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
                    hintText: 'Ej: Suscripciones',
                    hintStyle: const TextStyle(color: AppColors.authTextFooter),
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
                  onSelectionChanged: (selection) =>
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
                  children: kCategoryIcons.entries.map((entry) {
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
                        : Text(
                            _isEditing ? 'Guardar cambios' : 'Crear categoría'),
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
