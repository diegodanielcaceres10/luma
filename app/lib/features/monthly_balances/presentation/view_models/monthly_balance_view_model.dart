import 'package:flutter/foundation.dart';

import '../../../accounts/data/models/account.dart';
import '../../data/repositories/monthly_balance_repository.dart';

class MonthlyBalanceViewModel extends ChangeNotifier {
  final MonthlyBalanceRepository _repository;

  MonthlyBalanceViewModel(this._repository);

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  Set<String> _accountIdsWithBalance = {};
  bool _checked = false;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  /// Recién después de la primera verificación tiene sentido mostrar (o
  /// no) la alerta — antes de eso no sabemos si falta algo o no.
  bool get checked => _checked;

  int get currentMonth => DateTime.now().month;
  int get currentYear => DateTime.now().year;

  /// De las cuentas activas recibidas, cuáles todavía no tienen saldo
  /// inicial cargado para el mes en curso.
  List<Account> pendingAccounts(List<Account> activeAccounts) {
    return activeAccounts
        .where((account) => !_accountIdsWithBalance.contains(account.id))
        .toList();
  }

  /// Verifica contra Supabase qué cuentas ya tienen saldo inicial este
  /// mes. Se llama al iniciar el Home/Dashboard.
  Future<void> checkCurrentMonth() async {
    _isLoading = true;
    notifyListeners();

    try {
      _accountIdsWithBalance = await _repository.getExistingAccountIds(
        month: currentMonth,
        year: currentYear,
      );
      _checked = true;
    } catch (_) {
      // Si falla la verificación no bloqueamos el dashboard — se
      // reintenta la próxima vez que se abra la app o se refresque.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveOpeningBalance({
    required String userId,
    required String accountId,
    required double openingBalance,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.saveOpeningBalance(
        userId: userId,
        accountId: accountId,
        month: currentMonth,
        year: currentYear,
        openingBalance: openingBalance,
      );
      _accountIdsWithBalance = {..._accountIdsWithBalance, accountId};
      return true;
    } catch (error) {
      _errorMessage = 'No se pudo guardar el saldo inicial.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
