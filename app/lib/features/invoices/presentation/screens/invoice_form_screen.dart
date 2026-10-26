import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/app_clock.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../../core/widgets/inputs/input_text_field.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/layout/screen_header.dart';
import '../../../services/data/models/service.dart';
import '../../../services/presentation/view_models/service_view_model.dart';
import '../../data/models/invoice.dart';
import '../utils/month_names.dart';
import '../view_models/invoice_view_model.dart';

/// Creates an invoice, or edits it when [invoice] is provided. Paying or
/// cancelling is done from the view screen, and only pending invoices can
/// be edited.
class InvoiceFormScreen extends StatefulWidget {
  final String userId;
  final InvoiceViewModel invoiceViewModel;
  final ServiceViewModel serviceViewModel;
  final Invoice? invoice;

  final VoidCallback onDone;

  const InvoiceFormScreen({
    super.key,
    required this.userId,
    required this.invoiceViewModel,
    required this.serviceViewModel,
    required this.onDone,
    this.invoice,
  });

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  late final TextEditingController _yearController;

  String? _selectedServiceId;
  int? _selectedMonth;
  DateTime? _dueDate;

  bool get _isEditing => widget.invoice != null;

  @override
  void initState() {
    super.initState();
    final invoice = widget.invoice;
    _selectedServiceId = invoice?.serviceId;
    _selectedMonth = invoice?.month;
    _dueDate = invoice?.dueDate;
    _yearController = TextEditingController(
      text: '${invoice?.year ?? nowLocal().year}',
    );
    if (invoice != null) {
      _amountController.text = invoice.amount.toStringAsFixed(2);
    }
    widget.invoiceViewModel.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.invoiceViewModel.removeListener(_onViewModelChanged);
    _amountController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final year =
        int.tryParse(_yearController.text.trim()) ?? nowLocal().year;
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _dueDate ?? DateTime(year, _selectedMonth ?? nowLocal().month),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
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
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMonth == null) return;

    final confirmed = await showConfirmDialog(context);
    if (!confirmed || !mounted) return;

    final vm = widget.invoiceViewModel;
    final amount = double.parse(_amountController.text.trim());
    final year = int.parse(_yearController.text.trim());

    final success = _isEditing
        ? await vm.updateInvoice(
            id: widget.invoice!.id,
            serviceId: _selectedServiceId!,
            month: _selectedMonth!,
            year: year,
            amount: amount,
            dueDate: _dueDate,
          )
        : await vm.createInvoice(
            userId: widget.userId,
            serviceId: _selectedServiceId!,
            month: _selectedMonth!,
            year: year,
            amount: amount,
            dueDate: _dueDate,
          );

    if (!mounted) return;

