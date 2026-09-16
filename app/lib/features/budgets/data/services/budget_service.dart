import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/budget.dart';

class BudgetService {
  final SupabaseClient _client;

  BudgetService(this._client);

  Future<List<Budget>> fetchAll() async {
    final rows = await _client
        .from('budgets')
        .select('*, categories(name, type, color, icon)')
        .order('created_at');

    return (rows as List)
        .map((row) => Budget.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> create({
    required String userId,
    required String categoryId,
    required double amount,
  }) async {
    await _client.from('budgets').insert({
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
    });
  }

  Future<void> update({
    required String id,
    required String categoryId,
    required double amount,
  }) async {
    await _client.from('budgets').update({
      'category_id': categoryId,
      'amount': amount,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }
}
