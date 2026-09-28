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
    bool hasBudget = false,
    double? budgetAmount,
  }) async {
    await _client.from('categories').insert({
      'user_id': userId,
      'name': name,
      'type': type,
      'color': color,
      'has_budget': hasBudget,
      'budget_amount': hasBudget ? budgetAmount : null,
    });
  }

  Future<void> update({
    required String id,
    required String name,
    required String type,
    required String color,
    bool hasBudget = false,
    double? budgetAmount,
  }) async {
    await _client.from('categories').update({
      'name': name,
      'type': type,
      'color': color,
      'has_budget': hasBudget,
      'budget_amount': hasBudget ? budgetAmount : null,
    }).eq('id', id);
  }

  /// Sets, edits or clears a category's budget without touching its other
  /// fields. The budget lives on the category itself (`has_budget` +
  /// `budget_amount`).
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