    if (success) {
      widget.onDone();
    } else {
      final isDuplicate = vm.submitError == InvoiceSubmitError.duplicate;
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
                      ? 'Ya existe una factura de ese servicio para ese mes.'
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
    final isSubmitting = widget.invoiceViewModel.isSubmitting;
    final services = widget.serviceViewModel.activeServices;

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
                        title: _isEditing ? 'Editar factura' : 'Nueva factura',
                        subtitle: _isEditing
                            ? 'Modificá los valores o el vencimiento de la factura.'
                            : 'Emití una factura vinculada a tus servicios recurrentes.',
                        size: ScreenHeaderSize.compact,
                        onBack: widget.onDone,
                        backEnabled: !isSubmitting,
                      ),
                      const SizedBox(height: 20),
                      // Tarjeta 1: Servicio y período
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
                                    'Servicio y período',
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
                                    color: AppColors.authAccent
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.authAccent
                                          .withValues(alpha: 0.28),
                                    ),
                                  ),
                                  child: Text(
                                    _isEditing ? 'Edición' : 'Emisión',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.authAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Servicio',
                              style: TextStyle(
                                color: AppColors.authTextSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (services.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.authExpense
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.authExpense
                                        .withValues(alpha: 0.25),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      size: 20,
                                      color: AppColors.authExpense,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'No hay servicios activos todavía. Registrá un servicio antes de emitir facturas.',
                                        style: TextStyle(
                                          color: AppColors.authExpense,
                                          fontSize: 12.5,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              DropdownButtonFormField<String?>(
                                initialValue: _selectedServiceId,
                                dropdownColor: AppColors.authBackgroundBottom,
                                style: const TextStyle(
                                  color: AppColors.authTextPrimary,
                                ),
                                hint: const Text(
                                  'Seleccioná un servicio',
                                  style: TextStyle(
                                    color: AppColors.authTextSecondary,
                                  ),
                                ),
                                decoration: InputTextField.formDecoration,
                                items: services
                                    .map(
                                      (Service s) => DropdownMenuItem<String?>(
                                        value: s.id,
                                        child: Text(
                                          s.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: isSubmitting
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _selectedServiceId = value;
                                          if (_amountController.text
                                              .trim()
                                              .isEmpty) {
                                            final service = services.firstWhere(
                                              (s) => s.id == value,
                                            );
                                            _amountController.text = service
                                                .approximateAmount
                                                .toStringAsFixed(2);
                                          }
                                        });
                                      },
                                validator: (value) => value == null
                                    ? 'Seleccioná un servicio'
                                    : null,
                              ),
                            const SizedBox(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Mes',
                                        style: TextStyle(
                                          color: AppColors.authTextSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<int?>(
                                        initialValue: _selectedMonth,
                                        dropdownColor:
                                            AppColors.authBackgroundBottom,
                                        style: const TextStyle(
                                          color: AppColors.authTextPrimary,
                                        ),
                                        decoration:
                                            InputTextField.formDecoration,
                                        hint: const Text(
                                          'Seleccioná un mes',
                                          style: TextStyle(
                                            color: AppColors.authTextSecondary,
                                          ),
                                        ),
                                        items: List.generate(12, (i) => i + 1)
                                            .map(
                                              (month) =>
                                                  DropdownMenuItem<int?>(
                                                value: month,
                                                child: Text(
                                                  kMonthNames[month - 1],
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: isSubmitting
                                            ? null
                                            : (value) => setState(
                                                () => _selectedMonth = value),
                                        validator: (value) => value == null
                                            ? 'Seleccioná un mes'
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      InputTextField(
                                        controller: _yearController,
                                        label: 'Año',
                                        hintText: '2026',
                                        enabled: !isSubmitting,
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          final parsed = int.tryParse(
                                            (value ?? '').trim(),
                                          );
                                          return parsed == null || parsed < 2000
                                              ? 'Ingresa un año válido'
                                              : null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Tarjeta 2: Importe y vencimiento
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
                                    Icons.payments_outlined,
                                    size: 20,
                                    color: AppColors.authAccent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Importe y vencimiento',
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
                              label: 'Monto',
                              hintText: '0.00',
                              enabled: !isSubmitting,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: (value) {
                                final parsed =
                                    double.tryParse((value ?? '').trim());
                                return parsed == null || parsed <= 0
                                    ? 'Ingresa un monto válido'
                                    : null;
                              },
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Fecha de vencimiento (opcional)',
                              style: TextStyle(
                                color: AppColors.authTextSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: isSubmitting ? null : _pickDueDate,
                              borderRadius: BorderRadius.circular(14),
                              child: InputDecorator(
                                decoration:
                                    InputTextField.formDecoration.copyWith(
                                  hintText: 'Sin vencimiento',
                                  suffixIcon: _dueDate == null
                                      ? const Icon(
                                          Icons.calendar_today_rounded,
                                          size: 18,
                                          color: AppColors.authTextSecondary,
                                        )
                                      : IconButton(
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            size: 18,
                                            color: AppColors.authTextSecondary,
                                          ),
                                          onPressed: isSubmitting
                                              ? null
                                              : () => setState(
                                                  () => _dueDate = null),
                                        ),
                                ),
                                isEmpty: _dueDate == null,
                                child: _dueDate == null
                                    ? null
                                    : Text(
                                        formatDate(_dueDate!),
                                        style: const TextStyle(
                                          color: AppColors.authTextPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          label:
                              _isEditing ? 'Guardar cambios' : 'Crear factura',
                          disabledAlpha: 0.6,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          isLoading: isSubmitting,
                          onPressed: (isSubmitting || services.isEmpty)
                              ? null
                              : _submit,
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
