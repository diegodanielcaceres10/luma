import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/view_models/account_view_model.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../services/presentation/view_models/service_view_model.dart';
import '../../data/models/invoice.dart';
import '../view_models/invoice_view_model.dart';

enum _StatusFilter { all, pending, paid, cancelled }

/// Contenido de la pestaña "Facturas". No tiene Scaffold propio — vive
/// dentro del Scaffold del HomeShell, que es quien pone el header (con el
/// botón "+" para crear) y el bottomNavigationBar.
///
/// Además de crear facturas, desde acá se puede cancelar una factura
/// pendiente (cerrar su flujo sin pagarla) o registrar su pago: eso crea
/// la transacción de gasto vinculada a la categoría del servicio, con
/// posibilidad de ajustar el monto antes de confirmar.
class InvoicesTab extends StatefulWidget {
  final String userId;
  final InvoiceViewModel invoiceViewModel;
  final ServiceViewModel serviceViewModel;
  final CategoryViewModel categoryViewModel;
  final AccountViewModel accountViewModel;

  /// Si es true, la pestaña arranca con el filtro "Pendientes" ya
  /// aplicado (ej. al entrar desde la quick action "Facturas por pagar"
  /// del Dashboard). Solo se lee una vez, al crear el State — para que
  /// tenga efecto en una pestaña ya montada hace falta forzar un nuevo
  /// State (ver el nonce en HomeShell).
  final bool initialPendingFilter;

  const InvoicesTab({
    super.key,
    required this.userId,
    required this.invoiceViewModel,
    required this.serviceViewModel,
    required this.categoryViewModel,
    required this.accountViewModel,
    this.initialPendingFilter = false,
  });

  @override
  State<InvoicesTab> createState() => _InvoicesTabState();
}

class _InvoicesTabState extends State<InvoicesTab> {
  late _StatusFilter _statusFilter;

  @override
  void initState() {
    super.initState();
    _statusFilter =
        widget.initialPendingFilter ? _StatusFilter.pending : _StatusFilter.all;
  }

  static const _monthNames = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  bool _matchesStatus(Invoice invoice) {
    switch (_statusFilter) {
      case _StatusFilter.all:
        return true;
      case _StatusFilter.pending:
        return invoice.isPending;
      case _StatusFilter.paid:
        return invoice.paid;
      case _StatusFilter.cancelled:
        return invoice.cancelled;
    }
  }

