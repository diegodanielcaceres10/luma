import 'package:flutter/foundation.dart' hide Category;
import '../../data/models/category.dart';
import '../../data/repositories/category_repository.dart';

class CategoryViewModel extends ChangeNotifier {
  final CategoryRepository _repository;

  CategoryViewModel(this._repository);

  bool _isLoading = false;
  String? _errorMessage;
  List<Category> _categories = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Category> get categories => _categories;

  List<Category> byType(String type) =>
      _categories.where((c) => c.type == type).toList();

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
}
