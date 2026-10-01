import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/utils/month_range.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../invoices/presentation/view_models/invoice_view_model.dart';
import '../../../services/presentation/view_models/service_view_model.dart';
import '../../../transactions/presentation/view_models/transaction_view_model.dart';
import '../../data/models/account.dart';
import '../view_models/account_view_model.dart';
import '../widgets/balance_comparison_card.dart';
import '../widgets/pending_movement_persistence.dart';
import '../widgets/pending_movements_section.dart';

class AccountUpdateBalanceScreen extends StatefulWidget {
  final Account? account;

  final AccountViewModel accountViewModel;

  final CategoryViewModel categoryViewModel;

  final ServiceViewModel serviceViewModel;

  final InvoiceViewModel invoiceViewModel;

  final TransactionViewModel transactionViewModel;

  final String? userId;

  final VoidCallback onDone;

  const AccountUpdateBalanceScreen({
    super.key,
    required this.account,
    required this.accountViewModel,
    required this.categoryViewModel,
    required this.serviceViewModel,
    required this.invoiceViewModel,
    required this.transactionViewModel,
    required this.userId,
    required this.onDone,
  });

  @override
  State<AccountUpdateBalanceScreen> createState() =>
      _AccountUpdateBalanceScreenState();
}

class _AccountUpdateBalanceScreenState
    extends State<AccountUpdateBalanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newBalanceController = TextEditingController();

  final _movementsController = PendingMovementsController();

  bool _isSaving = false;

  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _newBalanceController.addListener(_onNewBalanceChanged);
    // The screen (not just PendingMovementsSection) needs to rebuild on every
    // change so the "still missing X" helper text and the step-2 summary,
    // both computed here from _movementsController, stay in sync.
    _movementsController.addListener(_onMovementsChanged);
  }

  void _onNewBalanceChanged() {
    if (mounted) setState(() {});
  }

  void _onMovementsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(AccountUpdateBalanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.account?.id != widget.account?.id) {
      _newBalanceController.clear();
      _currentStep = 0;
    }
  }

  @override
  void dispose() {
    _newBalanceController.removeListener(_onNewBalanceChanged);
    _newBalanceController.dispose();
    _movementsController.removeListener(_onMovementsChanged);
    _movementsController.dispose();
    super.dispose();
  }

  double? _parseAmount(String? raw) => parseBalanceAmount(raw);

  /// The difference (new − previous) that will later have to be justified
  /// with movements. `null` while the field is empty or not a valid number.
  /// Rounded to cents so the double subtraction doesn't leave remainders like
  /// 499.99999… or prevent detecting the "no difference" case.
  double? get _difference {
    final currentBalance = widget.account?.balance;
    if (currentBalance == null) return null;

    final newBalance = _parseAmount(_newBalanceController.text);
    if (newBalance == null) return null;

    final cents = ((newBalance - currentBalance) * 100).round();
    return cents / 100;
  }

  double get _pendingMovementsTotal => _movementsController.total;

  /// Part of the difference that the loaded movements don't cover. `null`
  /// while there is no computable difference (see [_difference]). Positive:
  /// an income is missing; negative: an expense is missing; zero (or very
  /// close, due to cent rounding): the movements fully justify it.
  double? get _unjustifiedRemainder {
    final diff = _difference;
    if (diff == null) return null;

    final cents = ((diff - _pendingMovementsTotal) * 100).round();
    return cents / 100;
  }

  /// Handler for the "Save and update balance" button. Inserts each entry of
  /// [_movementsController] as a real transaction, one at a time and in
  /// order, so it is known which ones were persisted if one fails midway
  /// (those are removed from [_movementsController] before the error is
  /// shown, so a retry doesn't duplicate them).
  ///
  /// If part of the difference is still uncovered, no uncategorized
  /// transaction is created to justify it: [AccountViewModel.applyUncontrolledAdjustment]
  /// is called instead. It adjusts `accounts.balance` directly and
  /// accumulates the same (signed) amount into
  /// `monthly_account_balances.uncontrolled_expenses_total` for the current
  /// month, in a single atomic operation.
  Future<void> _saveAndUpdateBalance() async {
    final account = widget.account;
    final remainder = _unjustifiedRemainder;
    if (account == null || remainder == null || _isSaving) return;

    final confirmed = await showConfirmDialog(context);
    if (!confirmed || !mounted) return;

    setState(() => _isSaving = true);

    final userId = widget.userId ?? '';
    final saved = <PendingMovement>[];

    try {
      for (final movement in _movementsController.movements) {
        await savePendingMovement(
          movement: movement,
          userId: userId,
          accountId: account.id,
          transactionViewModel: widget.transactionViewModel,
          invoiceViewModel: widget.invoiceViewModel,
        );
        saved.add(movement);
      }

      if (remainder.abs() >= kRemainderEpsilon) {
        final now = DateTime.now();
        final success =
            await widget.accountViewModel.applyUncontrolledAdjustment(
          userId: userId,
          accountId: account.id,
          amount: remainder,
          month: now.month,
          year: now.year,
        );
        if (!success) {
          throw Exception(
            widget.accountViewModel.errorMessage ??
                'No se pudo guardar el ajuste no declarado.',
          );
        }
        await widget.transactionViewModel.refreshUncontrolledTotals();
      } else {
        await widget.accountViewModel.loadAccounts();
      }
      if (!mounted) return;

      _movementsController.clear();
      setState(() => _newBalanceController.clear());
      widget.onDone();
    } catch (error) {
      if (!mounted) return;
      _movementsController.removeWhere(saved.contains);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildStepContent(
    Account account,
    String currency,
    String currencySymbol,
  ) {
    switch (_currentStep) {
      case 0:
        return BalanceComparisonCard(
          previousBalance: account.balance,
          currency: currency,
          difference: _difference,
          amountField: BalanceAmountField(
            controller: _newBalanceController,
            currencySymbol: currencySymbol,
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
          dateRange: currentMonthRange(),
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
      case 2:
      default:
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
            _MovementsSummaryCard(
              total: _pendingMovementsTotal,
              remainder: _unjustifiedRemainder,
              currency: currency,
            ),
          ],
        );
    }
  }

  Widget _buildStepNav() {
    final isFirstStep = _currentStep == 0;
    final isLastStep = _currentStep == 2;

    final backButton = OutlinedButton(
      onPressed: _isSaving ? null : () => setState(() => _currentStep -= 1),
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
      onPressed: !isLastStep
          ? (_isSaving || (isFirstStep && _difference == null)
              ? null
              : () => setState(() => _currentStep += 1))
          : (_difference == null || _isSaving ? null : _saveAndUpdateBalance),
      child: !isLastStep
          ? const Text('Siguiente',
              style: TextStyle(fontWeight: FontWeight.w700))
          : _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.authBackgroundBottom,
                  ),
                )
              : const Text(
                  'Guardar y actualizar saldo',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
    );

    if (isFirstStep) {
      final diff = _difference;
      return Column(
        children: [
          SizedBox(width: double.infinity, child: nextButton),
          if (diff != null && diff != 0) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isSaving ? null : _saveAndUpdateBalance,
              child: const Text(
                'Guardar sin justificar movimientos',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.authTextSecondary,
                ),
              ),
            ),
          ],
        ],
      );
    }

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
    final account = widget.account;
    final currency = widget.accountViewModel.primaryCurrency;
    final currencySymbol =
        NumberFormat.currency(locale: 'es_ES', name: currency).currencySymbol;

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
                    title: 'Actualizar saldo',
                    subtitle:
                        'Ingresa el nuevo saldo de tu cuenta y agrega los movimientos '
                        'que justifiquen la diferencia.',
                    size: ScreenHeaderSize.compact,
                    onBack: widget.onDone,
                    backEnabled: !_isSaving,
                  ),
                  if (account != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      account.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.authTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildStepContent(account, currency, currencySymbol),
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

class _MovementsSummaryCard extends StatelessWidget {
  final double total;

  final double? remainder;
  final String currency;

  const _MovementsSummaryCard({
    required this.total,
    required this.remainder,
    required this.currency,
  });

  static const _epsilon = kRemainderEpsilon;

  @override
  Widget build(BuildContext context) {
    final rem = remainder;

    final Color tone;
    final IconData icon;
    final String title;
    final String message;

    if (rem == null) {
      tone = AppColors.authTextSecondary;
      icon = Icons.info_outline_rounded;
      title = 'Falta el saldo nuevo';
      message = 'Ingresa el nuevo saldo para calcular la diferencia.';
    } else if (rem.abs() < _epsilon) {
      tone = AppColors.authAccent;
      icon = Icons.check_rounded;
      title = 'Coincide con la diferencia';
      message = 'El saldo se actualiza correctamente.';
    } else if (rem > 0) {
      tone = AppColors.authIncome;
      icon = Icons.priority_high_rounded;
      title = 'Diferencia sin justificar';
      message = 'Se ajustará el balance por '
          '${formatCurrency(rem, currency)} como ingreso no controlado, '
          'sin registrar un movimiento.';
    } else {
      tone = AppColors.authExpense;
      icon = Icons.priority_high_rounded;
      title = 'Diferencia sin justificar';
      message = 'Se ajustará el balance por '
          '${formatCurrency(rem.abs(), currency)} como gasto no '
          'controlado, sin registrar un movimiento.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.authAccent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calculate_rounded,
                    color: AppColors.authAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total de movimientos',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.authTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatCurrency(total, currency),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.authTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 52,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppColors.authCardBorder,
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: tone, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tone,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.3,
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
