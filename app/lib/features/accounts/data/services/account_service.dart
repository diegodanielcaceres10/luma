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
    final inserted = await _client
        .from('accounts')
        .insert({
          'user_id': userId,
          'name': name,
          'currency': currency,
          'balance': balance,
          'color': color,
          'icon': icon,
        })
        .select('id')
        .single();

    final accountId = inserted['id'] as String;
    final now = DateTime.now();

    // El saldo inicial cargado en el alta de la cuenta es, por definición,
    // el saldo de apertura del mes en curso — se usa para no tener que
    // pedírselo de nuevo al usuario la primera vez que abre esa cuenta.
    await _client.from('monthly_account_balances').insert({
      'user_id': userId,
      'account_id': accountId,
      'month': now.month,
      'year': now.year,
      'opening_balance': balance,
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
