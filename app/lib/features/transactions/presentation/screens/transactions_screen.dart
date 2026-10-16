import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/filter_chip_row.dart';
import '../../../../core/widgets/month_filter_button.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../../core/widgets/text_action_button.dart';
import '../../../accounts/presentation/view_models/account_view_model.dart';
import '../../../accounts/presentation/widgets/pending_movements/select_pending_invoice_sheet.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../invoices/data/models/invoice.dart';
import '../../../invoices/presentation/view_models/invoice_view_model.dart';
import '../../../services/presentation/view_models/service_view_model.dart';
import '../../data/models/transaction_entry.dart';
import '../view_models/transaction_view_model.dart';
import '../view_models/transactions_filters.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
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
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.authBackgroundTop,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.authCardBorder),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.authTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.authTextSecondary),
        ),
        actions: [
          TextActionButton(
            label: 'Volver',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          TextActionButton(
            label: confirmLabel,
            color: AppColors.authAccent,
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
          '¿Eliminar movimiento?',
          style: TextStyle(
            color: AppColors.authTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '${movement.description?.isNotEmpty == true ? movement.description! : movement.category.name} · '
          '${formatCurrency(movement.amount, widget.currency)}\n\n'
          'El saldo de la cuenta se va a actualizar. Esta acción no se '
          'puede deshacer.',
          style: const TextStyle(color: AppColors.authTextSecondary),
        ),
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
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.transactionViewModel.errorMessage ??
                'No se pudo eliminar el movimiento.',
          ),
        ),
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
              child: CircularProgressIndicator(color: AppColors.authAccent),
            );
          }

          if (vm.allTransactions.isEmpty) {
            return RefreshIndicator(
              onRefresh: vm.loadAllTransactions,
              color: AppColors.authAccent,
              backgroundColor: AppColors.authBackgroundTop,
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      'Todavía no hay movimientos.',
                      style: AppTextStyles.authSubtitle,
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
                ScreenHeader(
                  title: 'Movimientos',
                  subtitle: 'Revisa y filtra tus ingresos y gastos.',
                  action: MonthFilterButton(
                    selectedMonth: _selectedMonth,
                    onChanged: _pushMonth,
                  ),
                ),
                const SizedBox(height: 20),
                FilterChipRow<TransactionTypeFilter>(
                  options: const [
                    (value: TransactionTypeFilter.all, label: 'Todos'),
                    (value: TransactionTypeFilter.income, label: 'Ingresos'),
                    (value: TransactionTypeFilter.expense, label: 'Gastos'),
                  ],
                  selectedValue: _typeFilter,
                  onChanged: (value) {
                    if (value != _typeFilter) _pushType(value);
                  },
                ),
                if (TransactionsFilters.isCurrentMonth(_selectedMonth)) ...[
                  const SizedBox(height: 12),
                  const TransactionsFilterSectionLabel('Período'),
                  const SizedBox(height: 6),
                  FilterChipRow<TransactionDateRangeFilter>(
                    options: const [
                      (value: TransactionDateRangeFilter.all, label: 'Todo'),
                      (value: TransactionDateRangeFilter.today, label: 'Hoy'),
                      (
                        value: TransactionDateRangeFilter.thisWeek,
                        label: 'Esta semana'
                      ),
                      (
                        value: TransactionDateRangeFilter.last7Days,
                        label: 'Últimos 7 días'
                      ),
                      (
                        value: TransactionDateRangeFilter.last15Days,
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
                  const SizedBox(height: 12),
                  const TransactionsFilterSectionLabel('Cuenta'),
                  const SizedBox(height: 6),
                  FilterChipRow<String?>(
                    options: <({String? value, String label})>[
                      (value: null, label: 'Todas'),
                      ...accounts.map(
                        (a) => (value: _accountModelKey(a), label: a.name),
                      ),
                    ],
                    selectedValue: effectiveAccountKey,
                    onChanged: (key) {
                      if (key != _accountKey) _pushAccount(key);
                    },
                  ),
                ],
                if (categories.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const TransactionsFilterSectionLabel('Categoría'),
                  const SizedBox(height: 6),
                  FilterChipRow<String?>(
                    options: <({String? value, String label})>[
                      (value: null, label: 'Todas'),
                      ...categories.map(
                        (c) => (value: _categoryModelKey(c), label: c.name),
                      ),
                    ],
                    selectedValue: effectiveCategoryKey,
                    onChanged: (key) {
                      if (key != _categoryKey) _pushCategory(key);
                    },
                  ),
                ],
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  TransactionsEmptyFilteredState(
                    onClear: hasActiveFilters ? _pushClearFilters : null,
                  )
                else
                  Builder(builder: (context) {
                    final total = filtered.length;
                    final visibleCount = _visibleCount.clamp(0, total);
                    final visible = filtered.take(visibleCount).toList();
                    final remaining = total - visibleCount;

                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.authCardFill,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.authCardBorder),
                      ),
                      child: Column(
                        children: [
                          ...List.generate(visible.length, (i) {
                            final movement = visible[i];
                            return TransactionMovementRow(
                              movement: movement,
                              currency: widget.currency,
                              showDivider:
                                  i != visible.length - 1 || remaining > 0,
                              isDeleting: _deletingId == movement.id,
                              isUpdating: _updatingId == movement.id,
                              isServicePayment:
                                  servicePaymentIds.contains(movement.id),
                              onActions: () => _openActions(movement),
                            );
                          }),
                          if (remaining > 0)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: TextButton(
                                onPressed: () => setState(() {
                                  _visibleCount = visibleCount + _pageSize;
                                }),
                                child: Text(
                                  'Ver más (${remaining > _pageSize ? _pageSize : remaining})',
                                  style: const TextStyle(
                                    color: AppColors.authAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
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
