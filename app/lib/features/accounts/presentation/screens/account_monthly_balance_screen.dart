import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/app_clock.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/layout/screen_header.dart';
import '../../../../core/widgets/buttons/secondary_button.dart';
import '../../../../core/widgets/buttons/text_action_button.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../invoices/presentation/view_models/invoice_view_model.dart';
import '../../../services/presentation/view_models/service_view_model.dart';
import '../../../transactions/presentation/view_models/transaction_view_model.dart';
import '../../data/models/account.dart';
import '../view_models/account_view_model.dart';
import '../view_models/monthly_balance_view_model.dart';
import '../widgets/balance_comparison_card.dart';
import '../widgets/opening_summary_card.dart';
import '../widgets/pending_movement_persistence.dart';
import '../widgets/pending_movements_section.dart';

/// Wizard to start a new month for one account that has no opening balance
/// yet. Reached from the Dashboard's per-account notice.
///
/// 1. Opening balance of the month (the stored balance is stale: it still
///    reflects the end of the previous cycle).
/// 2. Movements of the previous cycle that justify the difference.
/// 3. Summary and save.
class AccountMonthlyBalanceScreen extends StatefulWidget {
  final String userId;
  final Account account;
  final AccountViewModel accountViewModel;
  final CategoryViewModel categoryViewModel;
  final ServiceViewModel serviceViewModel;
  final InvoiceViewModel invoiceViewModel;
  final TransactionViewModel transactionViewModel;
  final MonthlyBalanceViewModel monthlyBalanceViewModel;
  final VoidCallback onDone;

  const AccountMonthlyBalanceScreen({
    super.key,
    required this.userId,
    required this.account,
    required this.accountViewModel,
    required this.categoryViewModel,
    required this.serviceViewModel,
    required this.invoiceViewModel,
    required this.transactionViewModel,
    required this.monthlyBalanceViewModel,
    required this.onDone,
  });

  @override
  State<AccountMonthlyBalanceScreen> createState() =>
      _AccountMonthlyBalanceScreenState();
}

