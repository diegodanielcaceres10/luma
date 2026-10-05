import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/app_clock.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/filter_chip_row.dart';
import '../../../../core/widgets/month_filter_button.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../accounts/presentation/view_models/account_view_model.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../data/models/transaction_entry.dart';
import '../view_models/transaction_view_model.dart';
import '../widgets/history/edit_movement_dialog.dart';
import '../widgets/history/history_filter_widgets.dart';
import '../widgets/history/movement_row.dart';

enum _TypeFilter { all, income, expense }

enum _DateRangeFilter { today, thisWeek, last7Days, last15Days, all }

/// Filterable transaction history.
class TransactionsScreen extends StatefulWidget {
  final String userId;
  final TransactionViewModel transactionViewModel;
  final AccountViewModel accountViewModel;
  final CategoryViewModel categoryViewModel;
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
  late _TypeFilter _typeFilter;
  late _DateRangeFilter _dateRange;

  // null means "all". Holds category.id/account.id, or the name if there is
  // no id.
  late String? _categoryKey;
  late String? _accountKey;

  // Selected calendar month; defaults to the current month.
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _typeFilter = _typeFromQuery(widget.initialType);
    _dateRange = _rangeFromQuery(widget.initialRange);
    _categoryKey = widget.initialCategory;
    _accountKey = widget.initialAccount;
    _selectedMonth = _monthFromQuery(widget.initialMonth);
    // Load after the first frame: loadAllTransactions notifies listeners
    // synchronously, which would happen during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.transactionViewModel.loadAllTransactions();
    });
  }

  static _TypeFilter _typeFromQuery(String? value) {
    switch (value) {
      case 'income':
        return _TypeFilter.income;
      case 'expense':
        return _TypeFilter.expense;
      default:
        return _TypeFilter.all;
    }
  }

  static String? _typeQueryValue(_TypeFilter filter) {
    switch (filter) {
      case _TypeFilter.all:
        return null;
      case _TypeFilter.income:
        return 'income';
      case _TypeFilter.expense:
        return 'expense';
    }
  }

  static _DateRangeFilter _rangeFromQuery(String? value) {
    switch (value) {
      case 'today':
        return _DateRangeFilter.today;
      case 'week':
        return _DateRangeFilter.thisWeek;
      case 'last7':
        return _DateRangeFilter.last7Days;
      case 'last15':
        return _DateRangeFilter.last15Days;
      default:
        return _DateRangeFilter.all;
    }
  }

  static String? _rangeQueryValue(_DateRangeFilter filter) {
    switch (filter) {
      case _DateRangeFilter.all:
        return null;
      case _DateRangeFilter.today:
        return 'today';
      case _DateRangeFilter.thisWeek:
        return 'week';
      case _DateRangeFilter.last7Days:
        return 'last7';
      case _DateRangeFilter.last15Days:
        return 'last15';
    }
  }

  static DateTime _currentMonth() {
    final now = nowLocal();
    return DateTime(now.year, now.month);
  }

  static bool _isCurrentMonth(DateTime month) {
    final current = _currentMonth();
    return month.year == current.year && month.month == current.month;
  }

  /// Relative date ranges only apply to the current month; in other months
  /// the "Período" filter is hidden and ignored.
  _DateRangeFilter get _effectiveDateRange =>
      _isCurrentMonth(_selectedMonth) ? _dateRange : _DateRangeFilter.all;

  /// Parses 'YYYY-MM'; falls back to the current month if missing or
  /// invalid.
  static DateTime _monthFromQuery(String? value) {
    if (value == null) return _currentMonth();
    final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(value);
    if (match == null) return _currentMonth();
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    if (month < 1 || month > 12) return _currentMonth();
    return DateTime(year, month);
  }

  /// The current month is the default, so it is omitted from the URL.
  static String? _monthQueryValue(DateTime month) {
    if (_isCurrentMonth(month)) return null;
    final mm = month.month.toString().padLeft(2, '0');
    return '${month.year}-$mm';
  }

  /// Pushes a URL with the combined filters; see
  /// [TransactionsScreen.initialType].
  void _pushFilters({
    required _TypeFilter type,
    required _DateRangeFilter range,
    required String? categoryKey,
    required String? accountKey,
    required DateTime month,
  }) {
    final params = <String, String>{};
    final typeValue = _typeQueryValue(type);
    if (typeValue != null) params['type'] = typeValue;
    final rangeValue = _rangeQueryValue(range);
    if (rangeValue != null) params['range'] = rangeValue;
    if (categoryKey != null) params['category'] = categoryKey;
    if (accountKey != null) params['account'] = accountKey;
    final monthValue = _monthQueryValue(month);
    if (monthValue != null) params['month'] = monthValue;

    final uri = Uri(
      path: '/movements',
      queryParameters: params.isEmpty ? null : params,
    );
    context.push(uri.toString());
  }

  void _pushType(_TypeFilter value) => _pushFilters(
        type: value,
        range: _dateRange,
        categoryKey: _categoryKey,
        accountKey: _accountKey,
        month: _selectedMonth,
      );

  void _pushRange(_DateRangeFilter value) => _pushFilters(
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
        range: _isCurrentMonth(value) ? _dateRange : _DateRangeFilter.all,
        categoryKey: _categoryKey,
        accountKey: _accountKey,
        month: value,
      );

  void _pushClearFilters() => _pushFilters(
        type: _TypeFilter.all,
        range: _DateRangeFilter.all,
        categoryKey: null,
        accountKey: null,
        month: _currentMonth(),
      );

  /// Visible rows; starts at [_pageSize] and grows with "Ver más".
  int _visibleCount = _pageSize;

  static const int _pageSize = 10;

  // Id of the transaction being deleted, to disable its row actions.
  String? _deletingId;

  // Id of the transaction being updated.
  String? _updatingId;

  /// Opens the edit dialog and saves the changes if confirmed.
  Future<void> _openEditDialog(TransactionEntry movement) async {
    final result = await showDialog<EditMovementResult>(
      context: context,
      builder: (_) => EditMovementDialog(
        movement: movement,
        categoryViewModel: widget.categoryViewModel,
        currency: widget.currency,
      ),
    );

    if (result == null || !mounted) return;

    setState(() => _updatingId = movement.id);

    final success = await widget.transactionViewModel.updateTransaction(
      transactionId: movement.id,
      categoryId: result.categoryId,
      description: result.description,
      date: result.date,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.transactionViewModel.errorMessage ??
                'No se pudo guardar los cambios.',
          ),
        ),
      );
    }

    if (mounted) setState(() => _updatingId = null);
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
              'Eliminar',
              style: TextStyle(
                color: AppColors.authExpense,
                fontWeight: FontWeight.w700,
              ),
            ),
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

  bool _matchesType(TransactionEntry t) {
    switch (_typeFilter) {
      case _TypeFilter.all:
        return true;
      case _TypeFilter.income:
        return t.isIncome;
      case _TypeFilter.expense:
        return !t.isIncome;
    }
  }

  bool _matchesDateRange(TransactionEntry t) {
    final now = nowLocal();
    final today = DateTime(now.year, now.month, now.day);
    final txDate = DateTime(t.date.year, t.date.month, t.date.day);
    switch (_effectiveDateRange) {
      case _DateRangeFilter.all:
        return true;
      case _DateRangeFilter.today:
        return txDate == today;
      case _DateRangeFilter.thisWeek:
        // Weeks start on Monday.
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        return !txDate.isBefore(startOfWeek) && !txDate.isAfter(today);
      case _DateRangeFilter.last7Days:
        final start = today.subtract(const Duration(days: 6));
        return !txDate.isBefore(start) && !txDate.isAfter(today);
      case _DateRangeFilter.last15Days:
        final start = today.subtract(const Duration(days: 14));
        return !txDate.isBefore(start) && !txDate.isAfter(today);
    }
  }

  bool _matchesMonth(TransactionEntry t) =>
      t.date.year == _selectedMonth.year &&
      t.date.month == _selectedMonth.month;

  String _categoryKeyOf(TransactionEntry t) => t.category.id ?? t.category.name;

  String _accountKeyOf(TransactionEntry t) => t.account.id ?? t.account.name;

  /// Categories with at least one transaction under the current type/date
  /// filters.
  List<TransactionCategory> _visibleCategories(
      List<TransactionEntry> typeFiltered) {
    final Map<String, TransactionCategory> byKey = {};
    for (final t in typeFiltered) {
      byKey[_categoryKeyOf(t)] = t.category;
    }
    final list = byKey.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  List<TransactionAccount> _visibleAccounts(
      List<TransactionEntry> typeFiltered) {
    final Map<String, TransactionAccount> byKey = {};
    for (final t in typeFiltered) {
      byKey[_accountKeyOf(t)] = t.account;
    }
    final list = byKey.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListenableBuilder(
        listenable: widget.transactionViewModel,
        builder: (context, _) {
          final vm = widget.transactionViewModel;

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
          final categories = _visibleCategories(typeFiltered);
          final accounts = _visibleAccounts(typeFiltered);

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
                .where((t) => _categoryKeyOf(t) == effectiveCategoryKey)
                .toList();
          }
          if (effectiveAccountKey != null) {
            filtered = filtered
                .where((t) => _accountKeyOf(t) == effectiveAccountKey)
                .toList();
          }

          final hasActiveFilters = _typeFilter != _TypeFilter.all ||
              _effectiveDateRange != _DateRangeFilter.all ||
              !_isCurrentMonth(_selectedMonth) ||
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
                FilterChipRow<_TypeFilter>(
                  options: const [
                    (value: _TypeFilter.all, label: 'Todos'),
                    (value: _TypeFilter.income, label: 'Ingresos'),
                    (value: _TypeFilter.expense, label: 'Gastos'),
                  ],
                  selectedValue: _typeFilter,
                  onChanged: (value) {
                    if (value != _typeFilter) _pushType(value);
                  },
                ),
                if (_isCurrentMonth(_selectedMonth)) ...[
                  const SizedBox(height: 12),
                  const TransactionsFilterSectionLabel('Período'),
                  const SizedBox(height: 6),
                  FilterChipRow<_DateRangeFilter>(
                    options: const [
                      (value: _DateRangeFilter.all, label: 'Todo'),
                      (value: _DateRangeFilter.today, label: 'Hoy'),
                      (value: _DateRangeFilter.thisWeek, label: 'Esta semana'),
                      (
                        value: _DateRangeFilter.last7Days,
                        label: 'Últimos 7 días'
                      ),
                      (
                        value: _DateRangeFilter.last15Days,
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
                              onEdit: () => _openEditDialog(movement),
                              onDelete: () => _confirmDelete(movement),
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
