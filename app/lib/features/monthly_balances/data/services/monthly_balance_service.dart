import 'package:supabase_flutter/supabase_flutter.dart';

class MonthlyBalanceService {
  final SupabaseClient _client;

  MonthlyBalanceService(this._client);

  /// IDs de las cuentas que ya tienen saldo inicial cargado para ese
  /// mes/año. Se usa para saber qué cuentas todavía necesitan que el
  /// usuario complete el dato a mano.
  Future<Set<String>> fetchExistingAccountIds({
    required int month,
    required int year,
  }) async {
    final rows = await _client
        .from('monthly_account_balances')
        .select('account_id')
        .eq('month', month)
        .eq('year', year);

    return (rows as List).map((row) => row['account_id'] as String).toSet();
  }

  /// Suma de `uncontrolled_expenses_total` de todas las cuentas del
  /// usuario para ese mes/año — el acumulado (con signo) de ajustes sin
  /// declarar que dejó "Actualizar saldo" (ver
  /// `AccountViewModel.applyUncontrolledAdjustment`). Se usa en
  /// Estadísticas en vez de la vieja suma de transacciones sin
  /// categoría, porque esos ajustes ya no generan ninguna transacción.
  Future<double> fetchUncontrolledExpensesTotal({
    required int month,
    required int year,
  }) async {
    final rows = await _client
        .from('monthly_account_balances')
        .select('uncontrolled_expenses_total')
        .eq('month', month)
        .eq('year', year);

    return (rows as List).fold<double>(
      0,
      (sum, row) =>
          sum + (row['uncontrolled_expenses_total'] as num).toDouble(),
    );
  }

  Future<void> saveOpeningBalance({
    required String userId,
    required String accountId,
    required int month,
    required int year,
    required double openingBalance,
  }) async {
    await _client.from('monthly_account_balances').upsert(
      {
        'user_id': userId,
        'account_id': accountId,
        'month': month,
        'year': year,
        'opening_balance': openingBalance,
      },
      onConflict: 'account_id,month,year',
    );
  }
}
