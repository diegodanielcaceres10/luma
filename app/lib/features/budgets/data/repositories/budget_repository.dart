import '../models/budget.dart';
import '../services/budget_service.dart';

class BudgetRepository {
  final BudgetService _service;

  BudgetRepository(this._service);

  Future<List<Budget>> getAll() {
    return _service.fetchAll();
  }

  Future<void> create({
    required String userId,
    required String categoryId,
    required double amount,
  }) {
    return _service.create(
      userId: userId,
      categoryId: categoryId,
      amount: amount,
    );
  }

  Future<void> update({
    required String id,
    required String categoryId,
    required double amount,
  }) {
    return _service.update(id: id, categoryId: categoryId, amount: amount);
  }
}
