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

  Future<void> create({
    required String userId,
    required String name,
    required String type,
    required String color,
    required String icon,
  }) async {
    await _client.from('categories').insert({
      'user_id': userId,
      'name': name,
      'type': type,
      'color': color,
      'icon': icon,
    });
  }

  Future<void> update({
    required String id,
    required String name,
    required String type,
    required String color,
    required String icon,
  }) async {
    await _client.from('categories').update({
      'name': name,
      'type': type,
      'color': color,
      'icon': icon,
    }).eq('id', id);
  }
}
