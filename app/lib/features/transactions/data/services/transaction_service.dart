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
          '*, categories(id, name, color, icon), accounts(id, name, color)',
        )
        .gte('date', _formatDate(start))
        .lt('date', _formatDate(end))
        .order('date', ascending: false)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => TransactionEntry.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Trae todas las transacciones del usuario (todo el historial), más
  /// recientes primero. [limit] evita traer miles de filas de una — para
  /// paginar de verdad más adelante conviene sumar un offset/cursor.
  Future<List<TransactionEntry>> fetchAll({int limit = 200}) async {
    final rows = await _client
        .from('transactions')
        .select(
          '*, categories(id, name, color, icon), accounts(id, name, color)',
        )
        .order('date', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List)
        .map((row) => TransactionEntry.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Crea una transacción y devuelve el id de la fila creada — lo
  /// necesita, por ejemplo, el pago de una factura para vincularla.
  /// [categoryId] es nulo cuando la transacción viene de una
  /// transferencia entre cuentas propias — no pertenece a ninguna
  /// categoría de ingreso/gasto.
  ///
  /// Llama al RPC `create_transaction` en vez de insertar directo: ese
  /// RPC inserta la fila y actualiza `accounts.balance` en una sola
  /// transacción de la base — si algo falla, se revierte todo (ni queda
  /// la transacción ni el saldo se mueve a medias).
  Future<String> createTransaction({
    required String userId,
    required String accountId,
    String? categoryId,
    required String type,
    required double amount,
    String? description,
    required DateTime date,
  }) async {
    final id = await _client.rpc('create_transaction', params: {
      'p_user_id': userId,
      'p_account_id': accountId,
      'p_category_id': categoryId,
      'p_type': type,
      'p_amount': amount,
      'p_description': description,
      'p_date': _formatDate(date),
    });

    return id as String;
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
