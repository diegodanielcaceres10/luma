import 'package:flutter/foundation.dart';
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

  TransactionViewModel(this._repository);

  bool _isLoading = false;
  bool _isLoadingAll = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  List<TransactionEntry> _transactions = [];
  List<TransactionEntry> _allTransactions = [];
  bool _hasLoadedAll = false;

  bool get isLoading => _isLoading;
  bool get isLoadingAll => _isLoadingAll;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  /// Historial completo (no limitado al mes actual), para la pestaña
  /// Movimientos. Hay que llamar loadAllTransactions() antes de leerlo.
  List<TransactionEntry> get allTransactions => _allTransactions;

  List<TransactionEntry> get recentMovements => _transactions.take(4).toList();

  double get totalExpenses => _transactions
      .where((t) => t.type == 'expense')
      .fold(0, (sum, t) => sum + t.amount);

  double get totalIncome => _transactions
      .where((t) => t.type == 'income')
      .fold(0, (sum, t) => sum + t.amount);

  /// Ingresos - gastos del mes en curso. Puede ser negativo. No se
  /// persiste: se recalcula siempre a partir de los movimientos cargados
  /// con loadCurrentMonth(). Para meses ya cerrados, este mismo valor
  /// puede reconstruirse como la diferencia entre el saldo inicial de ese
  /// mes y el del mes siguiente (monthly_account_balances), sin necesidad
  /// de volver a sumar transacciones una por una.
  double get netResult => totalIncome - totalExpenses;

  List<CategoryTotal> get categoryBreakdown {
    final expenses = _transactions.where((t) => t.type == 'expense');
    final Map<String, double> totals = {};
    final Map<String, TransactionCategory> categories = {};

    for (final t in expenses) {
      final key = t.category.id ?? t.category.name;
      totals[key] = (totals[key] ?? 0) + t.amount;
      categories[key] = t.category;
    }

    final total = totalExpenses;
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

  Future<void> loadCurrentMonth() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _transactions = await _repository.getForMonth(DateTime.now());
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
    required String categoryId,
    required String type,
    required double amount,
    String? description,
    required DateTime date,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.create(
        userId: userId,
        accountId: accountId,
        categoryId: categoryId,
        type: type,
        amount: amount,
        description: description,
        date: date,
      );
      await loadCurrentMonth();
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
}
