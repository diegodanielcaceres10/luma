import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/app_clock.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/utils/month_range.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../invoices/presentation/view_models/invoice_view_model.dart';
import '../../../services/presentation/view_models/service_view_model.dart';
import '../../../transactions/presentation/view_models/transaction_view_model.dart';
import '../../data/models/account.dart';
import '../view_models/account_view_model.dart';
import '../widgets/justify_cards.dart';
import '../widgets/pending_movement_persistence.dart';
import '../widgets/pending_movements_section.dart';

/// Lets the user justify part (or all) of an account's uncontrolled
/// (undeclared) balance for the current month by loading the real
/// movements that explain it (income, expense, transfers and invoice
/// payments, all saved as justifying transactions). Unlike
/// [AccountUpdateBalanceScreen], there is no "enter a new balance" first
/// step: the amount to justify is the account's current
/// `uncontrolled_expenses_total`, read on open, not typed in.
class AccountJustifyUncontrolledScreen extends StatefulWidget {
  final Account? account;

  final AccountViewModel accountViewModel;

  final CategoryViewModel categoryViewModel;

  final ServiceViewModel serviceViewModel;

  final InvoiceViewModel invoiceViewModel;

  final TransactionViewModel transactionViewModel;

  final String? userId;

  final VoidCallback onDone;

  const AccountJustifyUncontrolledScreen({
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
  State<AccountJustifyUncontrolledScreen> createState() =>
      _AccountJustifyUncontrolledScreenState();
}

class _AccountJustifyUncontrolledScreenState
    extends State<AccountJustifyUncontrolledScreen> {
  final _movementsController = PendingMovementsController();

  bool _isSaving = false;
  bool _isLoadingTarget = true;

  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _movementsController.addListener(_onMovementsChanged);
    _loadTarget();
  }

  Future<void> _loadTarget() async {
    final account = widget.account;
    if (account != null) {
      await widget.accountViewModel.loadUncontrolledTotal(account.id);
    }
    if (mounted) setState(() => _isLoadingTarget = false);
  }

  void _onMovementsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(AccountJustifyUncontrolledScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.account?.id != widget.account?.id) {
      _currentStep = 0;
      _movementsController.clear();
      _isLoadingTarget = true;
      _loadTarget();
    }
  }

  @override
  void dispose() {
    _movementsController.removeListener(_onMovementsChanged);
    _movementsController.dispose();
    super.dispose();
  }

  /// The account's `uncontrolled_expenses_total` for the current month, as
  /// read when this screen opened. This is the amount the movements loaded
  /// here are meant to justify away; it is not re-read on every build, so
  /// adding a movement doesn't move its own target.
  double? get _target {
    final account = widget.account;
    if (account == null || _isLoadingTarget) return null;
    return widget.accountViewModel.uncontrolledTotalOf(account.id);
  }

  double get _pendingMovementsTotal => _movementsController.total;

  /// Part of [_target] the loaded movements don't cover yet. `null` while
  /// [_target] hasn't loaded. Zero (or very close, due to cent rounding)
  /// once fully justified.
  double? get _unjustifiedRemainder {
    final target = _target;
    if (target == null) return null;

    final cents = ((target - _pendingMovementsTotal) * 100).round();
    return cents / 100;
  }

