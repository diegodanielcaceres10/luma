import 'dart:async';

import 'package:luma/core/diagnostics/error_reporter.dart';
import 'package:luma/features/accounts/data/models/account.dart';
import 'package:luma/features/accounts/data/models/monthly_opening_balance.dart';
import 'package:luma/features/accounts/data/repositories/account_repository.dart';
import 'package:luma/features/accounts/data/repositories/monthly_balance_repository.dart';
import 'package:luma/features/auth/data/repositories/preferences_repository.dart';
import 'package:luma/features/invoices/data/models/invoice.dart';
import 'package:luma/features/invoices/data/repositories/invoice_repository.dart';
import 'package:luma/features/notifications/data/repositories/device_token_repository.dart';
import 'package:luma/features/notifications/data/services/local_notifications_service.dart';
import 'package:luma/features/notifications/data/services/push_messaging_service.dart';
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

  /// Month indexes (`year * 12 + month`) with an opening balance, per account.
  Map<String, Set<int>> openingMonths = {};

  /// Opening balance per account returned for any requested month.
  Map<String, double> openingBalances = {};

  /// Uncontrolled total per month (`year * 12 + month`); months without an
  /// entry return [uncontrolledExpensesTotal].
  Map<int, double> uncontrolledByMonth = {};
  Object? uncontrolledError;

  final requestedMonths = <({int month, int year})>[];
  final saved = <({String accountId, int month, int year, double amount})>[];

  /// `uncontrolledExpensesTotal` passed on each save, in call order.
  final uncontrolledTotals = <double?>[];

  @override
  Future<Map<String, Set<int>>> getOpeningMonthsByAccount() async {
    _throwIfSet(loadError);
    return {
      for (final entry in openingMonths.entries) entry.key: {...entry.value},
    };
  }

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
  Future<Map<String, double>> getOpeningBalancesByAccount({
    required int month,
    required int year,
  }) async {
    requestedMonths.add((month: month, year: year));
    _throwIfSet(loadError);
    return {...openingBalances};
  }

  @override
  Future<double> getUncontrolledExpensesTotal({
    required int month,
    required int year,
  }) async {
    _throwIfSet(uncontrolledError);
    return uncontrolledByMonth[year * 12 + month] ?? uncontrolledExpensesTotal;
  }

  @override
  Future<void> saveOpeningBalance({
    required String userId,
    required String accountId,
    required int month,
    required int year,
    required double openingBalance,
    double? uncontrolledExpensesTotal,
  }) async {
    _throwIfSet(saveError);
    saved.add((
      accountId: accountId,
      month: month,
      year: year,
      amount: openingBalance,
    ));
    uncontrolledTotals.add(uncontrolledExpensesTotal);
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

  /// Entries returned per month (`year * 12 + month`); other months are empty.
  Map<int, List<TransactionEntry>> entriesByMonth = {};
  Object? loadError;

  /// Months asked for, in call order.
  final requestedMonths = <DateTime>[];

  /// Awaited by every [getForMonth] call, to hold a request in flight.
  Future<void> Function(DateTime month)? beforeLoad;

  @override
  Future<List<TransactionEntry>> getForMonth(DateTime month) async {
    requestedMonths.add(month);
    await beforeLoad?.call(month);
    _throwIfSet(loadError);
    return List.of(entriesByMonth[month.year * 12 + month.month] ?? const []);
  }

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
  Future<void> setNotificationsEnabled(bool value) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}

/// Keeps the reports in memory so tests can check what would be sent.
class FakeErrorReporter implements ErrorReporter {
  final reports = <({Object error, String? reason, bool fatal})>[];

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    reports.add((error: error, reason: reason, fatal: fatal));
  }
}

void _throwIfSet(Object? error) {
  if (error != null) throw error;
}

/// Stands in for the push plugin. Every call is appended to [calls] so tests
/// can check the order of events across fakes.
class FakePushMessagingService implements PushMessagingService {
  FakePushMessagingService(this.calls);

  final List<String> calls;
  final _refreshes = StreamController<String>.broadcast();
  var _foreground = StreamController<PushMessage>.broadcast();

  @override
  bool isSupported = true;

  /// False simulates web, where foreground messages are not shown by the app.
  bool foregroundSupported = true;

  @override
  bool get showsForegroundMessages => isSupported && foregroundSupported;
  String? token = 'token-a';
  Object? getTokenError;
  Object? deleteTokenError;

  /// When set, `getToken` never answers until it completes.
  Completer<String?>? holdGetToken;

  /// Browser permission (web). Not recorded in [calls]: it is not part of the
  /// token order the tests check.
  bool permissionGranted = true;
  Object? permissionError;
  int permissionRequests = 0;

  /// When set, `requestPermission` waits for it, like a user taking a while
  /// to answer the prompt.
  Completer<void>? holdPermission;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    if (permissionError != null) throw permissionError!;
    await holdPermission?.future;
    return permissionGranted;
  }

  @override
  String get platform => 'android';

  /// Simulates FCM rotating the token.
  void emitRefresh(String newToken) => _refreshes.add(newToken);

  /// Simulates a push message arriving while the app is open.
  void emitForeground(PushMessage message) => _foreground.add(message);

  void emitForegroundError(Object error) => _foreground.addError(error);

  /// Simulates the foreground stream ending; the next listener gets a new one.
  Future<void> endForeground() async {
    final ended = _foreground;
    _foreground = StreamController<PushMessage>.broadcast();
    await ended.close();
  }

  @override
  Future<String?> getToken() async {
    calls.add('getToken');
    if (getTokenError != null) throw getTokenError!;
    if (holdGetToken != null) return holdGetToken!.future;
    return token;
  }

  @override
  Stream<String> get onTokenRefresh => _refreshes.stream;

  @override
  Stream<PushMessage> get onForegroundMessage {
    calls.add('onForegroundMessage');
    return _foreground.stream;
  }

  @override
  Future<void> deleteToken() async {
    calls.add('deleteToken');
    if (deleteTokenError != null) throw deleteTokenError!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}

/// Keeps what would be shown to the user instead of calling the plugin.
class RecordingLocalNotificationsService implements LocalNotificationsService {
  final shown = <({int id, String title, String body})>[];
  Object? showError;

  @override
  Future<void> showPush({
    required int id,
    required String title,
    required String body,
  }) async {
    if (showError != null) throw showError!;
    shown.add((id: id, title: title, body: body));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}

/// Records token writes in [calls] instead of calling Supabase.
class FakeDeviceTokenRepository implements DeviceTokenRepository {
  FakeDeviceTokenRepository(this.calls);

  final List<String> calls;
  Object? registerError;
  Object? unregisterError;

  /// When set, `register` never answers until it completes.
  Completer<void>? holdRegister;

  @override
  Future<void> register({
    required String token,
    required String platform,
  }) async {
    calls.add('register:$token:$platform');
    if (registerError != null) throw registerError!;
    await holdRegister?.future;
  }

  @override
  Future<void> unregister(String token) async {
    calls.add('unregister:$token');
    if (unregisterError != null) throw unregisterError!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}
