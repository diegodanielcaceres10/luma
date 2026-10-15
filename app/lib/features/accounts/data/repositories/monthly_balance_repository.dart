import '../services/monthly_balance_service.dart';

class MonthlyBalanceRepository {
  final MonthlyBalanceService _service;

  MonthlyBalanceRepository(this._service);

  Future<Set<String>> getExistingAccountIds({
    required int month,
    required int year,
  }) {
    return _service.fetchExistingAccountIds(month: month, year: year);
  }

  Future<double> getUncontrolledExpensesTotal({
    required int month,
    required int year,
  }) {
    return _service.fetchUncontrolledExpensesTotal(month: month, year: year);
  }

  Future<Map<String, Set<int>>> getOpeningMonthsByAccount() {
    return _service.fetchOpeningMonthsByAccount();
  }

  Future<void> saveOpeningBalance({
    required String userId,
    required String accountId,
    required int month,
    required int year,
    required double openingBalance,
    double? uncontrolledExpensesTotal,
  }) {
    return _service.saveOpeningBalance(
      userId: userId,
      accountId: accountId,
      month: month,
      year: year,
      openingBalance: openingBalance,
      uncontrolledExpensesTotal: uncontrolledExpensesTotal,
    );
  }
}
