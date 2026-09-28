import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/account.dart';

class AccountService {
  final SupabaseClient _client;

  AccountService(this._client);

  Future<List<Account>> fetchAccounts() async {
    // Fetches active and inactive accounts: the accounts list is where they
    // are deactivated/reactivated, so it needs to see both states.
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

    // The initial balance entered when creating the account is, by
    // definition, the opening balance of the current month — it is used so
    // the user isn't asked for it again the first time they open that
    // account.
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
    // The balance is not edited by hand here: it is maintained through the
    // registered movements. If a manual balance adjustment is ever needed,
    // it is better to resolve it with an adjustment transaction rather than
    // overwriting the value directly.
    await _client.from('accounts').update({
      'name': name,
    }).eq('id', id);
  }

  /// Activates or deactivates an account from the list, without going
  /// through the full form.
  Future<void> setActive({required String id, required bool isActive}) async {
    await _client.from('accounts').update({'is_active': isActive}).eq('id', id);
  }

  /// Adjusts `balance` by [amount] (may be negative or positive) and adds
  /// that same amount to `monthly_account_balances.uncontrolled_expenses_total`
  /// for the given month/year, in a single atomic operation.
  ///
  /// Used by "Update balance" for the part of the difference that no loaded
  /// movement explains: unlike [createTransaction] in `TransactionService`,
  /// this does not create any row in `transactions`.
  ///
  /// It calls the `register_uncontrolled_adjustment` RPC instead of doing
  /// the two updates separately: if something fails, neither is left
  /// half-applied.
  Future<void> applyUncontrolledAdjustment({
    required String userId,
    required String accountId,
    required double amount,
    required int month,
    required int year,
  }) async {
    await _client.rpc('register_uncontrolled_adjustment', params: {
      'p_user_id': userId,
      'p_account_id': accountId,
      'p_amount': amount,
      'p_month': month,
      'p_year': year,
    });
  }
}
