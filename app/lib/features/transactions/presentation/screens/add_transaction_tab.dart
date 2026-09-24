import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/view_models/account_view_model.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../data/models/receipt_scan_result.dart';
import '../../data/services/receipt_scan_service.dart';
import '../view_models/transaction_view_model.dart';

/// Contenido de la pestaña "Añadir ingreso" / "Añadir gasto". No tiene
/// Scaffold propio — se muestra dentro de un RoutedScreenScaffold, debajo
/// del header y encima del bottomNavigationBar que pone AppShellScreen. Se
/// llega acá desde "Acciones rápidas" en el Dashboard.
///
/// [type]: 'income' o 'expense'. Fija el tipo de transacción que se va a
/// crear; no hay selector de tipo en el formulario a propósito, porque se
/// llega acá desde el botón correspondiente.
///
/// La categoría es opcional (tanto en ingresos como en gastos): si no se
/// elige ninguna, el movimiento se guarda con `category_id` nulo y en el
/// resto de la app figura como "Sin categoría".
class AddTransactionTab extends StatefulWidget {
  final String type;
  final String userId;
  final AccountViewModel accountViewModel;
  final CategoryViewModel categoryViewModel;
  final TransactionViewModel transactionViewModel;

  /// Se llama tras guardar con éxito, o al cancelar, para volver a "Inicio".
  final VoidCallback onDone;

  const AddTransactionTab({
    super.key,
    required this.type,
    required this.userId,
    required this.accountViewModel,
    required this.categoryViewModel,
    required this.transactionViewModel,
    required this.onDone,
  });

  @override
  State<AddTransactionTab> createState() => _AddTransactionTabState();
}

class _AddTransactionTabState extends State<AddTransactionTab> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  Category? _selectedCategory;
  Account? _selectedAccount;
  DateTime _selectedDate = DateTime.now();

  // POC (branch gemini-image-reader): precompletar el form a partir de
  // una foto del ticket/factura, vía Edge Function + Gemini (tier
  // gratuito). El usuario siempre revisa/corrige antes de guardar.
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
    // Re-build cuando cambia isSubmitting/errorMessage — sin esto, el
    // spinner del botón y la barra de progreso no se ven, porque nada
    // más dispara un setState mientras se está guardando.
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
      // El saldo de la cuenta se actualizó en el servidor junto con la
      // transacción (RPC create_transaction); acá solo recargamos la
      // lista de cuentas para que el nuevo saldo se vea en pantalla.
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

      // El usuario confirma o descarta lo que devolvió la API antes de que
      // toque el formulario — así el escaneo nunca completa campos sin que
      // la persona vea primero qué se detectó.
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

  /// Muestra en un modal los datos que devolvió la API de escaneo, sin
  /// tocar todavía el formulario. Devuelve `true` si la persona confirma
  /// (y entonces corresponde precompletar el form) o `false`/`null` si
  /// cancela (se descarta el resultado y el form queda como estaba).
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
              result.date != null
                  ? _formatDate(result.date!)
                  : 'No detectada',
            ),
            const SizedBox(height: 12),
            const Text(
              'Podés confirmarlos para precompletar el formulario, o '
              'cancelar y cargarlos a mano.',
              style: TextStyle(color: AppColors.authTextSecondary, fontSize: 12),
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
        content: Text('Datos aplicados al formulario — revisalos antes de guardar.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.categoryViewModel.byType(widget.type);
    final accounts = widget.accountViewModel.activeAccounts;
    final isSubmitting = widget.transactionViewModel.isSubmitting;
    // Cubre tanto el guardado como el escaneo de ticket: mientras cualquiera
    // de los dos está en curso, el resto del form queda bloqueado.
    final isBusy = isSubmitting || _isScanning;

    return SafeArea(
      top: false,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Barra de progreso fina arriba mientras se guarda.
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
                        onTap: isBusy ? null : widget.onDone,
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.arrow_back_rounded,
                              color: AppColors.authTextPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isIncome ? 'Añadir ingreso' : 'Añadir gasto',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.authTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed:
                          isSubmitting || _isScanning ? null : _scanReceipt,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.authTextPrimary,
                        side: const BorderSide(color: AppColors.authCardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      // Mientras escanea, el child pasa a ser únicamente el
                      // spinner (mismo criterio que el botón de Guardar),
                      // así queda centrado en el botón en vez de correrse
                      // hacia la izquierda por ir en Row junto al texto.
                      child: _isScanning
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.authTextPrimary,
                              ),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.document_scanner_rounded),
                                SizedBox(width: 8),
                                Text('Escanear ticket (POC)'),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
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
                      // DropdownButtonFormField no pinta su placeholder
                      // desde decoration.hintText/hintStyle — lo hace a
                      // través de este parámetro. Por eso el color se fija
                      // acá y no en la decoration (mismo criterio que en
                      // NewServiceForm).
                      hint: const Text(
                        'Sin categoría',
                        style: TextStyle(color: AppColors.authTextSecondary),
                      ),
                      // El primer ítem (value nulo) permite volver a "sin
                      // categoría" después de haber elegido una. Sin
                      // validator: la categoría no es obligatoria.
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
