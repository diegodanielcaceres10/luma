import '../models/account.dart';
import '../services/account_service.dart';

class AccountRepository {
  final AccountService _service;

  AccountRepository(this._service);

  Future<List<Account>> getAccounts() {
    return _service.fetchAccounts();
  }
}
