import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../data/models/service.dart';
import '../view_models/service_view_model.dart';

/// Contenido de la pestaña "Nuevo servicio" / "Editar servicio". No tiene
/// Scaffold propio — vive dentro del Scaffold del HomeShell, que es quien
/// pone el header y el bottomNavigationBar.
///
/// Si [service] viene nulo, es un alta nueva. Si viene con valor, es
/// edición — activo/inactivo no se toca acá, se maneja desde la lista.
class ServiceFormTab extends StatefulWidget {
  final String userId;
  final ServiceViewModel serviceViewModel;
  final CategoryViewModel categoryViewModel;
  final Service? service;

  /// Se llama tras guardar con éxito, o al cancelar, para volver a
  /// "Servicios".
  final VoidCallback onDone;

  const ServiceFormTab({
    super.key,
    required this.userId,
    required this.serviceViewModel,
    required this.categoryViewModel,
    required this.onDone,
    this.service,
  });

  @override
  State<ServiceFormTab> createState() => _ServiceFormTabState();
}

class _ServiceFormTabState extends State<ServiceFormTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _dueDayController = TextEditingController();

  String? _selectedCategoryId;

  bool get _isEditing => widget.service != null;

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
  void initState() {
    super.initState();
    final service = widget.service;
    _nameController.text = service?.name ?? '';
    _amountController.text = service != null
        ? service.approximateAmount.toStringAsFixed(2)
        : '';
    _dueDayController.text = service?.dueDay?.toString() ?? '';
    _selectedCategoryId = service?.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _dueDayController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = widget.serviceViewModel;
    final amount = double.parse(_amountController.text.trim());
    final dueDayText = _dueDayController.text.trim();
    final dueDay = dueDayText.isEmpty ? null : int.parse(dueDayText);

    final success = _isEditing
        ? await vm.updateService(
            id: widget.service!.id,
            name: _nameController.text.trim(),
            approximateAmount: amount,
            categoryId: _selectedCategoryId,
            dueDay: dueDay,
          )
        : await vm.createService(
            userId: widget.userId,
            name: _nameController.text.trim(),
            approximateAmount: amount,
            categoryId: _selectedCategoryId,
            dueDay: dueDay,
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
    final isSubmitting = widget.serviceViewModel.isSubmitting;
    // Los servicios recurrentes son siempre un gasto — mismo criterio que
    // ya usa el presupuesto de categorías.
    final expenseCategories = widget.categoryViewModel.byType('expense');

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
                  _isEditing ? 'Editar servicio' : 'Nuevo servicio',
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
                hintText: 'Ej: Netflix',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Ingresa un nombre'
                  : null,
            ),
            const SizedBox(height: 20),
            const Text('Monto aproximado',
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
                return parsed == null || parsed < 0
                    ? 'Ingresa un monto válido'
                    : null;
              },
            ),
            const SizedBox(height: 20),
            const Text('Día de vencimiento (opcional)',
                style: TextStyle(color: AppColors.authTextSecondary)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _dueDayController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.authTextPrimary),
              decoration: _fieldDecoration.copyWith(hintText: 'Ej: 10'),
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) return null;
                final parsed = int.tryParse(text);
                if (parsed == null || parsed < 1 || parsed > 31) {
                  return 'Ingresa un día entre 1 y 31';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            const Text('Categoría (opcional)',
                style: TextStyle(color: AppColors.authTextSecondary)),
            const SizedBox(height: 8),
            if (widget.categoryViewModel.isLoading)
              const Center(
                child: CircularProgressIndicator(color: AppColors.authAccent),
              )
            else
              DropdownButtonFormField<String?>(
                initialValue: _selectedCategoryId,
                dropdownColor: AppColors.authBackgroundBottom,
                style: const TextStyle(color: AppColors.authTextPrimary),
                decoration: _fieldDecoration,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Sin categoría'),
                  ),
                  ...expenseCategories.map(
                    (Category c) => DropdownMenuItem<String?>(
                      value: c.id,
                      child: Text(c.name),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _selectedCategoryId = value),
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
                    : Text(_isEditing ? 'Guardar cambios' : 'Crear servicio'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
