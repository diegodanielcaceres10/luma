import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/app_clock.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/utils/image_crop_picker.dart';
import '../../../../core/widgets/dialogs/ai_image_source_sheet.dart';
import '../../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../../core/widgets/inputs/input_text_field.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/layout/screen_header.dart';
import '../../../../core/widgets/buttons/text_action_button.dart';
import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/view_models/account_view_model.dart';
import '../../../accounts/presentation/view_models/monthly_balance_view_model.dart';
import '../../../accounts/presentation/widgets/opening_balance_gate.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../data/models/receipt_scan_result.dart';
import '../../data/services/receipt_scan_service.dart';
import '../view_models/transaction_view_model.dart';
import '../widgets/entry_mode_card.dart';

enum _EntryMode { selecting, form }

/// Form to add an income or an expense, shown inside a
/// [RoutedScreenScaffold]. [type] is 'income' or 'expense'; category is
/// optional.
class TransactionFormScreen extends StatefulWidget {
  final String type;
  final String userId;
  final AccountViewModel accountViewModel;
  final CategoryViewModel categoryViewModel;
  final TransactionViewModel transactionViewModel;
  final MonthlyBalanceViewModel monthlyBalanceViewModel;

  /// Called after saving or cancelling.
  final VoidCallback onDone;

  const TransactionFormScreen({
    super.key,
    required this.type,
    required this.userId,
    required this.accountViewModel,
    required this.categoryViewModel,
    required this.transactionViewModel,
    required this.monthlyBalanceViewModel,
    required this.onDone,
  });

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  Category? _selectedCategory;
  Account? _selectedAccount;
  DateTime _selectedDate = nowLocal();

  _EntryMode _mode = _EntryMode.selecting;

  // FEAT: prefill the form from a receipt photo; the user reviews it before
  // saving.
  final _receiptScanService = ReceiptScanService(Supabase.instance.client);

  bool get _isIncome => widget.type == 'income';
  Color get _accentColor =>
      _isIncome ? AppColors.authIncome : AppColors.authExpense;

