import 'package:flutter/foundation.dart' hide Category;
import '../../data/models/category.dart';
import '../../data/repositories/category_repository.dart';

class CategoryViewModel extends ChangeNotifier {
  final CategoryRepository _repository;

  CategoryViewModel(this._repository);

  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  List<Category> _categories = [];

  bool get isLoading => _isLoading;

  /// `true` once the list has loaded successfully at least once, to tell
  /// "not loaded yet" apart from "loaded and missing" (see EntityRouteGuard).
  bool get hasLoaded => _hasLoaded;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  List<Category> get categories => _categories;

  List<Category> byType(String type) =>
      _categories.where((c) => c.type == type).toList();

  /// Looks up a category by id, for features that only store `category_id`.
  Category? categoryById(String? id) {
    if (id == null) return null;
    for (final category in _categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  /// Expense categories that have a budget assigned.
  List<Category> get budgetedCategories =>
      _categories.where((c) => c.type == 'expense' && c.hasBudget).toList();

  Future<void> loadCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await _repository.getAll();
      // Postgres `order('name')` is case-sensitive; re-sort ignoring case
      // (same as AccountViewModel.loadAccounts).
      _categories.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      _hasLoaded = true;
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
    bool hasBudget = false,
    double? budgetAmount,
  }) async {
    return _submit(() => _repository.create(
          userId: userId,
          name: name,
          type: type,
          color: color,
          hasBudget: hasBudget,
          budgetAmount: budgetAmount,
        ));
  }

  Future<bool> updateCategory({
    required String id,
    required String name,
    required String type,
    required String color,
    bool hasBudget = false,
    double? budgetAmount,
  }) async {
    return _submit(() => _repository.update(
          id: id,
          name: name,
          type: type,
          color: color,
          hasBudget: hasBudget,
          budgetAmount: budgetAmount,
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
