import 'package:flutter/foundation.dart';
import '../../data/models/account.dart';
import '../../data/repositories/account_repository.dart';

class AccountViewModel extends ChangeNotifier {
  final AccountRepository _repository;

  AccountViewModel(this._repository);

  bool _isLoading = false;
  String? _errorMessage;
  List<Account> _accounts = [];

  bool get isLoading => _isLoading;
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
}
