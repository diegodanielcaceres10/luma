import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/account.dart';

class AccountService {
  final SupabaseClient _client;

  AccountService(this._client);

  Future<List<Account>> fetchAccounts() async {
    // Trae activas e inactivas: la lista de cuentas es donde se
    // inactivan/reactivan, así que necesita ver ambos estados.
    final rows = await _client.from('accounts').select().order('name');

    return (rows as List)
        .map((row) => Account.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> create({
    required String userId,
    required String name,
    required double balance,
  }) async {
    final inserted = await _client
        .from('accounts')
        .insert({
          'user_id': userId,
          'name': name,
          'balance': balance,
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
  }) async {
    // El balance no se edita a mano desde acá: se mantiene a través de los
    // movimientos registrados. Si en algún momento hace falta un ajuste
    // manual de saldo, conviene resolverlo con una transacción de ajuste,
    // no pisando el valor directamente.
    await _client.from('accounts').update({
      'name': name,
    }).eq('id', id);
  }

  /// Activa o inactiva una cuenta desde la lista, sin pasar por el
  /// formulario completo.
  Future<void> setActive({required String id, required bool isActive}) async {
    await _client.from('accounts').update({'is_active': isActive}).eq('id', id);
  }
}
