import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/view_models/account_view_model.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../data/models/receipt_scan_result.dart';
import '../../data/services/receipt_scan_service.dart';
import '../view_models/transaction_view_model.dart';

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

  /// Called after saving or cancelling.
  final VoidCallback onDone;

  const TransactionFormScreen({
    super.key,
    required this.type,
    required this.userId,
    required this.accountViewModel,
    required this.categoryViewModel,
    required this.transactionViewModel,
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
  DateTime _selectedDate = DateTime.now();

  _EntryMode _mode = _EntryMode.selecting;

  // POC: prefill the form from a receipt photo; the user reviews it before
  // saving.
  final _receiptScanService = ReceiptScanService(Supabase.instance.client);
  bool _isScanning = false;

  bool get _isIncome => widget.type == 'income';
  Color get _accentColor =>
      _isIncome ? AppColors.authIncome : AppColors.authExpense;

  static const _labelStyle = TextStyle(color: AppColors.authTextSecondary);

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
    // Rebuild on isSubmitting/errorMessage changes.
    widget.transactionViewModel.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.transactionViewModel.removeListener(_onViewModelChanged);
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.transactionViewModel.errorMessage ??
                'No se pudo guardar la transacción.',
          ),
        ),
      );
    }
  }

  Future<ImageSource?> _pickImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.authBackgroundBottom,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded,
                  color: AppColors.authTextPrimary),
              title: const Text('Sacar foto',
                  style: TextStyle(color: AppColors.authTextPrimary)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppColors.authTextPrimary),
              title: const Text('Elegir de la galería',
                  style: TextStyle(color: AppColors.authTextPrimary)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanReceipt() async {
    final source = await _pickImageSource();
    if (source == null || !mounted) return;

    final XFile? picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _isScanning = true);
    try {
      final bytes = await picked.readAsBytes();
      final result = await _receiptScanService.scan(
        imageBytes: bytes,
        mimeType: picked.mimeType ?? 'image/jpeg',
      );
      if (!mounted) return;

      // Stop the scan spinner while the result dialog is open.
      setState(() => _isScanning = false);

      // The user confirms the detected data before it touches the form.
      final confirmed = await _showScanResultDialog(result);
      if (confirmed == true && mounted) {
        _applyScanResult(result);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Servicio no disponible. Intente más tarde o consulte a su '
            'administrador.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  /// Shows the scan result in a dialog. Returns true if the user confirms.
  Future<bool?> _showScanResultDialog(ReceiptScanResult result) {
    final currency = widget.accountViewModel.primaryCurrency;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.authBackgroundTop,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.authCardBorder),
        ),
        title: const Text(
          'Datos leídos del ticket',
          style: TextStyle(
            color: AppColors.authTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _scanResultRow(
              'Monto',
              result.amount != null
                  ? formatCurrency(result.amount!, currency)
                  : 'No detectado',
            ),
            _scanResultRow(
              'Descripción',
              result.description ?? 'No detectada',
            ),
            _scanResultRow(
              'Fecha',
              result.date != null ? _formatDate(result.date!) : 'No detectada',
            ),
            const SizedBox(height: 12),
            const Text(
              'Podés confirmarlos para precompletar el formulario, o '
              'cancelar y volver a elegir cómo cargar el movimiento.',
              style:
                  TextStyle(color: AppColors.authTextSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.authTextSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Confirmar',
              style: TextStyle(
                color: _accentColor,
                fontWeight: FontWeight.w700,
              ),
            ),
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
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
      if (result.date != null && !result.date!.isAfter(DateTime.now())) {
        _selectedDate = result.date!;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Datos aplicados al formulario — revisalos antes de guardar.'),
      ),
    );
  }

  bool get _hasFormData =>
      _amountController.text.trim().isNotEmpty ||
      _descriptionController.text.trim().isNotEmpty ||
      _selectedCategory != null ||
      _selectedAccount != null ||
      !DateUtils.isSameDay(_selectedDate, DateTime.now());

  void _resetForm() {
    setState(() {
      _amountController.clear();
      _descriptionController.clear();
      _selectedCategory = null;
      _selectedAccount = null;
      _selectedDate = DateTime.now();
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
        backgroundColor: AppColors.authBackgroundTop,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.authCardBorder),
        ),
        title: const Text(
          '¿Volver a la selección?',
          style: TextStyle(
            color: AppColors.authTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Se van a perder los datos cargados en el formulario.',
          style: TextStyle(color: AppColors.authTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Seguir editando',
              style: TextStyle(color: AppColors.authTextSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Volver',
              style: TextStyle(
                color: _accentColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    return result == true;
  }

  String get _title => _isIncome ? 'Añadir ingreso' : 'Añadir gasto';

  @override
  Widget build(BuildContext context) {
    // Saving and scanning both lock the screen.
    final isBusy = widget.transactionViewModel.isSubmitting || _isScanning;

    return _mode == _EntryMode.selecting
        ? _buildModeSelector(isBusy)
        : _buildForm(isBusy);
  }

  Widget _buildModeSelector(bool isBusy) {
    return SafeArea(
      top: false,
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
          _EntryModeCard(
            icon: Icons.document_scanner_rounded,
            title: 'Escanear ticket (POC)',
            subtitle: 'Tomá una foto del ticket y extraemos la información '
                'automáticamente.',
            highlighted: true,
            loading: _isScanning,
            onTap: isBusy ? null : _scanReceipt,
          ),
          const SizedBox(height: 12),
          _EntryModeCard(
            icon: Icons.article_outlined,
            title: 'Completar manualmente',
            subtitle: 'Ingresá los datos del movimiento uno por uno.',
            onTap:
                isBusy ? null : () => setState(() => _mode = _EntryMode.form),
          ),
        ],
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
                    title: _title,
                    subtitle: 'Completa los datos del '
                        '${_isIncome ? 'ingreso' : 'gasto'}.',
                    size: ScreenHeaderSize.compact,
                    onBack: _handleFormBack,
                    backEnabled: !isBusy,
                  ),
                  const SizedBox(height: 16),
                  const Text('Monto', style: _labelStyle),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    enabled: !isBusy,
                    style: const TextStyle(color: AppColors.authTextPrimary),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: _fieldDecoration.copyWith(hintText: '0.00'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa un monto';
                      }
                      final parsed =
                          double.tryParse(value.replaceAll(',', '.'));
                      if (parsed == null || parsed <= 0) {
                        return 'Monto inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Categoría (opcional)', style: _labelStyle),
                  const SizedBox(height: 8),
                  if (widget.categoryViewModel.isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.authAccent),
                    )
                  else if (categories.isEmpty)
                    Text(
                      _isIncome
                          ? 'No hay categorías de ingreso todavía. '
                              'Se guardará sin categoría.'
                          : 'No hay categorías de gasto todavía. '
                              'Se guardará sin categoría.',
                      style:
                          const TextStyle(color: AppColors.authTextSecondary),
                    )
                  else
                    DropdownButtonFormField<Category>(
                      initialValue: _selectedCategory,
                      dropdownColor: AppColors.authBackgroundBottom,
                      style: const TextStyle(color: AppColors.authTextPrimary),
                      decoration: _fieldDecoration,
                      // DropdownButtonFormField paints its placeholder through this parameter,
                      // not through decoration.hintStyle.
                      hint: const Text(
                        'Sin categoría',
                        style: TextStyle(color: AppColors.authTextSecondary),
                      ),
                      // The null item lets the user go back to no category.
                      items: [
                        const DropdownMenuItem<Category>(
                          value: null,
                          child: Text(
                            'Sin categoría',
                            style:
                                TextStyle(color: AppColors.authTextSecondary),
                          ),
                        ),
                        ...categories.map(
                          (c) => DropdownMenuItem<Category>(
                            value: c,
                            child: Text(c.name),
                          ),
                        ),
                      ],
                      onChanged: isBusy
                          ? null
                          : (value) =>
                              setState(() => _selectedCategory = value),
                    ),
                  const SizedBox(height: 20),
                  const Text('Cuenta', style: _labelStyle),
                  const SizedBox(height: 8),
                  if (widget.accountViewModel.isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.authAccent),
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
                      style: const TextStyle(color: AppColors.authTextPrimary),
                      decoration: _fieldDecoration,
                      hint: const Text(
                        'Seleccioná una cuenta',
                        style: TextStyle(color: AppColors.authTextSecondary),
                      ),
                      items: accounts
                          .map((a) => DropdownMenuItem(
                                value: a,
                                child: Text(
                                  '${a.name} - ${formatCurrency(a.balance, widget.accountViewModel.primaryCurrency)}',
                                ),
                              ))
                          .toList(),
                      onChanged: isBusy
                          ? null
                          : (value) => setState(() => _selectedAccount = value),
                      validator: (value) =>
                          value == null ? 'Seleccioná una cuenta' : null,
                    ),
                  const SizedBox(height: 20),
                  const Text('Descripción (opcional)', style: _labelStyle),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    enabled: !isBusy,
                    style: const TextStyle(color: AppColors.authTextPrimary),
                    decoration:
                        _fieldDecoration.copyWith(hintText: 'Ej: Mercadona'),
                  ),
                  const SizedBox(height: 20),
                  const Text('Fecha', style: _labelStyle),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: isBusy ? null : _pickDate,
                    borderRadius: BorderRadius.circular(14),
                    child: InputDecorator(
                      decoration: _fieldDecoration,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_selectedDate.day.toString().padLeft(2, '0')}/'
                            '${_selectedDate.month.toString().padLeft(2, '0')}/'
                            '${_selectedDate.year}',
                            style: const TextStyle(
                                color: AppColors.authTextPrimary),
                          ),
                          const Icon(Icons.calendar_today_rounded,
                              size: 18, color: AppColors.authTextSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: AppColors.authBackgroundBottom,
                        disabledBackgroundColor:
                            _accentColor.withValues(alpha: 0.6),
                        disabledForegroundColor: AppColors.authBackgroundBottom
                            .withValues(alpha: 0.6),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: isBusy ||
                              widget.categoryViewModel.isLoading ||
                              accounts.isEmpty
                          ? null
                          : _submit,
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
                              _isIncome ? 'Guardar ingreso' : 'Guardar gasto'),
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

class _EntryModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool highlighted;
  final bool loading;
  final VoidCallback? onTap;

  const _EntryModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final fill = highlighted
        ? Color.alphaBlend(
            AppColors.authAccent.withValues(alpha: 0.12),
            AppColors.authCardFill,
          )
        : AppColors.authCardFill;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: highlighted ? AppColors.authAccent : AppColors.authCardBorder,
        width: highlighted ? 1.5 : 1,
      ),
    );

    return Material(
      color: fill,
      shape: shape,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.authAccent.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, size: 32, color: AppColors.authTextPrimary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.authTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.authTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.authAccent,
                      ),
                    )
                  : const Icon(Icons.chevron_right_rounded,
                      color: AppColors.authAccent),
            ],
          ),
        ),
      ),
    );
  }
}
