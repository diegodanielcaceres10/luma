import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_entry.dart';

class TransactionService {
  final SupabaseClient _client;

  TransactionService(this._client);

  Future<List<TransactionEntry>> fetchForMonth(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    final rows = await _client
        .from('transactions')
        .select('*, categories(id, name, color, icon)')
        .gte('date', _formatDate(start))
        .lt('date', _formatDate(end))
        .order('date', ascending: false)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => TransactionEntry.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> createTransaction({
    required String userId,
    required String accountId,
    required String categoryId,
    required String type,
    required double amount,
    String? description,
    required DateTime date,
  }) async {
    await _client.from('transactions').insert({
      'user_id': userId,
      'account_id': accountId,
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'description': description,
      'date': _formatDate(date),
    });
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