class _AccountMonthlyBalanceScreenState
    extends State<AccountMonthlyBalanceScreen> {
  static const _lastStep = 2;

  static const _monthNames = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  final _formKey = GlobalKey<FormState>();
  final _openingBalanceController = TextEditingController();
  final _movementsController = PendingMovementsController();

  /// The account being processed, frozen on entry: its stored balance changes
  /// as movements are saved (and the router hands over a fresh copy each
  /// time), but the difference must keep being computed against the balance it
  /// had when the wizard started.
  late final Account _account = widget.account;

  /// Whether the account still lacks this month's opening balance. Decided
  /// once, when first known, and then kept: saving changes the answer, but the
  /// screen must not flip while it finishes. `null` until it is known.
  bool? _isPending;
  bool _checkFailed = false;

  int _currentStep = 0;
  bool _isSaving = false;

  /// Progress of a partially failed save, so a retry doesn't repeat work.
  double _savedMovementsTotal = 0;
  bool _adjustmentApplied = false;

  String get _monthLabel => _monthNames[nowLocal().month - 1];

  /// The movements belong to the previous cycle, so they can only be dated in
  /// the previous month.
  DateTimeRange get _previousMonth {
    final now = nowLocal();
    return DateTimeRange(
      start: DateTime(now.year, now.month - 1),
      end: DateTime(now.year, now.month, 0),
    );
  }

  String get _previousMonthLabel => _monthNames[_previousMonth.start.month - 1];

  @override
  void initState() {
    super.initState();
    _openingBalanceController.addListener(_onInputChanged);
    _movementsController.addListener(_onInputChanged);

    final monthlyBalanceViewModel = widget.monthlyBalanceViewModel;
    if (monthlyBalanceViewModel.checked) {
      _isPending = _lacksOpeningBalance;
      if (_isPending == true) _scheduleIntroDialog();
    } else {
      // Opened by URL before the month was checked.
      monthlyBalanceViewModel.addListener(_onMonthlyBalanceChanged);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || monthlyBalanceViewModel.isLoading) return;
        monthlyBalanceViewModel.checkCurrentMonth();
      });
    }
  }

  @override
  void dispose() {
    widget.monthlyBalanceViewModel.removeListener(_onMonthlyBalanceChanged);
    _openingBalanceController.removeListener(_onInputChanged);
    _openingBalanceController.dispose();
    _movementsController.removeListener(_onInputChanged);
    _movementsController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  bool get _lacksOpeningBalance =>
      widget.monthlyBalanceViewModel.pendingAccounts([_account]).isNotEmpty;

  void _onMonthlyBalanceChanged() {
    final monthlyBalanceViewModel = widget.monthlyBalanceViewModel;
    if (!mounted || _isPending != null) return;

    if (monthlyBalanceViewModel.checked) {
      monthlyBalanceViewModel.removeListener(_onMonthlyBalanceChanged);
      final pending = _lacksOpeningBalance;
      setState(() => _isPending = pending);
      if (pending) _scheduleIntroDialog();
    } else if (!monthlyBalanceViewModel.isLoading) {
      setState(() => _checkFailed = true);
    }
  }

  void _scheduleIntroDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _showIntroDialog());
  }

  void _showIntroDialog() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.authBackgroundBottom,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.authCardBorder),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.authAccent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.authAccent.withValues(alpha: 0.30),
                ),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: AppColors.authAccent,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Saldo inicial del mes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.authTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Esta pantalla sirve para cerrar $_previousMonthLabel: ingresá el '
              'saldo con el que arrancó la cuenta en $_monthLabel y justificá '
              'con movimientos de $_previousMonthLabel la diferencia con el '
              'saldo guardado. Los movimientos de $_monthLabel no se cargan '
              'acá: se controlan desde que termines.',
              style: const TextStyle(
                color: AppColors.authTextSecondary,
                fontSize: 13.5,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Entendido',
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              padding: const EdgeInsets.symmetric(vertical: 14),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        ],
      ),
    );
  }

  /// Opening balance typed by the user minus the account's stored balance
  /// (stale from the previous cycle). `null` while the field is empty or not
  /// a valid number. Rounded to cents to avoid double subtraction remainders.
  double? get _difference {
    final openingBalance = parseBalanceAmount(_openingBalanceController.text);
    if (openingBalance == null) return null;

    final cents = ((openingBalance - _account.balance) * 100).round();
    return cents / 100;
  }

  double get _movementsTotal =>
      _savedMovementsTotal + _movementsController.total;

  /// Part of the difference that the movements don't cover: what is added to
  /// the previous month's `uncontrolled_expenses_total`. Positive: an income
  /// is missing; negative: an expense is missing.
  double? get _unjustifiedRemainder {
    final difference = _difference;
    if (difference == null) return null;

    final cents = ((difference - _movementsTotal) * 100).round();
    return cents / 100;
  }

  void _goToNextStep() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _currentStep += 1);
  }

  /// Saves in this order, so each stage builds on the previous one:
  /// 1. the movements, as real transactions (they move the balance);
  /// 2. the uncontrolled remainder, added to the balance and to the previous
  ///    month's `uncontrolled_expenses_total` (creating that month's record
  ///    first if the account has none);
  /// 3. the new month's record, with the typed opening balance.
  ///
  /// Stages already done are remembered, so a retry after a failure resumes
  /// where it stopped instead of repeating them.
  Future<void> _saveAndStartMonth() async {
    final account = _account;
    final openingBalance = parseBalanceAmount(_openingBalanceController.text);
    final remainder = _unjustifiedRemainder;
    if (openingBalance == null || remainder == null || _isSaving) return;

    final confirmed = await showConfirmDialog(context);
    if (!confirmed || !mounted) return;

    setState(() => _isSaving = true);

    final userId = widget.userId;
    final previous = _previousMonth.start;

    try {
      for (final movement in _movementsController.movements) {
        await savePendingMovement(
          movement: movement,
          userId: userId,
          accountId: account.id,
          transactionViewModel: widget.transactionViewModel,
          invoiceViewModel: widget.invoiceViewModel,
        );
        _savedMovementsTotal += movement.amount;
        _movementsController.remove(movement);
      }

      if (!_adjustmentApplied) {
        if (remainder.abs() >= kRemainderEpsilon) {
          final ensured =
              await widget.monthlyBalanceViewModel.ensureOpeningBalance(
            userId: userId,
            accountId: account.id,
            month: previous.month,
            year: previous.year,
            openingBalance: account.balance,
          );
          if (!ensured) {
            throw Exception(
              widget.monthlyBalanceViewModel.errorMessage ??
                  'No se pudo preparar el ciclo anterior.',
            );
          }

          final adjusted =
              await widget.accountViewModel.applyUncontrolledAdjustment(
            userId: userId,
            accountId: account.id,
            amount: remainder,
            month: previous.month,
            year: previous.year,
          );
          if (!adjusted) {
            throw Exception(
              widget.accountViewModel.errorMessage ??
                  'No se pudo guardar el ajuste no declarado.',
            );
          }
          await widget.transactionViewModel.refreshUncontrolledTotals();
        } else {
          await widget.accountViewModel.loadAccounts();
        }
        _adjustmentApplied = true;
      }

      await _createOpeningBalanceRecord(
        accountId: account.id,
        openingBalance: openingBalance,
      );
      if (!mounted) return;

      widget.onDone();
    } catch (error) {
      if (!mounted) return;
      _showSaveError(error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Skips the justification: the stored balance is declared up to date, so
  /// it becomes the opening balance of the new month, with no movements or
  /// adjustment. Only allowed once the typed opening balance equals the stored
  /// balance, so the user has to consciously confirm it. The account is read
  /// fresh because an earlier failed save may have already moved its balance.
  Future<void> _saveWithCurrentBalance() async {
    if (_isSaving || _difference != 0) return;

    setState(() => _isSaving = true);

    try {
      final account = _findAccount(_account.id) ?? _account;
      await _createOpeningBalanceRecord(
        accountId: account.id,
        openingBalance: account.balance,
      );
      if (!mounted) return;

      widget.onDone();
    } catch (error) {
      if (!mounted) return;
      _showSaveError(error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _createOpeningBalanceRecord({
    required String accountId,
    required double openingBalance,
  }) async {
    final created = await widget.monthlyBalanceViewModel.saveOpeningBalance(
      userId: widget.userId,
      accountId: accountId,
      openingBalance: openingBalance,
    );
    if (!created) {
      throw Exception(
        widget.monthlyBalanceViewModel.errorMessage ??
            'No se pudo guardar el saldo inicial.',
      );
    }
  }

  void _showSaveError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
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

  Account? _findAccount(String id) {
    for (final account in widget.accountViewModel.activeAccounts) {
      if (account.id == id) return account;
    }
    return null;
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

  Widget _buildStepContent(Account account, String currency) {
    switch (_currentStep) {
      case 0:
        return BalanceComparisonCard(
          previousLabel: 'Saldo anterior (desactualizado del ciclo anterior)',
          newLabel: 'Saldo inicial del mes para este nuevo ciclo',
          newBalanceName: 'saldo inicial',
          previousBalance: account.balance,
          currency: currency,
          difference: _difference,
          amountField: BalanceAmountField(
            controller: _openingBalanceController,
            currencySymbol: currencySymbol(currency),
          ),
        );
      case 1:
        final remainder = _unjustifiedRemainder;
        return PendingMovementsSection(
          controller: _movementsController,
          currentAccount: account,
          accountViewModel: widget.accountViewModel,
          categoryViewModel: widget.categoryViewModel,
          serviceViewModel: widget.serviceViewModel,
          invoiceViewModel: widget.invoiceViewModel,
          currency: currency,
          enabled: !_isSaving,
          dateRange: _previousMonth,
          existingTransactions: widget.transactionViewModel.allTransactions,
          helperText: remainder == null
              ? null
              : Text(
                  remainder == 0
                      ? 'Ya justificaste toda la diferencia.'
                      : 'Todavía falta justificar '
                          '${remainder > 0 ? '+' : ''}'
                          '${formatCurrency(remainder, currency)}.',
                  style: TextStyle(
                    fontSize: 12,
                    color: remainder == 0
                        ? AppColors.authAccent
                        : AppColors.authTextSecondary,
                  ),
                ),
        );
      default:
        final openingBalance =
            parseBalanceAmount(_openingBalanceController.text);
        final difference = _difference;
        final uncovered = _unjustifiedRemainder;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_movementsController.isNotEmpty) ...[
              const Text(
                'Movimientos cargados',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.authTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              PendingMovementsReadOnlyList(
                movements: _movementsController.movements,
                currency: currency,
              ),
              const SizedBox(height: 20),
            ],
            if (openingBalance != null &&
                difference != null &&
                uncovered != null)
              OpeningSummaryCard(
                previousBalance: account.balance,
                openingBalance: openingBalance,
                difference: difference,
                movementsTotal: _movementsTotal,
                remainder: uncovered,
                currency: currency,
                openingMonthLabel: _monthLabel,
                previousMonthLabel: _previousMonthLabel,
              ),
          ],
        );
    }
  }

  Widget _buildAccountHero(Account account) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.authCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.authAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.authAccent.withValues(alpha: 0.30),
              ),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 22,
              color: AppColors.authAccent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.authTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Ajuste y conciliación de ciclo',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.authTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.authCardBorder.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.authCardBorder,
              ),
            ),
            child: Text(
              'Paso ${_currentStep + 1} de ${_lastStep + 1}',
              style: const TextStyle(
                fontSize: 12,
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
      onNext = _saveAndStartMonth;
    } else if (isFirstStep && _difference == null) {
      onNext = null;
    } else {
      onNext = _goToNextStep;
    }

    final nextButton = PrimaryButton(
      label: isLastStep ? 'Guardar y comenzar' : 'Siguiente',
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      disabledAlpha: 0.4,
      padding: const EdgeInsets.symmetric(vertical: 16),
      isLoading: isLastStep && _isSaving,
      onPressed: onNext,
    );

    if (isFirstStep) {
      return Column(
        children: [
          SizedBox(width: double.infinity, child: nextButton),
          const SizedBox(height: 8),
          TextActionButton(
            label: 'Mi saldo está al día, sin movimientos',
            fontWeight: FontWeight.w600,
            onPressed:
                _isSaving || _difference != 0 ? null : _saveWithCurrentBalance,
          ),
        ],
      );
    }

    final backButton = SecondaryButton(
      label: 'Atrás',
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      padding: const EdgeInsets.symmetric(vertical: 16),
      onPressed: _isSaving || _adjustmentApplied
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

  @override
  Widget build(BuildContext context) {
    final currency = widget.accountViewModel.primaryCurrency;
    final year = nowLocal().year;

    return SafeArea(
      top: false,
      child: Form(
        key: _formKey,
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
                        title: 'Saldo inicial',
                        subtitle: _isPending == true
                            ? 'Ingresá el saldo con el que arrancó la cuenta '
                                'en $_monthLabel de $year para empezar a '
                                'controlar el nuevo ciclo.'
                            : null,
                        size: ScreenHeaderSize.compact,
                        onBack: widget.onDone,
                        backEnabled: !_isSaving,
                      ),
                      const SizedBox(height: 20),
                      if (_isPending == null)
                        _checkFailed
                            ? _buildMessage(
                                'No pudimos comprobar el saldo inicial de esta '
                                'cuenta. Intentá de nuevo más tarde.',
                              )
                            : const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: CircularProgressIndicator(
                                    color: AppColors.authAccent,
                                  ),
                                ),
                              )
                      else if (_isPending == false)
                        _buildMessage(
                          'Esta cuenta ya tiene el saldo inicial de este mes.',
                        )
                      else ...[
                        _buildAccountHero(_account),
                        const SizedBox(height: 20),
                        _buildStepContent(_account, currency),
                        const SizedBox(height: 24),
                        _buildStepNav(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
