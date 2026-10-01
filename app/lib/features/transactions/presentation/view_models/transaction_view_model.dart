import 'package:flutter/foundation.dart';
import '../../../accounts/data/repositories/monthly_balance_repository.dart';
import '../../data/models/transaction_entry.dart';
import '../../data/repositories/transaction_repository.dart';

class CategoryTotal {
  final TransactionCategory category;
  final double amount;
  final double percent;

  const CategoryTotal({
    required this.category,
    required this.amount,
    required this.percent,
  });
}

class TransactionViewModel extends ChangeNotifier {
  final TransactionRepository _repository;
  final MonthlyBalanceRepository _monthlyBalanceRepository;

  TransactionViewModel(this._repository, this._monthlyBalanceRepository);

  bool _isLoading = false;
  bool _isLoadingAll = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  List<TransactionEntry> _transactions = [];
  List<TransactionEntry> _previousMonthTransactions = [];
  List<TransactionEntry> _allTransactions = [];
  bool _hasLoadedAll = false;
  String? _lastCreatedTransactionId;

  // null means the current month, already loaded in _transactions.
  DateTime? _statisticsMonth;
  List<TransactionEntry> _statisticsTransactions = [];
  List<TransactionEntry> _statisticsPreviousTransactions = [];
  bool _isLoadingStatistics = false;
  String? _statisticsErrorMessage;

  // Signed sums of uncontrolled_expenses_total for the current and
  // statistics months.
  double _currentMonthUncontrolledTotal = 0;
  double _statisticsUncontrolledTotal = 0;

  // Discards responses from superseded month loads.
  int _statisticsRequestId = 0;

  bool get isLoading => _isLoading;
  bool get isLoadingAll => _isLoadingAll;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  /// Id of the last transaction created by [createTransaction].
  String? get lastCreatedTransactionId => _lastCreatedTransactionId;

  /// Full history, not limited to the current month. Call
  /// [loadAllTransactions] first.
  List<TransactionEntry> get allTransactions => _allTransactions;

  List<TransactionEntry> get recentMovements => _transactions.take(4).toList();

  double get totalExpenses => _sumByType(_transactions, 'expense');

  double get totalIncome => _sumByType(_transactions, 'income');

  /// Income minus expenses for the current month. Can be negative.
  double get netResult => totalIncome - totalExpenses;

  /// [netResult] plus the current month's uncontrolled adjustments.
  double get netResultWithUncontrolled =>
      netResult + _currentMonthUncontrolledTotal;

  /// Previous calendar month totals, for "vs. previous month" comparisons.
  double get previousMonthIncome =>
      _sumByType(_previousMonthTransactions, 'income');

  double get previousMonthExpenses =>
      _sumByType(_previousMonthTransactions, 'expense');

  double get previousMonthNetResult =>
      previousMonthIncome - previousMonthExpenses;

  /// Percent change vs. the previous month; null when there is no base to
  /// compare against.
  double? get incomeChangePercent =>
      _percentChange(previousMonthIncome, totalIncome);

  double? get expenseChangePercent =>
      _percentChange(previousMonthExpenses, totalExpenses);

  double? get netResultChangePercent =>
      _percentChange(previousMonthNetResult, netResult);

  double? _percentChange(double previous, double current) {
    if (previous == 0) return null;
    return ((current - previous) / previous.abs()) * 100;
  }

  List<CategoryTotal> get categoryBreakdown => _breakdownOf(_transactions);

  /// Entries of one category since [since], for the category trend. Does
  /// not touch this view model's state; errors reach the caller.
  Future<List<TransactionEntry>> fetchCategoryEntries({
    required String categoryId,
    required DateTime since,
  }) {
    return _repository.getForCategory(categoryId: categoryId, since: since);
  }

  static double _sumByType(List<TransactionEntry> entries, String type) {
    return entries
        .where((t) => t.type == type && !t.isTransfer)
        .fold<double>(0, (sum, t) => sum + t.amount);
  }

