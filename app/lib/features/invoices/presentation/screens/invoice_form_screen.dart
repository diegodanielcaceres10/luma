import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/app_clock.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/screen_header.dart';
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
          content: Text(
            isDuplicate
                ? 'Ya existe una factura de ese servicio para ese mes.'
                : 'Ocurrió un error al guardar. Intentá de nuevo.',
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  ScreenHeader(
                    title: _isEditing ? 'Editar factura' : 'Nueva factura',
                    size: ScreenHeaderSize.compact,
                    onBack: widget.onDone,
                    backEnabled: !isSubmitting,
                  ),
                  const SizedBox(height: 20),
                  const Text('Servicio',
                      style: TextStyle(color: AppColors.authTextSecondary)),
                  const SizedBox(height: 8),
                  if (services.isEmpty)
                    const Text(
                      'No hay servicios activos todavía.',
                      style: TextStyle(color: AppColors.authExpense),
                    )
                  else
                    DropdownButtonFormField<String?>(
                      initialValue: _selectedServiceId,
                      dropdownColor: AppColors.authBackgroundBottom,
                      style: const TextStyle(color: AppColors.authTextPrimary),
                      // DropdownButtonFormField ignores decoration.hintText /
                      // hintStyle for its placeholder, so the color is set
                      // here instead.
                      hint: const Text(
                        'Seleccioná un servicio',
                        style: TextStyle(color: AppColors.authTextSecondary),
                      ),
                      decoration: _fieldDecoration,
                      items: services
                          .map(
                            (Service s) => DropdownMenuItem<String?>(
                              value: s.id,
                              child: Text(s.name),
                            ),
                          )
                          .toList(),
                      onChanged: isSubmitting
                          ? null
                          : (value) {
                              setState(() {
                                _selectedServiceId = value;
                                // Prefill the service's approximate amount
                                // only if the field is still empty, to not
                                // overwrite what the user typed.
                                if (_amountController.text.trim().isEmpty) {
                                  final service = services.firstWhere(
                                    (s) => s.id == value,
                                  );
                                  _amountController.text = service
                                      .approximateAmount
                                      .toStringAsFixed(2);
                                }
                              });
                            },
                      validator: (value) =>
                          value == null ? 'Seleccioná un servicio' : null,
                    ),
                  const SizedBox(height: 20),
                  const Text('Mes',
                      style: TextStyle(color: AppColors.authTextSecondary)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    initialValue: _selectedMonth,
                    dropdownColor: AppColors.authBackgroundBottom,
                    style: const TextStyle(color: AppColors.authTextPrimary),
                    decoration: _fieldDecoration,
                    hint: const Text(
                      'Seleccioná un mes',
                      style: TextStyle(color: AppColors.authTextSecondary),
                    ),
                    items: List.generate(12, (i) => i + 1)
                        .map(
                          (month) => DropdownMenuItem<int?>(
                            value: month,
                            child: Text(kMonthNames[month - 1]),
                          ),
                        )
                        .toList(),
                    onChanged: isSubmitting
                        ? null
                        : (value) => setState(() => _selectedMonth = value),
                    validator: (value) =>
                        value == null ? 'Seleccioná un mes' : null,
                  ),
                  const SizedBox(height: 20),
                  const Text('Año',
                      style: TextStyle(color: AppColors.authTextSecondary)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _yearController,
                    enabled: !isSubmitting,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.authTextPrimary),
                    decoration: _fieldDecoration.copyWith(hintText: '2026'),
                    validator: (value) {
                      final parsed = int.tryParse((value ?? '').trim());
                      return parsed == null || parsed < 2000
                          ? 'Ingresa un año válido'
                          : null;
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Monto',
                      style: TextStyle(color: AppColors.authTextSecondary)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    enabled: !isSubmitting,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: AppColors.authTextPrimary),
                    decoration: _fieldDecoration.copyWith(hintText: '0.00'),
                    validator: (value) {
                      final parsed = double.tryParse((value ?? '').trim());
                      return parsed == null || parsed <= 0
                          ? 'Ingresa un monto válido'
                          : null;
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Fecha de vencimiento (opcional)',
                      style: TextStyle(color: AppColors.authTextSecondary)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: isSubmitting ? null : _pickDueDate,
                    borderRadius: BorderRadius.circular(14),
                    child: InputDecorator(
                      decoration: _fieldDecoration.copyWith(
                        hintText: 'Sin vencimiento',
                        suffixIcon: _dueDate == null
                            ? const Icon(Icons.calendar_today_rounded,
                                size: 18, color: AppColors.authTextSecondary)
                            : IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    size: 18,
                                    color: AppColors.authTextSecondary),
                                onPressed: isSubmitting
                                    ? null
                                    : () => setState(() => _dueDate = null),
                              ),
                      ),
                      isEmpty: _dueDate == null,
                      child: _dueDate == null
                          ? null
                          : Text(
                              formatDate(_dueDate!),
                              style: const TextStyle(
                                  color: AppColors.authTextPrimary),
                            ),
                    ),
                  ),
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
                      onPressed:
                          (isSubmitting || services.isEmpty) ? null : _submit,
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
                              : 'Crear factura'),
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
