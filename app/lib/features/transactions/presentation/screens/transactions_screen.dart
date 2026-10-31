import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/inputs/filter_chip_row.dart';
import '../../../../core/widgets/inputs/month_filter_button.dart';
import '../../../../core/widgets/layout/screen_header.dart';
import '../../../../core/widgets/buttons/text_action_button.dart';
import '../../../accounts/presentation/view_models/account_view_model.dart';
import '../../../accounts/presentation/widgets/pending_movements/select_pending_invoice_sheet.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../invoices/data/models/invoice.dart';
import '../../../invoices/presentation/view_models/invoice_view_model.dart';
import '../../../services/presentation/view_models/service_view_model.dart';
import '../../data/models/transaction_entry.dart';
import '../view_models/transaction_view_model.dart';
import '../view_models/transactions_filters.dart';
import '../widgets/history/category_filter.dart';
import '../widgets/history/edit_movement_dialog.dart';
import '../widgets/history/history_filter_widgets.dart';
import '../widgets/history/movement_actions_sheet.dart';
import '../widgets/history/movement_row.dart';

/// Filterable transaction history.
class TransactionsScreen extends StatefulWidget {
  final String userId;
  final TransactionViewModel transactionViewModel;
  final AccountViewModel accountViewModel;
  final CategoryViewModel categoryViewModel;
  final InvoiceViewModel invoiceViewModel;
  final ServiceViewModel serviceViewModel;
  final String currency;

  /// Initial filters, read once from the URL query params (`type`, `range`,
  /// `category`, `account`, `month`). Changing a filter pushes a new URL so
  /// each combination gets its own history entry.
  final String? initialType;
  final String? initialRange;
  final String? initialCategory;
  final String? initialAccount;

  /// Month in `YYYY-MM` format; null or invalid falls back to the current
  /// month.
  final String? initialMonth;

