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
        .select(
          '*, categories(id, name, color), accounts(id, name)',
        )
        .gte('date', _formatDate(start))
        .lt('date', _formatDate(end))
        .order('date', ascending: false)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => TransactionEntry.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Fetches the non-transfer transactions of one category dated on or
  /// after [since], newest first.
  Future<List<TransactionEntry>> fetchForCategory({
    required String categoryId,
    required DateTime since,
  }) async {
    final rows = await _client
        .from('transactions')
        .select(
          '*, categories(id, name, color), accounts(id, name)',
        )
        .eq('category_id', categoryId)
        .eq('is_transfer', false)
        .gte('date', _formatDate(since))
        .order('date', ascending: false);

    return (rows as List)
        .map((row) => TransactionEntry.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Fetches the latest [limit] transactions, newest first.
  Future<List<TransactionEntry>> fetchAll({int limit = 200}) async {
    final rows = await _client
        .from('transactions')
        .select(
          '*, categories(id, name, color), accounts(id, name)',
        )
        .order('date', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List)
        .map((row) => TransactionEntry.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Creates a transaction and returns its id.
  ///
  /// Uses the `create_transaction` RPC so the insert and the
  /// `accounts.balance` update are atomic.
  Future<String> createTransaction({
    required String userId,
    required String accountId,
    String? categoryId,
    required String type,
    required double amount,
    String? description,
    required DateTime date,
    bool isTransfer = false,
  }) async {
    final id = await _client.rpc('create_transaction', params: {
      'p_user_id': userId,
      'p_account_id': accountId,
      'p_category_id': categoryId,
      'p_type': type,
      'p_amount': amount,
      'p_description': description,
      'p_date': _formatDate(date),
      'p_is_transfer': isTransfer,
    });

    return id as String;
  }

  /// Registers a transaction that justifies part of an account's
  /// uncontrolled (undeclared) balance for [month]/[year]. Calls the RPC
  /// `create_justifying_transaction` instead of `create_transaction`: it
  /// inserts the row but does NOT touch `accounts.balance` — that amount
  /// was already applied to it when the uncontrolled difference was first
  /// registered — and instead discounts the transaction's signed amount
  /// from `monthly_account_balances.uncontrolled_expenses_total`, in a
  /// single atomic operation.
  Future<String> createJustifyingTransaction({
    required String userId,
    required String accountId,
    String? categoryId,
    required String type,
    required double amount,
    String? description,
    required DateTime date,
    required int month,
    required int year,
  }) async {
    final id = await _client.rpc('create_justifying_transaction', params: {
      'p_user_id': userId,
      'p_account_id': accountId,
      'p_category_id': categoryId,
      'p_type': type,
      'p_amount': amount,
      'p_description': description,
      'p_date': _formatDate(date),
      'p_month': month,
      'p_year': year,
    });

    return id as String;
  }

  /// Updates category, description and date only. Account and amount are not
  /// editable because they affect `accounts.balance`.
  Future<void> updateTransaction({
    required String transactionId,
    String? categoryId,
    String? description,
    required DateTime date,
  }) async {
    await _client.from('transactions').update({
      'category_id': categoryId,
      'description': description,
      'date': _formatDate(date),
    }).eq('id', transactionId);
  }

  /// Deletes a transaction through the `delete_transaction` RPC, which also
  /// reverts its effect on `accounts.balance` atomically.
  Future<void> deleteTransaction({
    required String userId,
    required String transactionId,
  }) async {
    await _client.rpc('delete_transaction', params: {
      'p_user_id': userId,
      'p_transaction_id': transactionId,
    });
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
