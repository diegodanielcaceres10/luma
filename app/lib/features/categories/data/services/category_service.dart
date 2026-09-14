import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';

class CategoryService {
  final SupabaseClient _client;

  CategoryService(this._client);

  Future<List<Category>> fetchAll() async {
    final rows = await _client.from('categories').select().order('name');

    return (rows as List)
        .map((row) => Category.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}
