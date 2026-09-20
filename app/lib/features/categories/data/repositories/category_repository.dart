import '../models/category.dart';
import '../services/category_service.dart';

class CategoryRepository {
  final CategoryService _service;

  CategoryRepository(this._service);

  Future<List<Category>> getAll() {
    return _service.fetchAll();
  }

  Future<void> create({
    required String userId,
    required String name,
    required String type,
    required String color,
    bool hasBudget = false,
    double? budgetAmount,
  }) {
    return _service.create(
      userId: userId,
      name: name,
      type: type,
      color: color,
      hasBudget: hasBudget,
      budgetAmount: budgetAmount,
    );
  }

  Future<void> update({
    required String id,
    required String name,
    required String type,
    required String color,
    bool hasBudget = false,
    double? budgetAmount,
  }) {
    return _service.update(
      id: id,
      name: name,
      type: type,
      color: color,
      hasBudget: hasBudget,
      budgetAmount: budgetAmount,
    );
  }

  Future<void> updateBudget({
    required String id,
    required bool hasBudget,
    double? budgetAmount,
  }) {
    return _service.updateBudget(
      id: id,
      hasBudget: hasBudget,
      budgetAmount: budgetAmount,
    );
  }
}
