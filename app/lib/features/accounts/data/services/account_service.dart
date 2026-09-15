import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/account.dart';

class AccountService {
  final SupabaseClient _client;

  AccountService(this._client);

  Future<List<Account>> fetchAccounts() async {
    final rows = await _client
        .from('accounts')
        .select()
        .eq('is_active', true)
        .order('created_at');

    return (rows as List)
        .map((row) => Account.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> create({
    required String userId,
    required String name,
    required String currency,
    required double balance,
    String? color,
    String? icon,
  }) async {
    await _client.from('accounts').insert({
      'user_id': userId,
      'name': name,
      'currency': currency,
      'balance': balance,
      'color': color,
      'icon': icon,
    });
  }

  Future<void> update({
    required String id,
    required String name,
    required String currency,
    String? color,
    String? icon,
  }) async {
    // El balance no se edita a mano desde acá: se mantiene a través de los
    // movimientos registrados. Si en algún momento hace falta un ajuste
    // manual de saldo, conviene resolverlo con una transacción de ajuste,
    // no pisando el valor directamente.
    await _client.from('accounts').update({
      'name': name,
      'currency': currency,
      'color': color,
      'icon': icon,
    }).eq('id', id);
  }
}
