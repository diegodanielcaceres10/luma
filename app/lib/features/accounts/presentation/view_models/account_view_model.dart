import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../preferences/presentation/view_models/preferences_view_model.dart';
import '../../data/models/account.dart';
import '../../data/repositories/account_repository.dart';

enum AccountSubmitError { duplicate, generic }

class AccountViewModel extends ChangeNotifier {
  final AccountRepository _repository;
  final PreferencesViewModel _preferencesViewModel;

  AccountViewModel(this._repository, this._preferencesViewModel) {
    // The currency lives in the user's preferences (see PreferencesScreen /
    // PreferencesViewModel.setCurrencyCode), not in AccountViewModel — but
    // most screens already listen to AccountViewModel to format amounts (see
    // primaryCurrency). The change is forwarded here so those screens update
    // on their own when the currency changes, without having to add
    // PreferencesViewModel to each of them.
    _preferencesViewModel.addListener(notifyListeners);
  }

  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  AccountSubmitError? _submitError;
  List<Account> _accounts = [];
  final Map<String, double> _uncontrolledTotals = {};

  bool get isLoading => _isLoading;

  /// `true` once the accounts list has loaded successfully at least once.
  /// Used to tell "the accounts haven't arrived yet" apart from "the accounts
  /// arrived and this one doesn't exist" (see AccountRouteGuard).
  bool get hasLoaded => _hasLoaded;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  AccountSubmitError? get submitError => _submitError;
  List<Account> get accounts => _accounts;

  /// Active accounts — for picking an account in a new transaction or for
  /// the month's initial balance notice. The full list (including inactive
  /// ones) is only used in the "Accounts" screen, where they can be
  /// reactivated.
  List<Account> get activeAccounts =>
      _accounts.where((account) => account.isActive).toList();

  // Inactive accounts are left out of the total: they remain visible in the
  // list, but no longer represent available money.
  double get totalBalance => _accounts
      .where((account) => account.isActive)
      .fold(0, (sum, account) => sum + account.balance);

  // Accounts no longer have their own currency (removed to avoid mixing
  // calculations): the currency chosen in Preferences is used across the app.
  String get primaryCurrency => _preferencesViewModel.preferences.currencyCode;

  /// Signed `uncontrolled_expenses_total` of [accountId] for the current
  /// month, or 0 if it has not been loaded (see [loadUncontrolledTotal]).
  double uncontrolledTotalOf(String accountId) =>
      _uncontrolledTotals[accountId] ?? 0;

  /// Loads the current month's uncontrolled total of [accountId]. A failure
  /// is ignored on purpose: it is secondary information, and the previous
  /// value (if any) is kept.
  Future<void> loadUncontrolledTotal(String accountId) async {
    final now = DateTime.now();
    try {
      _uncontrolledTotals[accountId] = await _repository.getUncontrolledTotal(
        accountId: accountId,
        month: now.month,
        year: now.year,
      );
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadAccounts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _accounts = await _repository.getAccounts();
      // Supabase/Postgres `order('name')` is case-sensitive (it sorts by
      // character code), so an account with a capital initial can end up
      // before others that come first alphabetically. It is re-sorted here,
      // case-insensitively, so the list is truly alphabetical — this affects
      // this list and everything derived from it (account selectors in
      // movements, transfers, etc.).
      _accounts.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      _hasLoaded = true;
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
  }) async {
    return _submit(() => _repository.create(
          userId: userId,
          name: name,
          balance: balance,
        ));
  }

  Future<bool> updateAccount({
    required String id,
    required String name,
  }) async {
    return _submit(() => _repository.update(
          id: id,
          name: name,
        ));
  }

  /// Deactivates or reactivates an account from the list.
  Future<bool> toggleActive(String id, bool isActive) async {
    return _submit(
      () => _repository.setActive(id: id, isActive: isActive),
    );
  }

  /// Adjusts the balance of account [accountId] by [amount] (may be negative
  /// or positive) and accumulates that same amount into
  /// `monthly_account_balances.uncontrolled_expenses_total` for the given
  /// month/year — without creating any transaction. Used by "Update balance"
  /// for the part of the difference that no loaded movement explains (see
  /// `AccountUpdateBalanceScreen._saveAndUpdateBalance`).
  Future<bool> applyUncontrolledAdjustment({
    required String userId,
    required String accountId,
    required double amount,
    required int month,
    required int year,
  }) async {
    final success = await _submit(
      () => _repository.applyUncontrolledAdjustment(
        userId: userId,
        accountId: accountId,
        amount: amount,
        month: month,
        year: year,
      ),
      genericErrorMessage: 'No se pudo guardar el ajuste no declarado.',
    );
    if (success) await loadUncontrolledTotal(accountId);
    return success;
  }

  Future<bool> _submit(
    Future<void> Function() action, {
    String genericErrorMessage = 'No se pudo guardar la cuenta.',
  }) async {
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
        _errorMessage = genericErrorMessage;
      }
      notifyListeners();
      return false;
    } catch (_) {
      _submitError = AccountSubmitError.generic;
      _errorMessage = genericErrorMessage;
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _preferencesViewModel.removeListener(notifyListeners);
    super.dispose();
  }
}
