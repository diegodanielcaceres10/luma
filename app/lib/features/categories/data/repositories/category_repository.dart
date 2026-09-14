import '../models/category.dart';
import '../services/category_service.dart';

class CategoryRepository {
  final CategoryService _service;

  CategoryRepository(this._service);

  Future<List<Category>> getAll() {
    return _service.fetchAll();
  }
}
