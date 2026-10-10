import 'package:luma/features/accounts/data/models/account.dart';
import 'package:luma/features/accounts/data/models/monthly_opening_balance.dart';
import 'package:luma/features/accounts/data/repositories/account_repository.dart';
import 'package:luma/features/accounts/data/repositories/monthly_balance_repository.dart';
import 'package:luma/features/auth/data/repositories/preferences_repository.dart';
import 'package:luma/features/invoices/data/models/invoice.dart';
import 'package:luma/features/invoices/data/repositories/invoice_repository.dart';
import 'package:luma/features/transactions/data/models/transaction_entry.dart';
import 'package:luma/features/transactions/data/repositories/transaction_repository.dart';

// Fakes implement the repositories (Dart classes are implicit interfaces), so
// no Supabase client is needed. They fake only the methods the view models
// call; any other method fails loudly. Setting an error field makes the
// matching methods throw it.

class FakeInvoiceRepository implements InvoiceRepository {
  List<Invoice> invoices = [];
  Object? loadError;
  Object? writeError;

  int getAllCalls = 0;
  int createCalls = 0;
  final cancelledIds = <String>[];
  final paid = <({String id, String transactionId})>[];

  @override
  Future<List<Invoice>> getAll() async {
    getAllCalls++;
    _throwIfSet(loadError);
    return List.of(invoices);
  }

  @override
  Future<void> create({
    required String userId,
    required String serviceId,
    required int month,
    required int year,
    required double amount,
    DateTime? dueDate,
  }) async {
    createCalls++;
    _throwIfSet(writeError);
  }

  @override
  Future<void> cancel(String id) async {
    _throwIfSet(writeError);
    cancelledIds.add(id);
  }

  @override
  Future<void> markPaid({
    required String id,
    required String transactionId,
  }) async {
    _throwIfSet(writeError);
    paid.add((id: id, transactionId: transactionId));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}

class FakeAccountRepository implements AccountRepository {
  List<Account> accounts = [];
  double uncontrolledTotal = 0;
  List<MonthlyOpeningBalance> openingBalances = [];

  Object? loadError;
  Object? writeError;
  Object? secondaryError;

  int getAccountsCalls = 0;
  int createCalls = 0;
  final setActiveCalls = <({String id, bool isActive})>[];

  @override
  Future<List<Account>> getAccounts() async {
    getAccountsCalls++;
    _throwIfSet(loadError);
    return List.of(accounts);
  }

  @override
  Future<void> create({
    required String userId,
    required String name,
    required double balance,
  }) async {
    createCalls++;
    _throwIfSet(writeError);
  }

  @override
  Future<void> setActive({required String id, required bool isActive}) async {
    _throwIfSet(writeError);
    setActiveCalls.add((id: id, isActive: isActive));
  }

  @override
  Future<void> applyUncontrolledAdjustment({
    required String userId,
    required String accountId,
    required double amount,
    required int month,
    required int year,
  }) async {
    _throwIfSet(writeError);
  }

  @override
  Future<double> getUncontrolledTotal({
    required String accountId,
    required int month,
    required int year,
  }) async {
    _throwIfSet(secondaryError);
    return uncontrolledTotal;
  }

  @override
  Future<List<MonthlyOpeningBalance>> getOpeningBalances({
    required String accountId,
    required int months,
  }) async {
    _throwIfSet(secondaryError);
    return List.of(openingBalances);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}

class FakeMonthlyBalanceRepository implements MonthlyBalanceRepository {
  Set<String> existingIds = {};
  double uncontrolledExpensesTotal = 0;

  Object? loadError;
  Object? saveError;

  final requestedMonths = <({int month, int year})>[];
  final saved = <({String accountId, int month, int year, double amount})>[];

  @override
  Future<Set<String>> getExistingAccountIds({
    required int month,
    required int year,
  }) async {
    requestedMonths.add((month: month, year: year));
    _throwIfSet(loadError);
    return {...existingIds};
  }

  @override
  Future<double> getUncontrolledExpensesTotal({
    required int month,
    required int year,
  }) async {
    return uncontrolledExpensesTotal;
  }

  @override
  Future<void> saveOpeningBalance({
    required String userId,
    required String accountId,
    required int month,
    required int year,
    required double openingBalance,
  }) async {
    _throwIfSet(saveError);
    saved.add((
      accountId: accountId,
      month: month,
      year: year,
      amount: openingBalance,
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}

class FakeTransactionRepository implements TransactionRepository {
  String createdId = 'tx-1';
  Object? createError;

  int createCalls = 0;
  final justifying = <({int month, int year})>[];

  @override
  Future<List<TransactionEntry>> getForMonth(DateTime month) async => [];

  @override
  Future<String> create({
    required String userId,
    required String accountId,
    String? categoryId,
    required String type,
    required double amount,
    String? description,
    required DateTime date,
    bool isTransfer = false,
  }) async {
    createCalls++;
    _throwIfSet(createError);
    return createdId;
  }

  @override
  Future<String> createJustifying({
    required String userId,
    required String accountId,
    String? categoryId,
    required String type,
    required double amount,
    String? description,
    required DateTime date,
    required int month,
    required int year,
    bool isTransfer = false,
  }) async {
    _throwIfSet(createError);
    justifying.add((month: month, year: year));
    return createdId;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}

/// Avoids `SharedPreferencesAsync`, which needs a platform plugin.
class FakePreferencesRepository implements PreferencesRepository {
  @override
  Future<void> setCurrencyCode(String value) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}

void _throwIfSet(Object? error) {
  if (error != null) throw error;
}