  Future<void> _confirmCancel(BuildContext context, Invoice invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.authBackgroundTop,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.authCardBorder),
        ),
        title: const Text(
          '¿Cancelar factura?',
          style: TextStyle(
            color: AppColors.authTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'La factura quedará marcada como cancelada. Esta acción no se '
          'puede deshacer.',
          style: TextStyle(color: AppColors.authTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Volver',
              style: TextStyle(color: AppColors.authTextSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Cancelar factura',
              style: TextStyle(
                color: AppColors.authExpense,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ok = await widget.invoiceViewModel.cancelInvoice(invoice.id);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.invoiceViewModel.errorMessage ??
                'No se pudo cancelar la factura.',
          ),
        ),
      );
    }
  }

  Future<void> _payInvoice(
    BuildContext context, {
    required Invoice invoice,
    required String serviceName,
    required Category? category,
  }) async {
    if (category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El servicio no tiene categoría o fue eliminado; no se puede '
            'registrar el pago.',
          ),
        ),
      );
      return;
    }

    final accounts = widget.accountViewModel.activeAccounts;
    final result = await showDialog<_PayInvoiceResult>(
      context: context,
      builder: (_) => _PayInvoiceDialog(
        invoice: invoice,
        serviceName: serviceName,
        category: category,
        accounts: accounts,
      ),
    );

    if (result == null) return;

    final ok = await widget.invoiceViewModel.payInvoice(
      invoice: invoice,
      userId: widget.userId,
      accountId: result.accountId,
      categoryId: category.id,
      amount: result.amount,
      description: 'Factura · $serviceName',
    );

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.invoiceViewModel.errorMessage ??
                'No se pudo registrar el pago.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListenableBuilder(
        listenable: Listenable.merge([
          widget.invoiceViewModel,
          widget.serviceViewModel,
          widget.categoryViewModel,
          widget.accountViewModel,
        ]),
        builder: (context, _) {
          if (widget.invoiceViewModel.isLoading &&
              widget.invoiceViewModel.invoices.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.authAccent),
            );
          }

          final allInvoices = widget.invoiceViewModel.invoices;
          final invoices = allInvoices.where(_matchesStatus).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              const Text(
                'Facturas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.authTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _StatusFilterRow(
                value: _statusFilter,
                onChanged: (value) => setState(() => _statusFilter = value),
              ),
              const SizedBox(height: 16),
              if (invoices.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Text(
                    allInvoices.isEmpty
                        ? 'Todavía no hay facturas.\nTocá + para crear la '
                            'primera.'
                        : 'No hay facturas con este filtro.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.authSubtitle,
                  ),
                )
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.authCardFill,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.authCardBorder),
                  ),
                  child: Column(
                    children: List.generate(invoices.length, (i) {
                      final invoice = invoices[i];
                      final service = widget.serviceViewModel
                          .serviceById(invoice.serviceId);
                      final serviceName = service?.name ?? 'Servicio eliminado';
                      final category = widget.categoryViewModel
                          .categoryById(service?.categoryId);
                      return _InvoiceRow(
                        invoice: invoice,
                        serviceName: serviceName,
                        category: category,
                        monthLabel: _monthNames[invoice.month - 1],
                        showDivider: i != invoices.length - 1,
                        isCancelling:
                            widget.invoiceViewModel.isCancelling(invoice.id),
                        isPaying: widget.invoiceViewModel.isPaying(invoice.id),
                        onCancel: () => _confirmCancel(context, invoice),
                        onPay: () => _payInvoice(
                          context,
                          invoice: invoice,
                          serviceName: serviceName,
                          category: category,
                        ),
                      );
                    }),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Filtro rápido por estado de la factura: Todas / Pendientes / Pagadas /
/// Canceladas. Chips que fluyen horizontalmente y saltan de línea al
/// llegar al borde (Wrap), mismo criterio que los filtros de Movimientos.
class _StatusFilterRow extends StatelessWidget {
  final _StatusFilter value;
  final ValueChanged<_StatusFilter> onChanged;

  const _StatusFilterRow({required this.value, required this.onChanged});

  static const _options = [
    (_StatusFilter.all, 'Todas'),
    (_StatusFilter.pending, 'Pendientes'),
    (_StatusFilter.paid, 'Pagadas'),
    (_StatusFilter.cancelled, 'Canceladas'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _options.map((option) {
        final isSelected = option.$1 == value;
        return GestureDetector(
          onTap: () => onChanged(option.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.authAccent.withValues(alpha: 0.18)
                  : AppColors.authCardFill,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected
                    ? AppColors.authAccent
                    : AppColors.authCardBorder,
              ),
            ),
            child: Text(
              option.$2,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.authTextPrimary
                    : AppColors.authTextSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final Invoice invoice;
  final String serviceName;
  final Category? category;
  final String monthLabel;
  final bool showDivider;
  final bool isCancelling;
  final bool isPaying;
  final VoidCallback onCancel;
  final VoidCallback onPay;

  const _InvoiceRow({
    required this.invoice,
    required this.serviceName,
    required this.category,
    required this.monthLabel,
    required this.showDivider,
    required this.isCancelling,
    required this.isPaying,
    required this.onCancel,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = invoice.cancelled
        ? AppColors.authTextFooter
        : invoice.paid
            ? AppColors.authIncome
            : AppColors.authExpense;
    final badgeLabel = invoice.cancelled
        ? 'Cancelada'
        : invoice.paid
            ? 'Pagada'
            : 'Pendiente';

    final dueDate = invoice.dueDate;
    final subtitleParts = <String>[
      '$monthLabel ${invoice.year}',
      formatCurrency(invoice.amount, 'EUR'),
      if (dueDate != null)
        'vence el ${dueDate.day.toString().padLeft(2, '0')}/'
            '${dueDate.month.toString().padLeft(2, '0')}',
    ];

    final isBusy = isCancelling || isPaying;

    return Column(
      children: [
        Opacity(
          opacity: invoice.cancelled ? 0.5 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.authTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitleParts.join(' · '),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.authTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                ),
                if (invoice.isPending) ...[
                  const SizedBox(width: 4),
                  if (isBusy)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.authTextSecondary,
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 18,
                            color: AppColors.authIncome,
                          ),
                          tooltip: 'Registrar pago',
                          onPressed: onPay,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.authTextSecondary,
                          ),
                          tooltip: 'Cancelar factura',
                          onPressed: onCancel,
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: AppColors.authCardBorder),
      ],
    );
  }
}

class _PayInvoiceResult {
  final double amount;
  final String accountId;

  const _PayInvoiceResult({required this.amount, required this.accountId});
}

/// Diálogo de pago de una factura. El monto viene precargado con el
/// importe de la factura pero es editable — puede confirmarse un valor
/// distinto (ej. si el importe real varió respecto al aproximado). La
/// categoría se muestra fija: viene del servicio y no se puede cambiar
/// acá, así que la transacción de gasto siempre queda bien clasificada.
class _PayInvoiceDialog extends StatefulWidget {
  final Invoice invoice;
  final String serviceName;
  final Category category;
  final List<Account> accounts;

  const _PayInvoiceDialog({
    required this.invoice,
    required this.serviceName,
    required this.category,
    required this.accounts,
  });

  @override
  State<_PayInvoiceDialog> createState() => _PayInvoiceDialogState();
}

class _PayInvoiceDialogState extends State<_PayInvoiceDialog> {
  late final TextEditingController _amountController;
  Account? _selectedAccount;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.invoice.amount.toStringAsFixed(2),
    );
    _selectedAccount =
        widget.accounts.isNotEmpty ? widget.accounts.first : null;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _confirm() {
    final amount =
        double.tryParse(_amountController.text.trim().replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      setState(() => _amountError = 'Ingresá un monto válido');
      return;
    }
    if (_selectedAccount == null) return;

    Navigator.of(context).pop(
      _PayInvoiceResult(amount: amount, accountId: _selectedAccount!.id),
    );
  }

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
  Widget build(BuildContext context) {
    final accounts = widget.accounts;

    return AlertDialog(
      backgroundColor: AppColors.authBackgroundTop,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.authCardBorder),
      ),
      title: const Text(
        'Registrar pago',
        style: TextStyle(
          color: AppColors.authTextPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.serviceName} · ${widget.category.name}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.authTextPrimary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Monto a pagar',
              style: TextStyle(color: AppColors.authTextSecondary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.authTextPrimary),
              decoration: _fieldDecoration.copyWith(
                prefixText: '€ ',
                prefixStyle: const TextStyle(color: AppColors.authTextPrimary),
                errorText: _amountError,
                errorStyle: const TextStyle(color: AppColors.authExpense),
              ),
              onChanged: (_) {
                if (_amountError != null) {
                  setState(() => _amountError = null);
                }
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Cuenta con la que se paga',
              style: TextStyle(color: AppColors.authTextSecondary),
            ),
            const SizedBox(height: 8),
            if (accounts.isEmpty)
              const Text(
                'No hay cuentas activas — creá una antes de registrar el '
                'pago.',
                style: TextStyle(color: AppColors.authExpense),
              )
            else
              DropdownButtonFormField<Account>(
                initialValue: _selectedAccount,
                dropdownColor: AppColors.authBackgroundBottom,
                style: const TextStyle(color: AppColors.authTextPrimary),
                decoration: _fieldDecoration,
                items: accounts
                    .map((a) => DropdownMenuItem(value: a, child: Text(a.name)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedAccount = value),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Volver',
            style: TextStyle(color: AppColors.authTextSecondary),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.authAccent,
            foregroundColor: AppColors.authBackgroundBottom,
            disabledBackgroundColor:
                AppColors.authAccent.withValues(alpha: 0.6),
            disabledForegroundColor:
                AppColors.authBackgroundBottom.withValues(alpha: 0.6),
          ),
          onPressed: accounts.isEmpty ? null : _confirm,
          child: const Text('Confirmar pago'),
        ),
      ],
    );
  }
}
