import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/input_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../data/models/service.dart';
import '../view_models/service_view_model.dart';

/// Creates a service, or edits it when [service] is provided. The active
/// state is not edited here; it is toggled from the view screen.
class ServiceFormScreen extends StatefulWidget {
  final String userId;
  final ServiceViewModel serviceViewModel;
  final CategoryViewModel categoryViewModel;
  final Service? service;

  final VoidCallback onDone;

  const ServiceFormScreen({
    super.key,
    required this.userId,
    required this.serviceViewModel,
    required this.categoryViewModel,
    required this.onDone,
    this.service,
  });

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _dueDayController = TextEditingController();

  String? _selectedCategoryId;

  bool get _isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    final service = widget.service;
    _nameController.text = service?.name ?? '';
    _amountController.text =
        service != null ? service.approximateAmount.toStringAsFixed(2) : '';
    _dueDayController.text = service?.dueDay?.toString() ?? '';
    _selectedCategoryId = service?.categoryId;
    widget.serviceViewModel.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.serviceViewModel.removeListener(_onViewModelChanged);
    _nameController.dispose();
    _amountController.dispose();
    _dueDayController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await showConfirmDialog(context);
    if (!confirmed || !mounted) return;

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
      final isDuplicate = vm.submitError == ServiceSubmitError.duplicate;
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
                  isDuplicate
                      ? 'Ya existe un servicio con ese nombre.'
                      : 'Ocurrió un error al guardar. Intentá de nuevo.',
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

  @override
  Widget build(BuildContext context) {
    final isSubmitting = widget.serviceViewModel.isSubmitting;
    // Recurring services are always expenses.
    final expenseCategories = widget.categoryViewModel.byType('expense');

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
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      ScreenHeader(
                        title: _isEditing ? 'Editar servicio' : 'Nuevo servicio',
                        subtitle: _isEditing
                            ? 'Modifica los datos y condiciones del servicio recurrente.'
                            : 'Registra una suscripción o costo fijo para proyectar tus gastos.',
                        size: ScreenHeaderSize.compact,
                        onBack: widget.onDone,
                        backEnabled: !isSubmitting,
                      ),
                      const SizedBox(height: 20),
                      // Tarjeta 1: Datos del servicio
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
                                    Icons.receipt_long_rounded,
                                    size: 20,
                                    color: AppColors.authAccent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Datos del servicio',
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
                                    color: AppColors.authExpense
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.authExpense
                                          .withValues(alpha: 0.28),
                                    ),
                                  ),
                                  child: const Text(
                                    'Gasto fijo',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.authExpense,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Categoría',
                              style: TextStyle(
                                color: AppColors.authTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (widget.categoryViewModel.isLoading)
                              const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.authAccent,
                                ),
                              )
                            else
                              DropdownButtonFormField<String?>(
                                initialValue: _selectedCategoryId,
                                dropdownColor: AppColors.authBackgroundBottom,
                                style: const TextStyle(
                                  color: AppColors.authTextPrimary,
                                ),
                                hint: const Text(
                                  'Seleccioná una categoría',
                                  style: TextStyle(
                                    color: AppColors.authTextSecondary,
                                  ),
                                ),
                                decoration: InputTextField.formDecoration,
                                items: expenseCategories
                                    .map(
                                      (Category c) =>
                                          DropdownMenuItem<String?>(
                                        value: c.id,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: colorFromHex(
                                                  c.color,
                                                  fallback: AppColors
                                                      .authTextFooter,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(c.name),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: isSubmitting
                                    ? null
                                    : (value) => setState(
                                        () => _selectedCategoryId = value),
                                validator: (value) => value == null
                                    ? 'Seleccioná una categoría'
                                    : null,
                              ),
                            const SizedBox(height: 20),
                            InputTextField(
                              controller: _nameController,
                              label: 'Nombre',
                              hintText: 'Ej: Netflix',
                              enabled: !isSubmitting,
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'Ingresa un nombre'
                                      : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Tarjeta 2: Condiciones y Pago
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
                                    Icons.calendar_month_rounded,
                                    size: 20,
                                    color: AppColors.authAccent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Condiciones y pago',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.authTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            InputTextField(
                              controller: _amountController,
                              label: 'Monto aproximado',
                              hintText: '0.00',
                              helperText:
                                  'Monto recurrente estimado que se facturará cada mes.',
                              enabled: !isSubmitting,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: (value) {
                                final parsed =
                                    double.tryParse((value ?? '').trim());
                                return parsed == null || parsed < 0
                                    ? 'Ingresa un monto válido'
                                    : null;
                              },
                            ),
                            const SizedBox(height: 16),
                            InputTextField(
                              controller: _dueDayController,
                              label: 'Día de vencimiento (opcional)',
                              hintText: 'Ej: 10',
                              helperText:
                                  'Día del mes (1 a 31) en que opera el débito o vencimiento.',
                              enabled: !isSubmitting,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final text = (value ?? '').trim();
                                if (text.isEmpty) return null;
                                final parsed = int.tryParse(text);
                                if (parsed == null ||
                                    parsed < 1 ||
                                    parsed > 31) {
                                  return 'Ingresa un día entre 1 y 31';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          label:
                              _isEditing ? 'Guardar cambios' : 'Crear servicio',
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
      ),
    );
  }
}
