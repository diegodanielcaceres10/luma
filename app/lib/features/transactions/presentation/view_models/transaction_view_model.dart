import 'package:flutter/foundation.dart';
import '../../../monthly_balances/data/repositories/monthly_balance_repository.dart';
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

  // Mes que muestra Estadísticas. `null` = el mes en curso, que ya vive en
  // _transactions / _previousMonthTransactions (y se mantiene al día solo,
  // porque loadCurrentMonth() se llama tras cada movimiento nuevo). Un mes
  // distinto se carga aparte en las dos listas de abajo, para no pisar el
  // mes en curso que usan el Dashboard y "Movimientos recientes".
  DateTime? _statisticsMonth;
  List<TransactionEntry> _statisticsTransactions = [];
  List<TransactionEntry> _statisticsPreviousTransactions = [];
  bool _isLoadingStatistics = false;
  String? _statisticsErrorMessage;

  // Acumulado (con signo) de `uncontrolled_expenses_total` del mes en
  // curso y del mes elegido en Estadísticas, respectivamente — ver
  // [statisticsUncontrolledTotal].
  double _currentMonthUncontrolledTotal = 0;
  double _statisticsUncontrolledTotal = 0;

  // Identifica la carga de mes más reciente: si el usuario cambia de mes
  // varias veces seguidas, una respuesta vieja que llega tarde no debe
  // pisar los datos del mes que quedó elegido.
  int _statisticsRequestId = 0;

  bool get isLoading => _isLoading;
  bool get isLoadingAll => _isLoadingAll;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  /// Id de la última transacción creada con éxito por [createTransaction].
  /// Lo necesita, por ejemplo, el pago de una factura para vincularla a
  /// la transacción recién creada.
  String? get lastCreatedTransactionId => _lastCreatedTransactionId;

  /// Historial completo (no limitado al mes actual), para la pestaña
  /// Movimientos. Hay que llamar loadAllTransactions() antes de leerlo.
  List<TransactionEntry> get allTransactions => _allTransactions;

  List<TransactionEntry> get recentMovements => _transactions.take(4).toList();

  double get totalExpenses => _sumByType(_transactions, 'expense');

  double get totalIncome => _sumByType(_transactions, 'income');

  /// Ingresos - gastos del mes en curso. Puede ser negativo. No se
  /// persiste: se recalcula siempre a partir de los movimientos cargados
  /// con loadCurrentMonth(). Para meses ya cerrados, este mismo valor
  /// puede reconstruirse como la diferencia entre el saldo inicial de ese
  /// mes y el del mes siguiente (monthly_account_balances), sin necesidad
  /// de volver a sumar transacciones una por una.
  double get netResult => totalIncome - totalExpenses;

  /// [netResult] del mes en curso más los ajustes sin declarar de ese
  /// mismo mes (`uncontrolled_expenses_total`, ver
  /// [statisticsUncontrolledTotal]). Es lo que muestra la card "Balance
  /// general del mes" del Dashboard: a diferencia de [netResult], sí
  /// refleja los ajustes cargados desde "Actualizar saldo" que no
  /// corresponden a ninguna transacción real.
  double get netResultWithUncontrolled =>
      netResult + _currentMonthUncontrolledTotal;

  /// Mismos totales que arriba pero del mes calendario anterior, cargados
  /// junto con el mes en curso en loadCurrentMonth(). Solo existen para
  /// alimentar las comparaciones "vs. mes anterior" de Estadísticas.
  double get previousMonthIncome =>
      _sumByType(_previousMonthTransactions, 'income');

  double get previousMonthExpenses =>
      _sumByType(_previousMonthTransactions, 'expense');

  double get previousMonthNetResult =>
      previousMonthIncome - previousMonthExpenses;

  /// % de cambio vs. mes anterior. null cuando no hay base contra la que
  /// comparar (mes anterior en 0, p. ej. una cuenta recién creada) — se
  /// devuelve null en vez de 0% para no insinuar "sin cambios" cuando en
  /// realidad no hay dato previo.
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

  static double _sumByType(List<TransactionEntry> entries, String type) {
    return entries
        .where((t) => t.type == type && !t.isTransfer)
        .fold<double>(0, (sum, t) => sum + t.amount);
  }

  /// Gastos agrupados por categoría (mayor a menor), con su % del total.
  /// Excluye las transacciones de transferencia (`isTransfer`): mover
  /// plata entre cuentas propias no es un gasto real, y de todos modos no
  /// tienen categoría — contarlas acá las mostraba como "Sin categoría".
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

  // ── Estadísticas (mes elegido en el selector) ──────────────────────
  //
  // Mismos cálculos que los getters del mes en curso, pero sobre el mes que
  // esté elegido en Estadísticas (que puede ser cualquiera de los últimos
  // 12). Los comparativos "vs. mes anterior" son contra el mes previo al
  // elegido.

  /// `true` si Estadísticas está mostrando el mes en curso.
  bool get isStatisticsCurrentMonth {
    final month = _statisticsMonth;
    if (month == null) return true;
    final now = DateTime.now();
    return month.year == now.year && month.month == now.month;
  }

  /// Mes (día 1) que muestra Estadísticas.
  DateTime get statisticsMonth {
    if (isStatisticsCurrentMonth) {
      final now = DateTime.now();
      return DateTime(now.year, now.month);
    }
    return _statisticsMonth!;
  }

  /// `true` mientras se carga el mes elegido en Estadísticas.
  bool get isStatisticsLoading =>
      isStatisticsCurrentMonth ? _isLoading : _isLoadingStatistics;

  /// Error al cargar un mes anterior en Estadísticas, o `null`. Para el mes
  /// en curso no se informa acá: sigue el comportamiento de
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

  /// Acumulado (con signo) de ajustes sin declarar del mes que muestra
  /// Estadísticas — `monthly_account_balances.uncontrolled_expenses_total`
  /// sumado entre todas las cuentas (ver
  /// [MonthlyBalanceRepository.getUncontrolledExpensesTotal]). Puede ser
  /// negativo (gasto no controlado) o positivo (ingreso no controlado).
  /// Reemplaza a la vieja suma de transacciones sin categoría: los
  /// ajustes de "Actualizar saldo" ya no generan ninguna transacción.
  double get statisticsUncontrolledTotal => isStatisticsCurrentMonth
      ? _currentMonthUncontrolledTotal
      : _statisticsUncontrolledTotal;

  /// `false` cuando el total es cero (o casi, por redondeo) — para no
  /// mostrar la tarjeta de ajustes sin declarar sin nada que informar.
  bool get statisticsHasUncontrolledTotal =>
      statisticsUncontrolledTotal.abs() >= 0.005;

  /// Cambia el mes que muestra Estadísticas y carga sus datos (más los del
  /// mes previo, para los comparativos). Elegir el mes en curso no consulta
  /// nada: ya está cargado en [loadCurrentMonth].
  Future<void> loadStatisticsMonth(DateTime month) async {
    final target = DateTime(month.year, month.month);

    // Mismo mes que ya se ve, sin error que reintentar: nada que hacer.
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

  /// Vuelve a pedir el mes de Estadísticas si no es el en curso, sin vaciar
  /// lo que se ve mientras tanto. Se usa tras crear movimientos, que pueden
  /// tener fecha en ese mes.
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

  /// Devuelve true si se creó correctamente. En ese caso ya deja
  /// _transactions actualizado con el mes actual recargado.
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

  /// Registra una transferencia entre cuentas como dos transacciones sin
  /// categoría: un 'expense' en la cuenta de origen y un 'income' en la
  /// de destino, con el mismo monto — marcadas con `isTransfer: true`
  /// para que no se cuenten como ingreso/gasto real (ver
  /// [TransactionEntry.isTransfer], [_sumByType], [_breakdownOf]).
  ///
  /// Nota: cada llamada a [_repository.create] actualiza accounts.balance
  /// de forma atómica junto con su propia fila (RPC create_transaction),
  /// pero las dos llamadas de esta transferencia no son atómicas *entre
  /// sí*: si la segunda falla, la primera ya quedó confirmada y el saldo
  /// de origen queda descontado sin su contraparte en destino.
  ///
  /// Devuelve true si ambas transacciones se crearon correctamente.
  Future<bool> createTransfer({
    required String userId,
    required String originAccountId,
    required String destinationAccountId,
    required double amount,
    required DateTime date,
    String? originDescription,
    String? destinationDescription,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _lastCreatedTransactionId = null;
    notifyListeners();

    try {
      await _repository.create(
        userId: userId,
        accountId: originAccountId,
        type: 'expense',
        amount: amount,
        description: originDescription,
        date: date,
        isTransfer: true,
      );
      await _repository.create(
        userId: userId,
        accountId: destinationAccountId,
        type: 'income',
        amount: amount,
        description: destinationDescription,
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
}
