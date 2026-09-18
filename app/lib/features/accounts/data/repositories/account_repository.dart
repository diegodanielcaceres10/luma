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
    required double balance,
  }) {
    return _service.create(
      userId: userId,
      name: name,
      balance: balance,
    );
  }

  Future<void> update({
    required String id,
    required String name,
  }) {
    return _service.update(
      id: id,
      name: name,
    );
  }

  Future<void> setActive({required String id, required bool isActive}) {
    return _service.setActive(id: id, isActive: isActive);
  }
}
