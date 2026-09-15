import '../models/account.dart';
import '../services/account_service.dart';

class AccountRepository {
  final AccountService _service;

  AccountRepository(this._service);

  Future<List<Account>> getAccounts() {
    return _service.fetchAccounts();
  }

  Future<void> create({
    required String userId,
    required String name,
    required String currency,
    required double balance,
    String? color,
    String? icon,
  }) {
    return _service.create(
      userId: userId,
      name: name,
      currency: currency,
      balance: balance,
      color: color,
      icon: icon,
    );
  }

  Future<void> update({
    required String id,
    required String name,
    required String currency,
    String? color,
    String? icon,
  }) {
    return _service.update(
      id: id,
      name: name,
      currency: currency,
      color: color,
      icon: icon,
    );
  }

  Future<void> delete(String id) {
    return _service.deactivate(id);
  }
}
