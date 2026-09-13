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
}
