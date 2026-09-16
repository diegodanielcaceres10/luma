import 'package:flutter/foundation.dart';
import '../../data/models/budget.dart';
import '../../data/repositories/budget_repository.dart';

class BudgetViewModel extends ChangeNotifier {
  final BudgetRepository _repository;

  BudgetViewModel(this._repository);

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  List<Budget> _budgets = [];

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  List<Budget> get budgets => _budgets;

  /// Ids de categorías que ya tienen un presupuesto asignado (la tabla tiene
  /// una restricción unique(user_id, category_id), no se puede repetir).
  Set<String> get budgetedCategoryIds =>
      _budgets.map((b) => b.categoryId).toSet();

  Future<void> loadBudgets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _budgets = await _repository.getAll();
    } catch (error) {
      _errorMessage = 'No se pudieron cargar los presupuestos.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createBudget({
    required String userId,
    required String categoryId,
    required double amount,
  }) async {
    return _submit(() => _repository.create(
          userId: userId,
          categoryId: categoryId,
          amount: amount,
        ));
  }

  Future<bool> updateBudget({
    required String id,
    required String categoryId,
    required double amount,
  }) async {
    return _submit(
        () => _repository.update(id: id, categoryId: categoryId, amount: amount));
  }

  Future<bool> _submit(Future<void> Function() action) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      await loadBudgets();
      return true;
    } catch (error) {
      _errorMessage = 'No se pudo guardar el presupuesto.';
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