  /// Handler for the "Guardar" button. Inserts each queued movement as a
  /// real transaction via [TransactionViewModel.createJustifyingTransaction]
  /// — which does not move `accounts.balance` and instead discounts the
  /// movement from `uncontrolled_expenses_total` — one at a time and in
  /// order, so it is known which ones were persisted if one fails midway
  /// (those are removed from [_movementsController] before the error is
  /// shown, so a retry doesn't duplicate them).
  ///
  /// Whatever part of [_target] is left unjustified simply stays in
  /// `uncontrolled_expenses_total`; partial justification is valid, so
  /// nothing else needs to happen for it.
  Future<void> _save() async {
    final account = widget.account;
    if (account == null || _movementsController.isEmpty || _isSaving) return;

    final confirmed = await showConfirmDialog(context);
    if (!confirmed || !mounted) return;

    setState(() => _isSaving = true);

    final userId = widget.userId ?? '';
    final now = nowLocal();
    final saved = <PendingMovement>[];

    try {
      for (final movement in _movementsController.movements) {
        await saveJustifyingMovement(
          movement: movement,
          userId: userId,
          accountId: account.id,
          month: now.month,
          year: now.year,
          transactionViewModel: widget.transactionViewModel,
          invoiceViewModel: widget.invoiceViewModel,
        );
        saved.add(movement);
      }

      await widget.accountViewModel.loadUncontrolledTotal(account.id);
      if (!mounted) return;

      _movementsController.clear();
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

  Widget _buildStepContent(Account account, String currency) {
    switch (_currentStep) {
      case 0:
        final remainder = _unjustifiedRemainder;
        return PendingMovementsSection(
          controller: _movementsController,
          currentAccount: account,
          accountViewModel: widget.accountViewModel,
          categoryViewModel: widget.categoryViewModel,
          serviceViewModel: widget.serviceViewModel,
          invoiceViewModel: widget.invoiceViewModel,
          currency: currency,
          title: 'Movimientos para justificar lo sin declarar',
          enabled: !_isSaving,
          // Transferencia y Factura de servicio quedan para una próxima
          // entrega: justificarlas sin mover el saldo de esta cuenta
          // requiere lógica propia (ver notas de la conversación).
          dateRange: currentMonthRange(),
          existingTransactions: widget.transactionViewModel.allTransactions,
          helperText: remainder == null
              ? null
              : Text(
                  remainder.abs() < kRemainderEpsilon
                      ? 'Ya justificaste todo lo sin declarar de este mes.'
                      : 'Todavía queda ${formatCurrency(remainder.abs(), currency)} '
                          'de ${remainder < 0 ? 'gasto' : 'ingreso'} sin declarar.',
                  style: TextStyle(
                    fontSize: 12,
                    color: remainder.abs() < kRemainderEpsilon
                        ? AppColors.authAccent
                        : AppColors.authTextSecondary,
                  ),
                ),
        );
      case 1:
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
            JustifySummaryCard(
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
    final isLastStep = _currentStep == 1;
    final canAdvance = _movementsController.isNotEmpty;

    final backButton = SecondaryButton(
      label: 'Atrás',
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      padding: const EdgeInsets.symmetric(vertical: 16),
      borderRadius: 30,
      onPressed: _isSaving ? null : () => setState(() => _currentStep -= 1),
    );

    final nextButton = PrimaryButton(
      label: !isLastStep ? 'Siguiente' : 'Guardar',
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      disabledAlpha: 0.4,
      padding: const EdgeInsets.symmetric(vertical: 16),
      borderRadius: 30,
      isLoading: isLastStep && _isSaving,
      onPressed: !isLastStep
          ? (_isSaving || !canAdvance
              ? null
              : () => setState(() => _currentStep += 1))
          : (_isSaving || !canAdvance ? null : _save),
    );

    if (isFirstStep) {
      return SizedBox(width: double.infinity, child: nextButton);
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
    final target = _target;

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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                ScreenHeader(
                  title: 'Justificar sin declarar',
                  subtitle: 'Agregá los movimientos que expliquen el saldo '
                      'sin declarar de este mes en esta cuenta.',
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
                  if (_isLoadingTarget)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(
                          color: AppColors.authAccent,
                        ),
                      ),
                    )
                  else if (target == null || target.abs() < kRemainderEpsilon)
                    NothingToJustifyCard(onBack: widget.onDone)
                  else ...[
                    _buildStepContent(account, currency),
                    const SizedBox(height: 24),
                    _buildStepNav(),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