  const TransactionsScreen({
    super.key,
    required this.userId,
    required this.transactionViewModel,
    required this.accountViewModel,
    required this.categoryViewModel,
    required this.invoiceViewModel,
    required this.serviceViewModel,
    required this.currency,
    this.initialType,
    this.initialRange,
    this.initialCategory,
    this.initialAccount,
    this.initialMonth,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late TransactionTypeFilter _typeFilter;
  late TransactionDateRangeFilter _dateRange;

  // null means "all". Holds category.id/account.id, or the name if there is
  // no id.
  late String? _categoryKey;
  late String? _accountKey;

  // Selected calendar month; defaults to the current month.
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _typeFilter = TransactionsFilters.typeFromQuery(widget.initialType);
    _dateRange = TransactionsFilters.rangeFromQuery(widget.initialRange);
    _categoryKey = widget.initialCategory;
    _accountKey = widget.initialAccount;
    _selectedMonth = TransactionsFilters.monthFromQuery(widget.initialMonth);
    // Load after the first frame: loadAllTransactions notifies listeners
    // synchronously, which would happen during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.transactionViewModel.loadAllTransactions();
    });
  }

  /// Relative date ranges only apply to the current month; in other months
  /// the "Período" filter is hidden and ignored.
  TransactionDateRangeFilter get _effectiveDateRange =>
      TransactionsFilters.isCurrentMonth(_selectedMonth)
          ? _dateRange
          : TransactionDateRangeFilter.all;

  /// Pushes a URL with the combined filters; see
  /// [TransactionsScreen.initialType].
  void _pushFilters({
    required TransactionTypeFilter type,
    required TransactionDateRangeFilter range,
    required String? categoryKey,
    required String? accountKey,
    required DateTime month,
  }) {
    final params = <String, String>{};
    final typeValue = TransactionsFilters.typeQueryValue(type);
    if (typeValue != null) params['type'] = typeValue;
    final rangeValue = TransactionsFilters.rangeQueryValue(range);
    if (rangeValue != null) params['range'] = rangeValue;
    if (categoryKey != null) params['category'] = categoryKey;
    if (accountKey != null) params['account'] = accountKey;
    final monthValue = TransactionsFilters.monthQueryValue(month);
    if (monthValue != null) params['month'] = monthValue;

    final uri = Uri(
      path: '/movements',
      queryParameters: params.isEmpty ? null : params,
    );
    context.push(uri.toString());
  }

  void _pushType(TransactionTypeFilter value) => _pushFilters(
        type: value,
        range: _dateRange,
        categoryKey: _categoryKey,
        accountKey: _accountKey,
        month: _selectedMonth,
      );

  void _pushRange(TransactionDateRangeFilter value) => _pushFilters(
        type: _typeFilter,
        range: value,
        categoryKey: _categoryKey,
        accountKey: _accountKey,
        month: _selectedMonth,
      );

  void _pushCategory(String? value) => _pushFilters(
        type: _typeFilter,
        range: _dateRange,
        categoryKey: value,
        accountKey: _accountKey,
        month: _selectedMonth,
      );

  void _pushAccount(String? value) => _pushFilters(
        type: _typeFilter,
        range: _dateRange,
        categoryKey: _categoryKey,
        accountKey: value,
        month: _selectedMonth,
      );

  // The date range does not apply outside the current month; reset it.
  void _pushMonth(DateTime value) => _pushFilters(
        type: _typeFilter,
        range: TransactionsFilters.isCurrentMonth(value)
            ? _dateRange
            : TransactionDateRangeFilter.all,
        categoryKey: _categoryKey,
        accountKey: _accountKey,
        month: value,
      );

  void _pushClearFilters() => _pushFilters(
        type: TransactionTypeFilter.all,
        range: TransactionDateRangeFilter.all,
        categoryKey: null,
        accountKey: null,
        month: TransactionsFilters.currentMonth(),
      );

  /// Visible rows; starts at [_pageSize] and grows with "Ver más".
  int _visibleCount = _pageSize;

  static const int _pageSize = 10;

  // Id of the transaction being deleted, to disable its row actions.
  String? _deletingId;

  // Id of the transaction being updated.
  String? _updatingId;

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

  /// Opens the actions menu of [movement] and runs the chosen action.
  Future<void> _openActions(TransactionEntry movement) async {
    final linkedInvoice =
        widget.invoiceViewModel.invoiceForTransaction(movement.id);

    final action = await showMovementActionsSheet(
      context,
      movement: movement,
      isServicePayment: linkedInvoice != null,
    );
    if (action == null || !mounted) return;

    switch (action) {
      case MovementAction.edit:
        await _editMovement(movement, isServicePayment: linkedInvoice != null);
      case MovementAction.markTransfer:
        await _setTransfer(movement, isTransfer: true);
      case MovementAction.unmarkTransfer:
        await _setTransfer(movement, isTransfer: false);
      case MovementAction.linkInvoice:
        await _linkInvoice(movement);
      case MovementAction.unlinkInvoice:
        if (linkedInvoice != null) {
          await _unlinkInvoice(movement, linkedInvoice);
        }
      case MovementAction.delete:
        await _confirmDelete(movement);
    }
  }

  /// Runs [action] marking the row as updating and reports a failure with
  /// the message from [errorMessage]. Each view model keeps its own last
  /// error, so the caller says which one to read.
  Future<void> _runUpdate(
    TransactionEntry movement,
    Future<bool> Function() action, {
    required String? Function() errorMessage,
    String? successMessage,
  }) async {
    setState(() => _updatingId = movement.id);

    final success = await action();

    if (!mounted) return;

    final message = success
        ? successMessage
        : errorMessage() ?? 'No se pudo guardar los cambios.';
    if (message != null) {
      _showFloatingSnackBar(message, isError: !success);
    }

    setState(() => _updatingId = null);
  }

  /// Edit dialog: category (regular movements only) and description.
  Future<void> _editMovement(
    TransactionEntry movement, {
    required bool isServicePayment,
  }) async {
    final result = await showDialog<EditMovementResult>(
      context: context,
      builder: (_) => EditMovementDialog(
        movement: movement,
        categoryViewModel: widget.categoryViewModel,
        isServicePayment: isServicePayment,
        currency: widget.currency,
      ),
    );
    if (result == null || !mounted) return;

    await _runUpdate(
      movement,
      () => widget.transactionViewModel.updateTransaction(
        transactionId: movement.id,
        categoryId: result.categoryId,
        description: result.description,
      ),
      errorMessage: () => widget.transactionViewModel.errorMessage,
    );
  }

  Future<void> _setTransfer(
    TransactionEntry movement, {
    required bool isTransfer,
  }) {
    return _runUpdate(
      movement,
      () => widget.transactionViewModel.setTransfer(
        transactionId: movement.id,
        isTransfer: isTransfer,
      ),
      errorMessage: () => widget.transactionViewModel.errorMessage,
    );
  }

  /// Picks a pending invoice and links the movement to it as its payment.
  /// The movement keeps its amount and takes the service's category.
  Future<void> _linkInvoice(TransactionEntry movement) async {
    final invoice = await showModalBottomSheet<Invoice>(
      context: context,
      backgroundColor: AppColors.authBackgroundBottom,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SelectPendingInvoiceSheet(
        invoices: widget.invoiceViewModel.pendingInvoicesNear(movement.date),
        serviceViewModel: widget.serviceViewModel,
        currency: widget.currency,
      ),
    );
    if (invoice == null || !mounted) return;

    if (invoice.amount != movement.amount) {
      final confirmed = await _askConfirmation(
        title: '¿Vincular a la factura?',
        message: 'El monto del movimiento '
            '(${formatCurrency(movement.amount, widget.currency)}) difiere '
            'del de la factura '
            '(${formatCurrency(invoice.amount, widget.currency)}). El '
            'movimiento conserva su monto.',
        confirmLabel: 'Vincular',
        icon: Icons.link_rounded,
        accentColor: AppColors.authAccent,
      );
      if (!confirmed || !mounted) return;
    }

    final service = widget.serviceViewModel.serviceById(invoice.serviceId);
    final serviceName = service?.name ?? 'la factura';
    await _runUpdate(
      movement,
      () => widget.invoiceViewModel.linkExistingTransaction(
        invoice: invoice,
        transactionId: movement.id,
        // A service without category keeps the movement's own.
        categoryId: service?.categoryId ?? movement.category.id,
        description: movement.description,
      ),
      errorMessage: () => widget.invoiceViewModel.errorMessage,
      successMessage: 'Movimiento vinculado a $serviceName.',
    );
  }

  /// Reverts a service payment: the invoice goes back to pending and the
  /// movement stays as a regular expense.
  Future<void> _unlinkInvoice(
    TransactionEntry movement,
    Invoice invoice,
  ) async {
    final service = widget.serviceViewModel.serviceById(invoice.serviceId);
    final confirmed = await _askConfirmation(
      title: '¿Desvincular del servicio?',
      message: 'La factura de ${service?.name ?? 'servicio'} vuelve a quedar '
          'pendiente y el movimiento se mantiene como un gasto común.',
      confirmLabel: 'Desvincular',
      icon: Icons.link_off_rounded,
      accentColor: AppColors.authExpense,
    );
    if (!confirmed || !mounted) return;

    await _runUpdate(
      movement,
      () => widget.invoiceViewModel.unlinkTransaction(invoice),
      errorMessage: () => widget.invoiceViewModel.errorMessage,
      successMessage: 'Movimiento desvinculado del servicio.',
    );
  }

  Future<bool> _askConfirmation({
    required String title,
    required String message,
    required String confirmLabel,
    IconData icon = Icons.help_outline_rounded,
    Color accentColor = AppColors.authAccent,
  }) async {
    final confirmed = await showDialog<bool>(
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
                    color: accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.authTextPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.authTextSecondary,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextActionButton(
            label: 'Volver',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          TextActionButton(
            label: confirmLabel,
            color: accentColor,
            fontWeight: FontWeight.w700,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  /// Asks for confirmation, then deletes the transaction.
  Future<void> _confirmDelete(TransactionEntry movement) async {
    final titleText = movement.description?.isNotEmpty == true
        ? movement.description!
        : movement.category.name;
    final amountText = formatCurrency(movement.amount, widget.currency);

    final confirmed = await showDialog<bool>(
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
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: AppColors.authExpense,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '¿Eliminar movimiento?',
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.authCardFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.authCardBorder.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      titleText,
                      style: const TextStyle(
                        color: AppColors.authTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    amountText,
                    style: const TextStyle(
                      color: AppColors.authExpense,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'El saldo de la cuenta se va a actualizar. Esta acción no se puede deshacer.',
              style: TextStyle(
                color: AppColors.authTextSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextActionButton(
            label: 'Volver',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          TextActionButton(
            label: 'Eliminar',
            color: AppColors.authExpense,
            fontWeight: FontWeight.w700,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteMovement(movement);
    }
  }

  Future<void> _deleteMovement(TransactionEntry movement) async {
    setState(() => _deletingId = movement.id);

    final success = await widget.transactionViewModel.deleteTransaction(
      userId: widget.userId,
      transactionId: movement.id,
    );

    if (!mounted) return;

    if (success) {
      // Balance changed server-side; reload accounts to show it.
      await widget.accountViewModel.loadAccounts();
      if (mounted) {
        _showFloatingSnackBar('Movimiento eliminado correctamente.');
      }
    } else if (mounted) {
      _showFloatingSnackBar(
        widget.transactionViewModel.errorMessage ??
            'No se pudo eliminar el movimiento.',
        isError: true,
      );
    }

    if (mounted) setState(() => _deletingId = null);
  }

  bool _matchesType(TransactionEntry t) =>
      TransactionsFilters.matchesType(_typeFilter, t);

  bool _matchesDateRange(TransactionEntry t) =>
      TransactionsFilters.matchesDateRange(_effectiveDateRange, t);

  bool _matchesMonth(TransactionEntry t) =>
      TransactionsFilters.matchesMonth(_selectedMonth, t);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListenableBuilder(
        // Invoices too: linking or unlinking a payment changes a row's icon
        // without reloading the movements.
        listenable: Listenable.merge([
          widget.transactionViewModel,
          widget.invoiceViewModel,
        ]),
        builder: (context, _) {
          final vm = widget.transactionViewModel;
          final servicePaymentIds =
              widget.invoiceViewModel.servicePaymentTransactionIds;

          if (vm.isLoadingAll && vm.allTransactions.isEmpty) {
            return const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.authAccent,
                ),
              ),
            );
          }

          if (vm.allTransactions.isEmpty) {
            return RefreshIndicator(
              onRefresh: vm.loadAllTransactions,
              color: AppColors.authAccent,
              backgroundColor: AppColors.authBackgroundTop,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ScreenHeader(
                            title: 'Movimientos',
                            subtitle: 'Revisa y filtra tus ingresos y gastos.',
                            action: MonthFilterButton(
                              selectedMonth: _selectedMonth,
                              onChanged: _pushMonth,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 40,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.authCardFill,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: AppColors.authCardBorder,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.14),
                                  blurRadius: 18,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppColors.authAccent
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.authAccent
                                          .withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long_outlined,
                                    color: AppColors.authAccent,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Todavía no hay movimientos',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.authTextPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Tus ingresos y gastos registrados aparecerán listados aquí.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.authTextSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final dateFiltered = vm.allTransactions
              .where(_matchesDateRange)
              .where(_matchesMonth)
              .toList();
          final typeFiltered = dateFiltered.where(_matchesType).toList();
          final categories =
              TransactionsFilters.visibleCategories(typeFiltered);
          final accounts = TransactionsFilters.visibleAccounts(typeFiltered);

          // Ignore a selected category/account hidden by the current filters,
          // without changing state.
          final effectiveCategoryKey = _categoryKey != null &&
                  categories.any((c) => _categoryModelKey(c) == _categoryKey)
              ? _categoryKey
              : null;
          final effectiveAccountKey = _accountKey != null &&
                  accounts.any((a) => _accountModelKey(a) == _accountKey)
              ? _accountKey
              : null;

          var filtered = typeFiltered;
          if (effectiveCategoryKey != null) {
            filtered = filtered
                .where(
                  (t) =>
                      TransactionsFilters.categoryKeyOf(t) ==
                      effectiveCategoryKey,
                )
                .toList();
          }
          if (effectiveAccountKey != null) {
            filtered = filtered
                .where(
                  (t) =>
                      TransactionsFilters.accountKeyOf(t) ==
                      effectiveAccountKey,
                )
                .toList();
          }

          final hasActiveFilters = _typeFilter != TransactionTypeFilter.all ||
              _effectiveDateRange != TransactionDateRangeFilter.all ||
              !TransactionsFilters.isCurrentMonth(_selectedMonth) ||
              effectiveCategoryKey != null ||
              effectiveAccountKey != null;

          return RefreshIndicator(
            onRefresh: vm.loadAllTransactions,
            color: AppColors.authAccent,
            backgroundColor: AppColors.authBackgroundTop,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ScreenHeader(
                          title: 'Movimientos',
                          subtitle: 'Revisa y filtra tus ingresos y gastos.',
                          action: MonthFilterButton(
                            selectedMonth: _selectedMonth,
                            onChanged: _pushMonth,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.authCardFill,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppColors.authCardBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.authAccent
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.authAccent
                                            .withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.tune_rounded,
                                      size: 16,
                                      color: AppColors.authAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'Filtros',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.authTextPrimary,
                                      ),
                                    ),
                                  ),
                                  if (hasActiveFilters)
                                    InkWell(
                                      onTap: _pushClearFilters,
                                      borderRadius: BorderRadius.circular(8),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.refresh_rounded,
                                              size: 14,
                                              color: AppColors.authAccent,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Limpiar',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.authAccent,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              FilterChipRow<TransactionTypeFilter>(
                                options: const [
                                  (
                                    value: TransactionTypeFilter.all,
                                    label: 'Todos'
                                  ),
                                  (
                                    value: TransactionTypeFilter.income,
                                    label: 'Ingresos'
                                  ),
                                  (
                                    value: TransactionTypeFilter.expense,
                                    label: 'Gastos'
                                  ),
                                  (
                                    value: TransactionTypeFilter.transfer,
                                    label: 'Transferencias'
                                  ),
                                ],
                                selectedValue: _typeFilter,
                                onChanged: (value) {
                                  if (value != _typeFilter) _pushType(value);
                                },
                              ),
                              if (TransactionsFilters.isCurrentMonth(
                                  _selectedMonth)) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  child: Divider(
                                    height: 1,
                                    color: AppColors.authCardBorder
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                const TransactionsFilterSectionLabel('Período'),
                                const SizedBox(height: 8),
                                FilterChipRow<TransactionDateRangeFilter>(
                                  options: const [
                                    (
                                      value: TransactionDateRangeFilter.all,
                                      label: 'Todo'
                                    ),
                                    (
                                      value: TransactionDateRangeFilter.today,
                                      label: 'Hoy'
                                    ),
                                    (
                                      value: TransactionDateRangeFilter.thisWeek,
                                      label: 'Esta semana'
                                    ),
                                    (
                                      value:
                                          TransactionDateRangeFilter.last7Days,
                                      label: 'Últimos 7 días'
                                    ),
                                    (
                                      value:
                                          TransactionDateRangeFilter.last15Days,
                                      label: 'Últimos 15 días'
                                    ),
                                  ],
                                  selectedValue: _dateRange,
                                  onChanged: (value) {
                                    if (value != _dateRange) _pushRange(value);
                                  },
                                ),
                              ],
                              if (accounts.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  child: Divider(
                                    height: 1,
                                    color: AppColors.authCardBorder
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                const TransactionsFilterSectionLabel('Cuenta'),
                                const SizedBox(height: 8),
                                FilterChipRow<String?>(
                                  options: <({String? value, String label})>[
                                    (value: null, label: 'Todas'),
                                    ...accounts.map(
                                      (a) => (
                                        value: _accountModelKey(a),
                                        label: a.name
                                      ),
                                    ),
                                  ],
                                  selectedValue: effectiveAccountKey,
                                  onChanged: (key) {
                                    if (key != _accountKey) _pushAccount(key);
                                  },
                                ),
                              ],
                              if (categories.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  child: Divider(
                                    height: 1,
                                    color: AppColors.authCardBorder
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                const TransactionsFilterSectionLabel(
                                    'Categoría'),
                                const SizedBox(height: 8),
                                TransactionsCategoryFilter(
                                  categories: categories,
                                  selectedKey: effectiveCategoryKey,
                                  onChanged: (key) {
                                    if (key != _categoryKey) _pushCategory(key);
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (filtered.isEmpty)
                          TransactionsEmptyFilteredState(
                            onClear:
                                hasActiveFilters ? _pushClearFilters : null,
                          )
                        else
                          Builder(builder: (context) {
                            final total = filtered.length;
                            final visibleCount = _visibleCount.clamp(0, total);
                            final visible =
                                filtered.take(visibleCount).toList();
                            final remaining = total - visibleCount;

                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.authCardFill,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                    color: AppColors.authCardBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.16),
                                    blurRadius: 18,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      14,
                                      16,
                                      12,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          hasActiveFilters
                                              ? 'RESULTADOS'
                                              : 'HISTORIAL',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.8,
                                            color: AppColors.authTextFooter,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.05),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '$total movimiento${total == 1 ? '' : 's'}',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  AppColors.authTextSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Divider(
                                    height: 1,
                                    color: AppColors.authCardBorder
                                        .withValues(alpha: 0.5),
                                  ),
                                  ...List.generate(visible.length, (i) {
                                    final movement = visible[i];
                                    return TransactionMovementRow(
                                      movement: movement,
                                      currency: widget.currency,
                                      showDivider:
                                          i != visible.length - 1 ||
                                              remaining > 0,
                                      isDeleting: _deletingId == movement.id,
                                      isUpdating: _updatingId == movement.id,
                                      isServicePayment:
                                          servicePaymentIds.contains(
                                              movement.id),
                                      onActions: () => _openActions(movement),
                                    );
                                  }),
                                  if (remaining > 0)
                                    InkWell(
                                      onTap: () => setState(() {
                                        _visibleCount =
                                            visibleCount + _pageSize;
                                      }),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.02),
                                          border: Border(
                                            top: BorderSide(
                                              color: AppColors.authCardBorder
                                                  .withValues(alpha: 0.5),
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Ver más (${remaining > _pageSize ? _pageSize : remaining})',
                                              style: const TextStyle(
                                                color: AppColors.authAccent,
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.expand_more_rounded,
                                              size: 18,
                                              color: AppColors.authAccent,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _categoryModelKey(TransactionCategory c) => c.id ?? c.name;

  String _accountModelKey(TransactionAccount a) => a.id ?? a.name;
}
