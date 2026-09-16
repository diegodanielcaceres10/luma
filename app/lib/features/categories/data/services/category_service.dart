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

  /// Asigna, edita o quita el presupuesto de una categoría sin tocar el
  /// resto de sus campos (nombre, tipo, color, ícono). Reemplaza a la
  /// vieja tabla `budgets`: ahora el presupuesto es un dato de la propia
  /// categoría (`has_budget` + `budget_amount`).
  Future<void> updateBudget({
    required String id,
    required bool hasBudget,
    double? budgetAmount,
  }) async {
    await _client.from('categories').update({
      'has_budget': hasBudget,
      'budget_amount': budgetAmount,
    }).eq('id', id);
  }
}
