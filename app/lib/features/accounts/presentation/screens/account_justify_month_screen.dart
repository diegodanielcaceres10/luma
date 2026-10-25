import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/month_filter_button.dart'
    show formatMonthLabel;
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../invoices/presentation/view_models/invoice_view_model.dart';
import '../../../services/presentation/view_models/service_view_model.dart';
import '../../../transactions/presentation/view_models/transaction_view_model.dart';
import '../../data/models/account.dart';
import '../view_models/account_view_model.dart';
import '../view_models/closed_month_justification.dart';
import '../view_models/monthly_balance_view_model.dart';
import '../widgets/balance_comparison_card.dart';
import '../widgets/closed_month_balances_step.dart';
import '../widgets/closed_month_review_step.dart';
import '../widgets/pending_movement_persistence.dart';
import '../widgets/pending_movements_section.dart';

/// Wizard to justify a closed month for an account that was never loaded in
/// it (no opening balance and no movements). Reached from Statistics.
///
/// 1. Account and the opening balance of the month. Its closing balance is
///    not typed: it is the opening balance of the following month, and
///    without it the month can't be justified.
/// 2. Movements of that month that explain the difference.
/// 3. Summary and save.
///
/// Saving creates the month's record (opening balance and the difference as
/// its uncontrolled total) and then the movements as justifying
/// transactions, which discount their amount from that total. Neither
/// `accounts.balance` nor anything of the current month is touched.
class AccountJustifyMonthScreen extends StatefulWidget {
  /// Month to justify; only its year and month are used.
  final DateTime month;
  final String userId;
  final AccountViewModel accountViewModel;
  final CategoryViewModel categoryViewModel;
  final ServiceViewModel serviceViewModel;
  final InvoiceViewModel invoiceViewModel;
  final TransactionViewModel transactionViewModel;
  final MonthlyBalanceViewModel monthlyBalanceViewModel;
  final VoidCallback onDone;

  const AccountJustifyMonthScreen({
    super.key,
    required this.month,
    required this.userId,
    required this.accountViewModel,
    required this.categoryViewModel,
    required this.serviceViewModel,
    required this.invoiceViewModel,
    required this.transactionViewModel,
    required this.monthlyBalanceViewModel,
    required this.onDone,
  });

  @override
  State<AccountJustifyMonthScreen> createState() =>
      _AccountJustifyMonthScreenState();
}

class _AccountJustifyMonthScreenState extends State<AccountJustifyMonthScreen> {
  static const _lastStep = 2;

  final _openingController = TextEditingController();
  final _movementsController = PendingMovementsController();

  /// Accounts that can be justified, decided once when the data is first
  /// known and then kept: saving gives the account a record, which would
  /// otherwise make it vanish from the list mid-flow. `null` until known.
  List<Account>? _eligible;
  String? _selectedAccountId;

  /// Closing balance of the month: the opening balance of the next month for
  /// the selected account. Never typed; null unless the status is available.
  ClosingBalanceStatus _closingStatus = ClosingBalanceStatus.noAccount;
  double? _closingBalance;

  /// Identifies the latest closing balance request, so a slow answer for a
  /// previously selected account is ignored.
  int _closingRequest = 0;

  int _currentStep = 0;
  bool _isSaving = false;

  /// Progress of a partially failed save, so a retry doesn't repeat work.
  bool _recordCreated = false;
  double _savedMovementsTotal = 0;

  late final DateTime _month = DateTime(widget.month.year, widget.month.month);
  late final DateTime _nextMonth = DateTime(_month.year, _month.month + 1);
  late final bool _isPast = ClosedMonthJustification.isPastMonth(_month);

  TransactionViewModel get _transactions => widget.transactionViewModel;
  MonthlyBalanceViewModel get _balances => widget.monthlyBalanceViewModel;

  String get _monthInSentence => formatMonthLabel(_month).toLowerCase();
  String get _nextMonthInSentence =>
      formatMonthLabel(_nextMonth).toLowerCase();