  /// Expenses grouped by category (largest first) with their share of the
  /// total. Transfers are excluded.
  static List<CategoryTotal> _breakdownOf(List<TransactionEntry> entries) {
    final expenses = entries.where((t) => t.type == 'expense' && !t.isTransfer);
    final Map<String, double> totals = {};
    final Map<String, TransactionCategory> categories = {};

    for (final t in expenses) {
      final key = t.category.id ?? t.category.name;
      totals[key] = (totals[key] ?? 0) + t.amount;
      categories[key] = t.category;
    }

    final total = _sumByType(entries, 'expense');
    final list = totals.entries.map((e) {
      return CategoryTotal(
        category: categories[e.key]!,
        amount: e.value,
        percent: total > 0 ? (e.value / total) * 100 : 0,
      );
    }).toList();

    list.sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  // Statistics month: same calculations as above, for the selected month.

  bool get isStatisticsCurrentMonth {
    final month = _statisticsMonth;
    if (month == null) return true;
    final now = DateTime.now();
    return month.year == now.year && month.month == now.month;
  }

  DateTime get statisticsMonth {
    if (isStatisticsCurrentMonth) {
      final now = DateTime.now();
      return DateTime(now.year, now.month);
    }
    return _statisticsMonth!;
  }

  bool get isStatisticsLoading =>
      isStatisticsCurrentMonth ? _isLoading : _isLoadingStatistics;

  /// Only reports errors for past months; the current month follows
  /// [loadCurrentMonth].
  String? get statisticsErrorMessage =>
      isStatisticsCurrentMonth ? null : _statisticsErrorMessage;

  List<TransactionEntry> get _statisticsEntries =>
      isStatisticsCurrentMonth ? _transactions : _statisticsTransactions;

  List<TransactionEntry> get _statisticsPreviousEntries =>
      isStatisticsCurrentMonth
          ? _previousMonthTransactions
          : _statisticsPreviousTransactions;

  double get statisticsIncome => _sumByType(_statisticsEntries, 'income');

  double get statisticsExpenses => _sumByType(_statisticsEntries, 'expense');

  double get statisticsNetResult => statisticsIncome - statisticsExpenses;

  double? get statisticsIncomeChangePercent => _percentChange(
        _sumByType(_statisticsPreviousEntries, 'income'),
        statisticsIncome,
      );

  double? get statisticsExpenseChangePercent => _percentChange(
        _sumByType(_statisticsPreviousEntries, 'expense'),
        statisticsExpenses,
      );

  double? get statisticsNetResultChangePercent {
    final previousNet = _sumByType(_statisticsPreviousEntries, 'income') -
        _sumByType(_statisticsPreviousEntries, 'expense');
    return _percentChange(previousNet, statisticsNetResult);
  }

  List<CategoryTotal> get statisticsCategoryBreakdown =>
      _breakdownOf(_statisticsEntries);

  /// Signed sum of uncontrolled adjustments for the statistics month across
  /// all accounts (negative is an expense, positive an income).
  double get statisticsUncontrolledTotal => isStatisticsCurrentMonth
      ? _currentMonthUncontrolledTotal
      : _statisticsUncontrolledTotal;

  /// False when the total is zero within rounding.
  bool get statisticsHasUncontrolledTotal =>
      statisticsUncontrolledTotal.abs() >= 0.005;

  /// Selects the statistics month and loads it with its previous month.
  /// The current month is already loaded, so no fetch is made for it.
  Future<void> loadStatisticsMonth(DateTime month) async {
    final target = DateTime(month.year, month.month);

    if (target == statisticsMonth &&
        _statisticsErrorMessage == null &&
        !_isLoadingStatistics) {
      return;
    }

    final requestId = ++_statisticsRequestId;
    _statisticsErrorMessage = null;
    _statisticsTransactions = [];
    _statisticsPreviousTransactions = [];

    final now = DateTime.now();
    if (target.year == now.year && target.month == now.month) {
      _statisticsMonth = null;
      _isLoadingStatistics = false;
      notifyListeners();
      return;
    }

    _statisticsMonth = target;
    _isLoadingStatistics = true;
    notifyListeners();

    await _fetchStatisticsMonth(target, requestId);
  }

  /// Reloads a past statistics month without clearing what is shown.
  Future<void> _refreshStatisticsMonth() async {
    final month = _statisticsMonth;
    if (month == null || isStatisticsCurrentMonth) return;
    await _fetchStatisticsMonth(month, ++_statisticsRequestId);
  }

  Future<void> _fetchStatisticsMonth(DateTime month, int requestId) async {
    try {
      final results = await Future.wait([
        _repository.getForMonth(month),
        _repository.getForMonth(DateTime(month.year, month.month - 1)),
      ]);
      if (requestId != _statisticsRequestId) return;
      _statisticsTransactions = results[0];
      _statisticsPreviousTransactions = results[1];

      _statisticsUncontrolledTotal =
          await _monthlyBalanceRepository.getUncontrolledExpensesTotal(
        month: month.month,
        year: month.year,
      );
      if (requestId != _statisticsRequestId) return;

      _statisticsErrorMessage = null;
    } catch (error) {
      if (requestId != _statisticsRequestId) return;
      _statisticsErrorMessage =
          'No se pudieron cargar las estadísticas de ese mes.';
    } finally {
      if (requestId == _statisticsRequestId) {
        _isLoadingStatistics = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadCurrentMonth() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final previousMonth = DateTime(now.year, now.month - 1);
      final results = await Future.wait([
        _repository.getForMonth(now),
        _repository.getForMonth(previousMonth),
      ]);
      _transactions = results[0];
      _previousMonthTransactions = results[1];

      _currentMonthUncontrolledTotal =
          await _monthlyBalanceRepository.getUncontrolledExpensesTotal(
        month: now.month,
        year: now.year,
      );
    } catch (error) {
      _errorMessage = 'No se pudieron cargar los movimientos.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reloads the figures derived from `uncontrolled_expenses_total` (dashboard
  /// net result, statistics). Call it after that total changes outside this
  /// view model, e.g. via `AccountViewModel.applyUncontrolledAdjustment`.
  Future<void> refreshUncontrolledTotals() async {
    await loadCurrentMonth();
    await _refreshStatisticsMonth();
  }

  Future<void> loadAllTransactions() async {
    _isLoadingAll = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allTransactions = await _repository.getAll();
      _hasLoadedAll = true;
    } catch (error) {
      _errorMessage = 'No se pudieron cargar los movimientos.';
    } finally {
      _isLoadingAll = false;
      notifyListeners();
    }
  }

  /// Returns true on success; the current month is reloaded afterwards.
  Future<bool> createTransaction({
    required String userId,
    required String accountId,
    String? categoryId,
    required String type,
    required double amount,
    String? description,
    required DateTime date,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _lastCreatedTransactionId = null;
    notifyListeners();

    try {
      _lastCreatedTransactionId = await _repository.create(
        userId: userId,
        accountId: accountId,
        categoryId: categoryId,
        type: type,
        amount: amount,
        description: description,
        date: date,
      );
      await loadCurrentMonth();
      await _refreshStatisticsMonth();
      if (_hasLoadedAll) {
        await loadAllTransactions();
      }
      return true;
    } catch (error) {
      _errorMessage = 'No se pudo guardar la transacción.';
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Registra una transacción que justifica parte del saldo sin declarar
  /// (`uncontrolled_expenses_total`) de una cuenta para [month]/[year]. A
  /// diferencia de [createTransaction], no mueve `accounts.balance` — ese
  /// monto ya se aplicó cuando se registró la diferencia sin declarar —
  /// sino que descuenta el monto firmado de la transacción de
  /// `uncontrolled_expenses_total`. Devuelve true si se creó
  /// correctamente; en ese caso ya deja `_transactions` actualizado con
  /// el mes actual recargado, igual que [createTransaction].
  Future<bool> createJustifyingTransaction({
    required String userId,
    required String accountId,
    String? categoryId,
    required String type,
    required double amount,
    String? description,
    required DateTime date,
    required int month,
    required int year,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _lastCreatedTransactionId = null;
    notifyListeners();

    try {
      _lastCreatedTransactionId = await _repository.createJustifying(
        userId: userId,
        accountId: accountId,
        categoryId: categoryId,
        type: type,
        amount: amount,
        description: description,
        date: date,
        month: month,
        year: year,
      );
      await loadCurrentMonth();
      await _refreshStatisticsMonth();
      if (_hasLoadedAll) {
        await loadAllTransactions();
      }
      return true;
    } catch (error) {
      _errorMessage = 'No se pudo guardar el movimiento.';
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Creates one side of a transfer between own accounts: a single
  /// uncategorized row flagged `isTransfer` on [accountId], an expense when
  /// money leaves it and an income when money enters it.
  ///
  /// The counterpart row on the other account is not created; the user
  /// registers it manually. Returns true if the row was created.
  Future<bool> createTransfer({
    required String userId,
    required String accountId,
    required String type,
    required double amount,
    required DateTime date,
    String? description,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _lastCreatedTransactionId = null;
    notifyListeners();

    try {
      await _repository.create(
        userId: userId,
        accountId: accountId,
        type: type,
        amount: amount,
        description: description,
        date: date,
        isTransfer: true,
      );
      await loadCurrentMonth();
      await _refreshStatisticsMonth();
      if (_hasLoadedAll) {
        await loadAllTransactions();
      }
      return true;
    } catch (error) {
      _errorMessage = 'No se pudo guardar la transferencia.';
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Deletes a transaction (its balance effect is reverted server-side) and
  /// reloads the affected data. Returns true on success.
  Future<bool> deleteTransaction({
    required String userId,
    required String transactionId,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.delete(userId: userId, transactionId: transactionId);
      await loadCurrentMonth();
      await _refreshStatisticsMonth();
      if (_hasLoadedAll) {
        await loadAllTransactions();
      }
      return true;
    } catch (error) {
      _errorMessage = 'No se pudo eliminar el movimiento.';
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Edits category, description and date only. Account and amount stay fixed
  /// because they affect `accounts.balance`. Returns true on success.
  Future<bool> updateTransaction({
    required String transactionId,
    String? categoryId,
    String? description,
    required DateTime date,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.update(
        transactionId: transactionId,
        categoryId: categoryId,
        description: description,
        date: date,
      );
      await loadCurrentMonth();
      await _refreshStatisticsMonth();
      if (_hasLoadedAll) {
        await loadAllTransactions();
      }
      return true;
    } catch (error) {
      _errorMessage = 'No se pudo guardar los cambios.';
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
