import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/account.dart';
import '../../data/repositories/account_repository.dart';

enum AccountSubmitError { duplicate, generic }

class AccountViewModel extends ChangeNotifier {
  final AccountRepository _repository;

  AccountViewModel(this._repository);

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  AccountSubmitError? _submitError;
  List<Account> _accounts = [];

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  AccountSubmitError? get submitError => _submitError;
  List<Account> get accounts => _accounts;

  /// Cuentas activas — para elegir cuenta en una transacción nueva o para
  /// el aviso de saldo inicial del mes. La lista completa (con inactivas)
  /// se usa solo en la pantalla "Cuentas", donde se pueden reactivar.
  List<Account> get activeAccounts =>
      _accounts.where((account) => account.isActive).toList();

  // Las inactivas quedan afuera del total: siguen visibles en la lista,
  // pero ya no representan plata disponible.
  double get totalBalance => _accounts
      .where((account) => account.isActive)
      .fold(0, (sum, account) => sum + account.balance);

  //
  // cuentas ya no tienen moneda propia (se removió para no mezclar
  // cálculos), así que se usa un valor fijo hasta que exista esa config.
  String get primaryCurrency => 'EUR';

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
    required double balance,
    String? color,
  }) async {
    return _submit(() => _repository.create(
          userId: userId,
          name: name,
          balance: balance,
          color: color,
        ));
  }

  Future<bool> updateAccount({
    required String id,
    required String name,
    String? color,
  }) async {
    return _submit(() => _repository.update(
          id: id,
          name: name,
          color: color,
        ));
  }

  /// Inactiva o reactiva una cuenta desde la lista.
  Future<bool> toggleActive(String id, bool isActive) async {
    return _submit(
      () => _repository.setActive(id: id, isActive: isActive),
    );
  }

  Future<bool> _submit(Future<void> Function() action) async {
    _isSubmitting = true;
    _errorMessage = null;
    _submitError = null;
    notifyListeners();

    try {
      await action();
      await loadAccounts();
      return true;
    } on PostgrestException catch (e) {
      // Unique constraint violation: code 23505 covers duplicate key errors.
      if (e.code == '23505') {
        _submitError = AccountSubmitError.duplicate;
        _errorMessage = 'Ya existe una cuenta con ese nombre.';
      } else {
        _submitError = AccountSubmitError.generic;
        _errorMessage = 'No se pudo guardar la cuenta.';
      }
      notifyListeners();
      return false;
    } catch (_) {
      _submitError = AccountSubmitError.generic;
      _errorMessage = 'No se pudo guardar la cuenta.';
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
