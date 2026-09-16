import 'package:flutter/foundation.dart' hide Category;
import '../../data/models/category.dart';
import '../../data/repositories/category_repository.dart';

class CategoryViewModel extends ChangeNotifier {
  final CategoryRepository _repository;

  CategoryViewModel(this._repository);

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  List<Category> _categories = [];

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  List<Category> get categories => _categories;

  List<Category> byType(String type) =>
      _categories.where((c) => c.type == type).toList();

  /// Categorías de gasto con presupuesto asignado — reemplaza a la vieja
  /// tabla `budgets`.
  List<Category> get budgetedCategories =>
      _categories.where((c) => c.type == 'expense' && c.hasBudget).toList();

  Set<String> get budgetedCategoryIds =>
      budgetedCategories.map((c) => c.id).toSet();

  Future<void> loadCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await _repository.getAll();
    } catch (error) {
      _errorMessage = 'No se pudieron cargar las categorías.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCategory({
    required String userId,
    required String name,
    required String type,
    required String color,
    required String icon,
  }) async {
    return _submit(() => _repository.create(
          userId: userId,
          name: name,
          type: type,
          color: color,
          icon: icon,
        ));
  }

  Future<bool> updateCategory({
    required String id,
    required String name,
    required String type,
    required String color,
    required String icon,
  }) async {
    return _submit(() => _repository.update(
          id: id,
          name: name,
          type: type,
          color: color,
          icon: icon,
        ));
  }

  /// Asigna o edita el presupuesto de una categoría de gasto existente.
  Future<bool> setCategoryBudget({
    required String categoryId,
    required double amount,
  }) async {
    return _submit(() => _repository.updateBudget(
          id: categoryId,
          hasBudget: true,
          budgetAmount: amount,
        ));
  }

  /// Quita el presupuesto de una categoría, sin borrar la categoría.
  Future<bool> clearCategoryBudget(String categoryId) async {
    return _submit(() => _repository.updateBudget(
          id: categoryId,
          hasBudget: false,
          budgetAmount: null,
        ));
  }

  Future<bool> _submit(Future<void> Function() action) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      await loadCategories();
      return true;
    } catch (error) {
      _errorMessage = 'No se pudo guardar la categoría.';
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
