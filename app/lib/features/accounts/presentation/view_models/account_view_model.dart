import 'package:flutter/foundation.dart';
import '../../data/models/account.dart';
import '../../data/repositories/account_repository.dart';

class AccountViewModel extends ChangeNotifier {
  final AccountRepository _repository;

  AccountViewModel(this._repository);

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  List<Account> _accounts = [];

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  List<Account> get accounts => _accounts;

  double get totalBalance =>
      _accounts.fold(0, (sum, account) => sum + account.balance);

  String get primaryCurrency =>
      _accounts.isNotEmpty ? _accounts.first.currency : 'USD';

  Future<void> loadAccounts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _accounts = await _repository.getAccounts();
    } catch (error) {
      _errorMessage = 'No se pudieron cargar las cuentas.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createAccount({
    required String userId,
    required String name,
    required String currency,
    required double balance,
    String? color,
    String? icon,
  }) async {
    return _submit(() => _repository.create(
          userId: userId,
          name: name,
          currency: currency,
          balance: balance,
          color: color,
          icon: icon,
        ));
  }

  Future<bool> updateAccount({
    required String id,
    required String name,
    required String currency,
    String? color,
    String? icon,
  }) async {
    return _submit(() => _repository.update(
          id: id,
          name: name,
          currency: currency,
          color: color,
          icon: icon,
        ));
  }

  Future<bool> deleteAccount(String id) async {
    return _submit(() => _repository.delete(id));
  }

  Future<bool> _submit(Future<void> Function() action) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      await loadAccounts();
      return true;
    } catch (error) {
      _errorMessage = 'No se pudo guardar la cuenta.';
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
