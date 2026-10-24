// The record `.wait` extension lives in dart:async.
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../accounts/data/repositories/monthly_balance_repository.dart';
import '../../../transactions/data/repositories/transaction_repository.dart';
import 'month_comparison.dart';

/// Loads the two months being compared. It only fetches: the figures are
/// derived by [MonthComparison.compute], together with the categories,
/// services and invoices the app already keeps.
class MonthComparisonViewModel extends ChangeNotifier {
  static const loadErrorMessage = 'No se pudo cargar la comparación.';

  final TransactionRepository _transactions;
  final MonthlyBalanceRepository _monthlyBalances;

  MonthComparisonViewModel(this._transactions, this._monthlyBalances);

  DateTime? _beforeMonth;
  DateTime? _afterMonth;
  MonthSnapshot? _before;
  MonthSnapshot? _after;
  bool _isLoading = false;
  String? _errorMessage;
  int _requestId = 0;

  /// First day of the selected months; null until the first [load].
  DateTime? get beforeMonth => _beforeMonth;
  DateTime? get afterMonth => _afterMonth;

  /// Null while loading, after an error and when both months are the same.
  MonthSnapshot? get before => _before;
  MonthSnapshot? get after => _after;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get hasSameMonth =>
      _beforeMonth != null && _beforeMonth == _afterMonth;

  /// Selects the months and fetches both in parallel. The previous result is
  /// cleared right away so a stale comparison is never shown under new
  /// selectors.
  Future<void> load(DateTime before, DateTime after) async {
    final beforeMonth = DateTime(before.year, before.month);
    final afterMonth = DateTime(after.year, after.month);
    final requestId = ++_requestId;

    _beforeMonth = beforeMonth;
    _afterMonth = afterMonth;
    _before = null;
    _after = null;
    _errorMessage = null;

    if (beforeMonth == afterMonth) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final (beforeSnapshot, afterSnapshot) =
          await (_fetch(beforeMonth), _fetch(afterMonth)).wait;
      if (requestId != _requestId) return;
      _before = beforeSnapshot;
      _after = afterSnapshot;
    } catch (_) {
      if (requestId != _requestId) return;
      // Never a half comparison: either both months load or none is shown.
      _errorMessage = loadErrorMessage;
    } finally {
      if (requestId == _requestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Repeats the last [load]. Does nothing before the first one.
  Future<void> retry() async {
    final beforeMonth = _beforeMonth;
    final afterMonth = _afterMonth;
    if (beforeMonth == null || afterMonth == null) return;
    await load(beforeMonth, afterMonth);
  }

  /// Exchanges "before" and "after". Does nothing before the first [load].
  Future<void> swap() async {
    final beforeMonth = _beforeMonth;
    final afterMonth = _afterMonth;
    if (beforeMonth == null || afterMonth == null) return;
    await load(afterMonth, beforeMonth);
  }

  Future<MonthSnapshot> _fetch(DateTime month) async {
    final (entries, uncontrolledTotal) = await (
      _transactions.getForMonth(month),
      _monthlyBalances.getUncontrolledExpensesTotal(
        month: month.month,
        year: month.year,
      ),
    ).wait;
    return MonthSnapshot(
      month: month,
      entries: entries,
      uncontrolledTotal: uncontrolledTotal,
    );
  }
}