  static const _labelStyle = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: AppColors.authTextSecondary,
  );

  @override
  void initState() {
    super.initState();
    // Rebuild on isSubmitting/errorMessage changes.
    widget.transactionViewModel.addListener(_onViewModelChanged);
    widget.monthlyBalanceViewModel.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.transactionViewModel.removeListener(_onViewModelChanged);
    widget.monthlyBalanceViewModel.removeListener(_onViewModelChanged);
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showFloatingSnackBar(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
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
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: isError ? AppColors.error : AppColors.authAccent,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: nowLocal(),
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
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccount == null) return;

    final confirmed = await showConfirmDialog(context);
    if (!confirmed || !mounted) return;

    final amount = double.parse(_amountController.text.replaceAll(',', '.'));

    final success = await widget.transactionViewModel.createTransaction(
      userId: widget.userId,
      accountId: _selectedAccount!.id,
      categoryId: _selectedCategory?.id,
      type: widget.type,
      amount: amount,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      date: _selectedDate,
    );

    if (!mounted) return;

    if (success) {
      // Balance changed server-side; reload accounts to show it.
      await widget.accountViewModel.loadAccounts();
      if (!mounted) return;
      widget.onDone();
    } else {
      _showFloatingSnackBar(
        widget.transactionViewModel.errorMessage ??
            'No se pudo guardar la transacción.',
        isError: true,
      );
    }
  }

  Future<void> _scanReceipt() async {
    final source = await showAiImageSourceSheet(
      context,
      title: 'Escanear un ticket',
    );
    if (source == null || !mounted) return;

    // The scan runs inside the crop preview, which stays open (and offers a
    // retry) until the service answers.
    final result = await pickAndCropImage<ReceiptScanResult>(
      context,
      source,
      process: (image, report) => _receiptScanService.scan(
        imageBytes: image.bytes,
        mimeType: image.mimeType,
        onStage: report,
      ),
    );
    if (result == null || !mounted) return;

    // The user confirms the detected data before it touches the form.
    final confirmed = await _showScanResultDialog(result);
    if (confirmed == true && mounted) {
      _applyScanResult(result);
    }
  }

  /// Shows the scan result in a dialog. Returns true if the user confirms.
  Future<bool?> _showScanResultDialog(ReceiptScanResult result) {
    final currency = widget.accountViewModel.primaryCurrency;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.authBackgroundBottom,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.authCardBorder),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.authAccent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.authAccent.withValues(alpha: 0.30),
                    ),
                  ),
                  child: const Icon(
                    Icons.document_scanner_rounded,
                    size: 20,
                    color: AppColors.authAccent,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Datos leídos del ticket',
                    style: TextStyle(
                      color: AppColors.authTextPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.authCardFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.authCardBorder.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                children: [
                  _scanResultRow(
                    'Monto',
                    result.amount != null
                        ? formatCurrency(result.amount!, currency)
                        : 'No detectado',
                  ),
                  const Divider(
                    height: 12,
                    color: AppColors.authCardBorder,
                  ),
                  _scanResultRow(
                    'Descripción',
                    result.description ?? 'No detectada',
                  ),
                  const Divider(
                    height: 12,
                    color: AppColors.authCardBorder,
                  ),
                  _scanResultRow(
                    'Fecha',
                    result.date != null
                        ? formatDate(result.date!)
                        : 'No detectada',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Podés confirmarlos para precompletar el formulario, o '
              'cancelar y volver a elegir cómo cargar el movimiento.',
              style: TextStyle(
                color: AppColors.authTextSecondary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextActionButton(
            label: 'Cancelar',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          TextActionButton(
            label: 'Confirmar',
            color: _accentColor,
            fontWeight: FontWeight.w700,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
  }

  Widget _scanResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 92, child: Text(label, style: _labelStyle)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.authTextPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _applyScanResult(ReceiptScanResult result) {
    setState(() {
      _mode = _EntryMode.form;
      if (result.amount != null && result.amount! > 0) {
        _amountController.text = result.amount!.toStringAsFixed(2);
      }
      if (result.description != null) {
        _descriptionController.text = result.description!;
      }
      if (result.date != null && !result.date!.isAfter(nowLocal())) {
        _selectedDate = result.date!;
      }
    });

    _showFloatingSnackBar(
      'Datos aplicados al formulario — revisalos antes de guardar.',
    );
  }

  bool get _hasFormData =>
      _amountController.text.trim().isNotEmpty ||
      _descriptionController.text.trim().isNotEmpty ||
      _selectedCategory != null ||
      _selectedAccount != null ||
      !DateUtils.isSameDay(_selectedDate, nowLocal());

  void _resetForm() {
    setState(() {
      _amountController.clear();
      _descriptionController.clear();
      _selectedCategory = null;
      _selectedAccount = null;
      _selectedDate = nowLocal();
      _mode = _EntryMode.selecting;
    });
  }

  /// Goes back to the mode selector, asking for confirmation if data was
  /// entered.
  Future<void> _handleFormBack() async {
    if (_hasFormData) {
      final discard = await _confirmDiscardForm();
      if (!discard || !mounted) return;
    }
    _resetForm();
  }

  Future<bool> _confirmDiscardForm() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.authBackgroundBottom,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.authCardBorder),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.authExpense.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.authExpense.withValues(alpha: 0.30),
                    ),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: AppColors.authExpense,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '¿Volver a la selección?',
                    style: TextStyle(
                      color: AppColors.authTextPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Se van a perder los datos cargados en el formulario.',
              style: TextStyle(
                color: AppColors.authTextSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextActionButton(
            label: 'Seguir editando',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          TextActionButton(
            label: 'Volver',
            color: _accentColor,
            fontWeight: FontWeight.w700,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    return result == true;
  }

  String get _title => _isIncome ? 'Añadir ingreso' : 'Añadir gasto';

  @override
  Widget build(BuildContext context) {
    // Saving locks the screen; scanning is locked by its own dialog.
    final isBusy = widget.transactionViewModel.isSubmitting;

    return _mode == _EntryMode.selecting
        ? _buildModeSelector(isBusy)
        : _buildForm(isBusy);
  }

  Widget _buildModeSelector(bool isBusy) {
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              ScreenHeader(
                title: _title,
                subtitle: 'Elige cómo quieres registrar tu '
                    '${_isIncome ? 'ingreso' : 'gasto'}.',
                onBack: widget.onDone,
                backEnabled: !isBusy,
              ),
              const SizedBox(height: 16),
              EntryModeOptions(
                cards: [
                  EntryModeCard(
                    icon: Icons.document_scanner_rounded,
                    title: 'Escanear ticket',
                    subtitle:
                        'Tomá una foto del ticket y extraemos la información '
                        'automáticamente.',
                    highlighted: true,
                    onTap: isBusy ? null : _scanReceipt,
                  ),
                  EntryModeCard(
                    icon: Icons.article_outlined,
                    title: 'Completar manualmente',
                    subtitle: 'Ingresá los datos del movimiento uno por uno.',
                    onTap: isBusy
                        ? null
                        : () => setState(() => _mode = _EntryMode.form),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(bool isBusy) {
    final categories = widget.categoryViewModel.byType(widget.type);
    final accounts = widget.accountViewModel.activeAccounts;
    final isSubmitting = widget.transactionViewModel.isSubmitting;

    return SafeArea(
      top: false,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (isSubmitting)
              LinearProgressIndicator(
                backgroundColor: AppColors.authCardBorder,
                color: _accentColor,
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
                        title: _title,
                        subtitle: 'Completa los datos del '
                            '${_isIncome ? 'ingreso' : 'gasto'}.',
                        size: ScreenHeaderSize.compact,
                        onBack: _handleFormBack,
                        backEnabled: !isBusy,
                      ),
                      const SizedBox(height: 20),
                      // Tarjeta 1: Importe y clasificación
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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: _accentColor
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _accentColor
                                          .withValues(alpha: 0.30),
                                    ),
                                  ),
                                  child: Icon(
                                    _isIncome
                                        ? Icons.arrow_downward_rounded
                                        : Icons.arrow_upward_rounded,
                                    size: 20,
                                    color: _accentColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Importe y clasificación',
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
                                    color: _accentColor
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _accentColor
                                          .withValues(alpha: 0.28),
                                    ),
                                  ),
                                  child: Text(
                                    _isIncome ? 'Ingreso' : 'Gasto',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: _accentColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            InputTextField(
                              controller: _amountController,
                              label: 'Monto',
                              hintText: '0.00',
                              enabled: !isBusy,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingresa un monto';
                                }
                                final parsed = double.tryParse(
                                  value.replaceAll(',', '.'),
                                );
                                if (parsed == null || parsed <= 0) {
                                  return 'Monto inválido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            const Text('Categoría (opcional)',
                                style: _labelStyle),
                            const SizedBox(height: 8),
                            if (widget.categoryViewModel.isLoading)
                              const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.authAccent,
                                ),
                              )
                            else if (categories.isEmpty)
                              Text(
                                _isIncome
                                    ? 'No hay categorías de ingreso todavía. '
                                        'Se guardará sin categoría.'
                                    : 'No hay categorías de gasto todavía. '
                                        'Se guardará sin categoría.',
                                style: const TextStyle(
                                  color: AppColors.authTextSecondary,
                                ),
                              )
                            else
                              DropdownButtonFormField<Category>(
                                initialValue: _selectedCategory,
                                dropdownColor: AppColors.authBackgroundBottom,
                                style: const TextStyle(
                                  color: AppColors.authTextPrimary,
                                ),
                                decoration: InputTextField.formDecoration,
                                hint: const Text(
                                  'Sin categoría',
                                  style: TextStyle(
                                    color: AppColors.authTextSecondary,
                                  ),
                                ),
                                items: [
                                  DropdownMenuItem<Category>(
                                    value: null,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color:
                                                  AppColors.authTextSecondary,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Sin categoría',
                                          style: TextStyle(
                                            color: AppColors.authTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ...categories.map(
                                    (c) => DropdownMenuItem<Category>(
                                      value: c,
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
                                                fallback:
                                                    AppColors.authTextFooter,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(c.name),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: isBusy
                                    ? null
                                    : (value) => setState(
                                        () => _selectedCategory = value),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Tarjeta 2: Cuenta y detalles
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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                    Icons.account_balance_wallet_outlined,
                                    size: 20,
                                    color: AppColors.authAccent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Cuenta y detalles',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.authTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text('Cuenta', style: _labelStyle),
                            const SizedBox(height: 8),
                            if (widget.accountViewModel.isLoading)
                              const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.authAccent,
                                ),
                              )
                            else if (accounts.isEmpty)
                              const Text(
                                'No hay cuentas todavía.',
                                style: TextStyle(color: AppColors.authExpense),
                              )
                            else
                              DropdownButtonFormField<Account>(
                                initialValue: _selectedAccount,
                                dropdownColor: AppColors.authBackgroundBottom,
                                style: const TextStyle(
                                  color: AppColors.authTextPrimary,
                                ),
                                decoration: InputTextField.formDecoration,
                                hint: const Text(
                                  'Seleccioná una cuenta',
                                  style: TextStyle(
                                    color: AppColors.authTextSecondary,
                                  ),
                                ),
                                items: accounts.map((a) {
                                  final isPending = widget
                                      .monthlyBalanceViewModel
                                      .isAccountPending(a.id);
                                  return DropdownMenuItem(
                                    value: a,
                                    enabled: !isPending,
                                    child: accountOptionLabel(
                                      '${a.name} - ${formatCurrency(a.balance, widget.accountViewModel.primaryCurrency)}',
                                      isPending: isPending,
                                    ),
                                  );
                                }).toList(),
                                onChanged: isBusy
                                    ? null
                                    : (value) => setState(
                                        () => _selectedAccount = value),
                                validator: (value) => value == null
                                    ? 'Seleccioná una cuenta'
                                    : null,
                              ),
                            const SizedBox(height: 20),
                            InputTextField(
                              controller: _descriptionController,
                              label: 'Descripción (opcional)',
                              hintText: 'Ej: Mercadona',
                              enabled: !isBusy,
                            ),
                            const SizedBox(height: 20),
                            const Text('Fecha', style: _labelStyle),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: isBusy ? null : _pickDate,
                              borderRadius: BorderRadius.circular(14),
                              child: InputDecorator(
                                decoration: InputTextField.formDecoration,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      formatDate(_selectedDate),
                                      style: const TextStyle(
                                        color: AppColors.authTextPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 18,
                                      color: AppColors.authTextSecondary,
                                    ),
                                  ],
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
                          label: _isIncome
                              ? 'Guardar ingreso'
                              : 'Guardar gasto',
                          backgroundColor: _accentColor,
                          disabledAlpha: 0.6,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          isLoading: isSubmitting,
                          onPressed: isBusy ||
                                  widget.categoryViewModel.isLoading ||
                                  accounts.isEmpty
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
