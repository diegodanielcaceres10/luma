import 'package:flutter/foundation.dart';

import '../../../../core/utils/app_clock.dart';
import '../../data/models/account.dart';
import '../../data/models/monthly_opening_balance.dart';
import '../../data/repositories/monthly_balance_repository.dart';

class MonthlyBalanceViewModel extends ChangeNotifier {
  final MonthlyBalanceRepository _repository;

  MonthlyBalanceViewModel(this._repository);

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  Set<String> _accountIdsWithBalance = {};
  bool _checked = false;
  Map<String, Set<int>> _openingMonths = {};
  bool _openingMonthsLoaded = false;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  /// True after the first check; before that it is unknown whether any
  /// balance is missing.
  bool get checked => _checked;

  /// Months that have an opening balance row, per account, as [monthIndex]
  /// values. Empty until [loadOpeningMonths] succeeds.
  Map<String, Set<int>> get openingMonthsByAccount =>
      Map.unmodifiable(_openingMonths);

  bool get openingMonthsLoaded => _openingMonthsLoaded;

  int get currentMonth => nowLocal().month;
  int get currentYear => nowLocal().year;

  /// True while the account has no opening balance for the current month.
  /// Also true before the first check, so nothing is allowed by mistake.
  bool isAccountPending(String accountId) =>
      !_accountIdsWithBalance.contains(accountId);

  /// Active accounts without an opening balance for the current month.
  List<Account> pendingAccounts(List<Account> activeAccounts) {
    return activeAccounts
        .where((account) => isAccountPending(account.id))
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

  /// Loads which months have an opening balance, for every account.
  Future<void> loadOpeningMonths() async {
    try {
      _openingMonths = await _repository.getOpeningMonthsByAccount();
      _openingMonthsLoaded = true;
    } catch (_) {
      // Optional data: whoever needs it just offers nothing until it loads.
    } finally {
      notifyListeners();
    }
  }

  /// Ids of the accounts that have an opening balance record in
  /// [month]/[year], or null (and sets [errorMessage]) if it can't be read.
  /// It doesn't touch the current-month state used by [isAccountPending].
  Future<Set<String>?> accountIdsWithOpeningBalance({
    required int month,
    required int year,
  }) async {
    _errorMessage = null;
    try {
      return await _repository.getExistingAccountIds(month: month, year: year);
    } catch (_) {
      _errorMessage = 'No se pudo comprobar el saldo inicial del mes.';
      notifyListeners();
      return null;
    }
  }

  /// Saves the opening balance of [month]/[year] (the current month by
  /// default). With [uncontrolledExpensesTotal] the row also gets that
  /// uncontrolled total; without it the stored one is kept.
  Future<bool> saveOpeningBalance({
    required String userId,
    required String accountId,
    required double openingBalance,
    int? month,
    int? year,
    double? uncontrolledExpensesTotal,
  }) async {
    final targetMonth = month ?? currentMonth;
    final targetYear = year ?? currentYear;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.saveOpeningBalance(
        userId: userId,
        accountId: accountId,
        month: targetMonth,
        year: targetYear,
        openingBalance: openingBalance,
        uncontrolledExpensesTotal: uncontrolledExpensesTotal,
      );
      // Only the current month feeds the pending state.
      if (targetMonth == currentMonth && targetYear == currentYear) {
        _accountIdsWithBalance = {..._accountIdsWithBalance, accountId};
      }
      _openingMonths = {
        ..._openingMonths,
        accountId: {
          ...?_openingMonths[accountId],
          monthIndex(targetYear, targetMonth),
        },
      };
      return true;
    } catch (error) {
      _errorMessage = 'No se pudo guardar el saldo inicial.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Creates the opening balance record of a past month for the account if it
  /// has none, so an uncontrolled adjustment can be applied to that month.
  /// Returns false (and sets [errorMessage]) if it couldn't be checked or
  /// created.
  Future<bool> ensureOpeningBalance({
    required String userId,
    required String accountId,
    required int month,
    required int year,
    required double openingBalance,
  }) async {
    _errorMessage = null;
    try {
      final existing = await _repository.getExistingAccountIds(
        month: month,
        year: year,
      );
      if (!existing.contains(accountId)) {
        await _repository.saveOpeningBalance(
          userId: userId,
          accountId: accountId,
          month: month,
          year: year,
          openingBalance: openingBalance,
        );
        _openingMonths = {
          ..._openingMonths,
          accountId: {...?_openingMonths[accountId], monthIndex(year, month)},
        };
      }
      return true;
    } catch (error) {
      _errorMessage = 'No se pudo preparar el ciclo anterior.';
      notifyListeners();
      return false;
    }
  }
}
