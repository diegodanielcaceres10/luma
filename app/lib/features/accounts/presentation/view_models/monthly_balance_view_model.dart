import 'package:flutter/foundation.dart';

import '../../data/models/account.dart';
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

  /// True after the first check; before that it is unknown whether any
  /// balance is missing.
  bool get checked => _checked;

  int get currentMonth => DateTime.now().month;
  int get currentYear => DateTime.now().year;

  /// Active accounts without an opening balance for the current month.
  List<Account> pendingAccounts(List<Account> activeAccounts) {
    return activeAccounts
        .where((account) => !_accountIdsWithBalance.contains(account.id))
        .toList();
  }

  /// Loads which accounts already have an opening balance this month.
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
      // A failed check must not block the dashboard; it is retried later.
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
