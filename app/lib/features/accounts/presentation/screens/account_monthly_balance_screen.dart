import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../invoices/presentation/view_models/invoice_view_model.dart';
import '../../../services/presentation/view_models/service_view_model.dart';
import '../../../transactions/presentation/view_models/transaction_view_model.dart';
import '../../data/models/account.dart';
import '../view_models/account_view_model.dart';
import '../view_models/monthly_balance_view_model.dart';
import '../widgets/balance_comparison_card.dart';
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

  String get _monthLabel => _monthNames[DateTime.now().month - 1];

  /// The movements belong to the previous cycle, so they can only be dated in
  /// the previous month.
  DateTimeRange get _previousMonth {
    final now = DateTime.now();
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
        backgroundColor: AppColors.authBackgroundTop,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.authCardBorder),
        ),
        icon: const Icon(
          Icons.calendar_month_rounded,
          color: AppColors.authAccent,
        ),
        title: const Text(
          'Saldo inicial del mes',
          style: TextStyle(
            color: AppColors.authTextPrimary,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Esta pantalla sirve para cerrar $_previousMonthLabel: ingresá el '
          'saldo con el que arrancó la cuenta en $_monthLabel y justificá '
          'con movimientos de $_previousMonthLabel la diferencia con el '
          'saldo guardado. Los movimientos de $_monthLabel no se cargan '
          'acá: se controlan desde que termines.',
          style: const TextStyle(color: AppColors.authTextSecondary),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.authAccent,
              foregroundColor: AppColors.authBackgroundBottom,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Entendido',
              style: TextStyle(fontWeight: FontWeight.w700),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString().replaceFirst('Exception: ', '')),
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
    return Text(
      message,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.authTextSecondary,
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
              _OpeningSummaryCard(
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

    final nextButton = FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.authAccent,
        foregroundColor: AppColors.authBackgroundBottom,
        disabledBackgroundColor: AppColors.authAccent.withValues(alpha: 0.4),
        disabledForegroundColor:
            AppColors.authBackgroundBottom.withValues(alpha: 0.6),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      onPressed: onNext,
      child: isLastStep && _isSaving
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.authBackgroundBottom,
              ),
            )
          : Text(
              isLastStep ? 'Guardar y comenzar' : 'Siguiente',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
    );

    if (isFirstStep) {
      return Column(
        children: [
          SizedBox(width: double.infinity, child: nextButton),
          const SizedBox(height: 8),
          TextButton(
            onPressed:
                _isSaving || _difference != 0 ? null : _saveWithCurrentBalance,
            child: const Text(
              'Mi saldo está al día, sin movimientos',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.authTextSecondary,
              ),
            ),
          ),
        ],
      );
    }

    final backButton = OutlinedButton(
      onPressed: _isSaving || _adjustmentApplied
          ? null
          : () => setState(() => _currentStep -= 1),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.authTextPrimary,
        side: const BorderSide(color: AppColors.authCardBorder),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: const Text('Atrás', style: TextStyle(fontWeight: FontWeight.w700)),
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
    final year = DateTime.now().year;

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
                    Text(
                      _account.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.authTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildStepContent(_account, currency),
                    const SizedBox(height: 24),
                    _buildStepNav(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpeningSummaryCard extends StatelessWidget {
  final double previousBalance;
  final double openingBalance;
  final double difference;
  final double movementsTotal;
  final double remainder;
  final String currency;
  final String openingMonthLabel;
  final String previousMonthLabel;

  const _OpeningSummaryCard({
    required this.previousBalance,
    required this.openingBalance,
    required this.difference,
    required this.movementsTotal,
    required this.remainder,
    required this.currency,
    required this.openingMonthLabel,
    required this.previousMonthLabel,
  });

  @override
  Widget build(BuildContext context) {
    final Color tone;
    final IconData icon;
    final String title;
    final String message;

    if (remainder.abs() < kRemainderEpsilon) {
      tone = AppColors.authAccent;
      icon = Icons.check_rounded;
      title = 'Coincide con la diferencia';
      message = 'No hace falta ningún ajuste. Se registra el saldo inicial '
          'de $openingMonthLabel.';
    } else if (remainder > 0) {
      tone = AppColors.authIncome;
      icon = Icons.priority_high_rounded;
      title = 'Diferencia sin justificar';
      message = 'Se sumarán ${formatCurrency(remainder, currency)} como '
          'ingreso no controlado de $previousMonthLabel, sin registrar un '
          'movimiento.';
    } else {
      tone = AppColors.authExpense;
      icon = Icons.priority_high_rounded;
      title = 'Diferencia sin justificar';
      message = 'Se sumarán ${formatCurrency(remainder.abs(), currency)} como '
          'gasto no controlado de $previousMonthLabel, sin registrar un '
          'movimiento.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(
            label: 'Saldo anterior',
            value: formatCurrency(previousBalance, currency),
          ),
          _SummaryRow(
            label: 'Saldo inicial de $openingMonthLabel',
            value: formatCurrency(openingBalance, currency),
          ),
          _SummaryRow(
            label: 'Diferencia',
            value: formatCurrency(difference, currency),
          ),
          _SummaryRow(
            label: 'Total de movimientos',
            value: formatCurrency(movementsTotal, currency),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tone.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: tone, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: tone,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: AppColors.authTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.authTextSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.authTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