  @override
  void initState() {
    super.initState();
    _openingController.addListener(_onInputChanged);
    _movementsController.addListener(_onInputChanged);

    if (!_isPast) return;
    _transactions.addListener(_onDataChanged);
    _balances.addListener(_onDataChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _transactions.loadStatisticsMonth(_month);
      if (!_balances.openingMonthsLoaded) _balances.loadOpeningMonths();
      _freezeEligibleIfReady();
    });
  }

  @override
  void dispose() {
    _transactions.removeListener(_onDataChanged);
    _balances.removeListener(_onDataChanged);
    _openingController.removeListener(_onInputChanged);
    _openingController.dispose();
    _movementsController.removeListener(_onInputChanged);
    _movementsController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  void _onDataChanged() {
    if (mounted) _freezeEligibleIfReady();
  }

  /// The month's movements and the opening balances are both needed to know
  /// which accounts were left without loading.
  bool get _dataReady =>
      _balances.openingMonthsLoaded &&
      _transactions.statisticsMonth == _month &&
      !_transactions.isStatisticsLoading &&
      _transactions.statisticsErrorMessage == null;

  void _freezeEligibleIfReady() {
    if (_eligible != null || !_dataReady) return;

    final eligible = ClosedMonthJustification.eligibleAccounts(
      month: _month,
      activeAccounts: widget.accountViewModel.activeAccounts,
      openingMonthsByAccount: _balances.openingMonthsByAccount,
      monthEntries: _transactions.statisticsEntries,
    );

    _transactions.removeListener(_onDataChanged);
    _balances.removeListener(_onDataChanged);
    setState(() {
      _eligible = eligible;
      if (eligible.length == 1) _selectedAccountId = eligible.first.id;
    });
    if (_selectedAccountId != null) _loadClosingBalance();
  }

  void _selectAccount(String id) {
    setState(() => _selectedAccountId = id);
    _loadClosingBalance();
  }

  /// Reads the opening balance of the next month for the selected account,
  /// which is this month's closing balance.
  Future<void> _loadClosingBalance() async {
    final account = _account;
    final request = ++_closingRequest;

    if (account == null) {
      setState(() {
        _closingBalance = null;
        _closingStatus = ClosingBalanceStatus.noAccount;
      });
      return;
    }

    setState(() {
      _closingBalance = null;
      _closingStatus = ClosingBalanceStatus.loading;
    });

    final balances = await _balances.openingBalancesOfMonth(
      month: _nextMonth.month,
      year: _nextMonth.year,
    );
    if (!mounted || request != _closingRequest) return;

    final amount = balances?[account.id];
    setState(() {
      _closingBalance = amount;
      _closingStatus = balances == null
          ? ClosingBalanceStatus.failed
          : amount == null
              ? ClosingBalanceStatus.missing
              : ClosingBalanceStatus.available;
    });
  }

  Account? get _account {
    final id = _selectedAccountId;
    if (id == null) return null;
    for (final account in _eligible ?? const <Account>[]) {
      if (account.id == id) return account;
    }
    return null;
  }

  double? get _openingBalance => parseBalanceAmount(_openingController.text);

  double? get _difference {
    final opening = _openingBalance;
    final closing = _closingBalance;
    if (opening == null || closing == null) return null;
    return ClosedMonthJustification.difference(
      openingBalance: opening,
      closingBalance: closing,
    );
  }

  double get _movementsTotal =>
      _savedMovementsTotal + _movementsController.total;

  /// Part of the difference the movements don't cover: it stays as the
  /// month's uncontrolled total.
  double? get _unjustifiedRemainder {
    final difference = _difference;
    if (difference == null) return null;
    return ClosedMonthJustification.unjustifiedRemainder(
      difference: difference,
      movementsTotal: _movementsTotal,
    );
  }

  /// Without the next month's opening balance (the closing one) the month
  /// can't be justified, so the flow doesn't go past the first step.
  bool get _canLeaveFirstStep =>
      _account != null && _openingBalance != null && _closingBalance != null;

  /// Saves in this order, remembering what is done so a retry after a failure
  /// resumes instead of repeating it:
  /// 1. the month's record, with the opening balance and the difference as
  ///    its uncontrolled total (refusing to replace a record that appeared
  ///    in the meantime);
  /// 2. each movement, as a justifying transaction dated in that month.
  Future<void> _save() async {
    final account = _account;
    final opening = _openingBalance;
    final difference = _difference;
    if (account == null || opening == null || difference == null) return;
    if (_isSaving) return;

    final confirmed = await showConfirmDialog(context);
    if (!confirmed || !mounted) return;

    setState(() => _isSaving = true);

    try {
      if (!_recordCreated) {
        await _createMonthRecord(
          account: account,
          openingBalance: opening,
          difference: difference,
        );
        _recordCreated = true;
      }

      for (final movement in _movementsController.movements) {
        await saveJustifyingMovement(
          movement: movement,
          userId: widget.userId,
          accountId: account.id,
          month: _month.month,
          year: _month.year,
          transactionViewModel: _transactions,
          invoiceViewModel: widget.invoiceViewModel,
        );
        _savedMovementsTotal += movement.amount;
        _movementsController.remove(movement);
      }

      await _transactions.refreshUncontrolledTotals();
      if (!mounted) return;

      widget.onDone();
    } catch (error) {
      if (!mounted) return;
      _showFloatingSnackBar(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showFloatingSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E2922),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(
            color: AppColors.authCardBorder,
            width: 1,
          ),
        ),
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.authTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createMonthRecord({
    required Account account,
    required double openingBalance,
    required double difference,
  }) async {
    final existing = await _balances.accountIdsWithOpeningBalance(
      month: _month.month,
      year: _month.year,
    );
    if (existing == null) {
      throw Exception(
        _balances.errorMessage ??
            'No se pudo comprobar el saldo inicial del mes.',
      );
    }
    if (existing.contains(account.id)) {
      throw Exception(
        'Esta cuenta ya tiene saldo inicial en $_monthInSentence.',
      );
    }

    final created = await _balances.saveOpeningBalance(
      userId: widget.userId,
      accountId: account.id,
      openingBalance: openingBalance,
      month: _month.month,
      year: _month.year,
      uncontrolledExpensesTotal: difference,
    );
    if (!created) {
      throw Exception(
        _balances.errorMessage ?? 'No se pudo guardar el saldo inicial.',
      );
    }
  }

  Widget _buildMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.authTextSecondary,
        ),
      ),
    );
  }

  Widget _buildStepContent(
    List<Account> accounts,
    Account? account,
    String currency,
  ) {
    switch (_currentStep) {
      case 0:
        return ClosedMonthBalancesStep(
          accounts: accounts,
          selectedAccountId: _selectedAccountId,
          onSelectAccount: _isSaving ? null : _selectAccount,
          openingController: _openingController,
          closingBalance: _closingBalance,
          closingStatus: _closingStatus,
          onRetryClosing: _isSaving ? null : _loadClosingBalance,
          currency: currency,
          monthLabel: _monthInSentence,
          nextMonthLabel: _nextMonthInSentence,
          difference: _difference,
        );
      case 1:
        final remainder = _unjustifiedRemainder;
        return PendingMovementsSection(
          controller: _movementsController,
          currentAccount: account!,
          accountViewModel: widget.accountViewModel,
          categoryViewModel: widget.categoryViewModel,
          serviceViewModel: widget.serviceViewModel,
          invoiceViewModel: widget.invoiceViewModel,
          currency: currency,
          title: 'Movimientos de $_monthInSentence',
          enabled: !_isSaving,
          dateRange: DateTimeRange(
            start: _month,
            end: DateTime(_month.year, _month.month + 1, 0),
          ),
          existingTransactions: _transactions.allTransactions,
          helperText: remainder == null
              ? null
              : Text(
                  remainder.abs() < kRemainderEpsilon
                      ? 'Ya justificaste toda la diferencia.'
                      : 'Todavía falta justificar '
                          '${remainder > 0 ? '+' : ''}'
                          '${formatCurrency(remainder, currency)}.',
                  style: TextStyle(
                    fontSize: 12,
                    color: remainder.abs() < kRemainderEpsilon
                        ? AppColors.authAccent
                        : AppColors.authTextSecondary,
                  ),
                ),
        );
      default:
        return ClosedMonthReviewStep(
          movements: _movementsController.movements,
          openingBalance: _openingBalance,
          closingBalance: _closingBalance,
          difference: _difference,
          movementsTotal: _movementsTotal,
          remainder: _unjustifiedRemainder,
          currency: currency,
          monthLabel: _monthInSentence,
        );
    }
  }

  Widget _buildStepProgress() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.authAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.authAccent.withValues(alpha: 0.30),
              ),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              size: 18,
              color: AppColors.authAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _account?.name ?? 'Justificación mensual',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.authTextPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Ciclo de $_monthInSentence',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.authTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.authCardBorder.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.authCardBorder),
            ),
            child: Text(
              'Paso ${_currentStep + 1} de ${_lastStep + 1}',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.authTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepNav() {
    final isFirstStep = _currentStep == 0;
    final isLastStep = _currentStep == _lastStep;

    final VoidCallback? onNext;
    if (_isSaving) {
      onNext = null;
    } else if (isLastStep) {
      onNext = _save;
    } else if (isFirstStep && !_canLeaveFirstStep) {
      onNext = null;
    } else {
      onNext = () => setState(() => _currentStep += 1);
    }

    final nextButton = PrimaryButton(
      label: isLastStep ? 'Guardar' : 'Siguiente',
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      disabledAlpha: 0.4,
      padding: const EdgeInsets.symmetric(vertical: 16),
      isLoading: isLastStep && _isSaving,
      onPressed: onNext,
    );

    if (isFirstStep) {
      return SizedBox(width: double.infinity, child: nextButton);
    }

    final backButton = SecondaryButton(
      label: 'Atrás',
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      padding: const EdgeInsets.symmetric(vertical: 16),
      onPressed: _isSaving || _recordCreated
          ? null
          : () => setState(() => _currentStep -= 1),
    );

    return Row(
      children: [
        Expanded(child: backButton),
        const SizedBox(width: 12),
        Expanded(child: nextButton),
      ],
    );
  }

  List<Widget> _buildBody(String currency) {
    if (!_isPast) {
      return [_buildMessage('Solo se pueden justificar meses ya cerrados.')];
    }

    final accounts = _eligible;
    if (accounts == null) {
      if (_transactions.statisticsErrorMessage != null) {
        return [
          _buildMessage(
            'No pudimos cargar los movimientos de $_monthInSentence. '
            'Intentá de nuevo más tarde.',
          ),
        ];
      }
      return const [
        Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(color: AppColors.authAccent),
          ),
        ),
      ];
    }

    if (accounts.isEmpty) {
      return [
        _buildMessage('No hay cuentas sin cargar en $_monthInSentence.'),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: SecondaryButton(
            label: 'Volver',
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            padding: const EdgeInsets.symmetric(vertical: 14),
            onPressed: widget.onDone,
          ),
        ),
      ];
    }

    return [
      _buildStepProgress(),
      _buildStepContent(accounts, _account, currency),
      const SizedBox(height: 24),
      _buildStepNav(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final currency = widget.accountViewModel.primaryCurrency;

    return SafeArea(
      top: false,
      child: Column(
        children: [
          if (_isSaving)
            const LinearProgressIndicator(
              backgroundColor: AppColors.authCardBorder,
              color: AppColors.authAccent,
              minHeight: 3,
            ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    ScreenHeader(
                      title: 'Justificar mes',
                      subtitle: 'Cargá los saldos y movimientos de '
                          '$_monthInSentence en una cuenta que quedó sin cargar.',
                      size: ScreenHeaderSize.compact,
                      onBack: widget.onDone,
                      backEnabled: !_isSaving,
                    ),
                    const SizedBox(height: 20),
                    ..._buildBody(currency),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
