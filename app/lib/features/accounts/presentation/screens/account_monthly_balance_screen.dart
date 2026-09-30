import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../data/models/account.dart';
import '../view_models/account_view_model.dart';
import '../view_models/monthly_balance_view_model.dart';
import '../widgets/balance_comparison_card.dart';

/// Wizard to enter the opening balance of the current month for each account
/// that lacks one. Reached from the Dashboard balance card notice.
///
/// Only step 1 (opening balance) is built so far; the value is kept in memory
/// and nothing is persisted yet.
class AccountMonthlyBalanceScreen extends StatefulWidget {
  final String userId;
  final List<Account> pendingAccounts;
  final AccountViewModel accountViewModel;
  final MonthlyBalanceViewModel monthlyBalanceViewModel;
  final VoidCallback onDone;

  const AccountMonthlyBalanceScreen({
    super.key,
    required this.userId,
    required this.pendingAccounts,
    required this.accountViewModel,
    required this.monthlyBalanceViewModel,
    required this.onDone,
  });

  @override
  State<AccountMonthlyBalanceScreen> createState() =>
      _AccountMonthlyBalanceScreenState();
}

class _AccountMonthlyBalanceScreenState
    extends State<AccountMonthlyBalanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _openingBalanceController = TextEditingController();

  int _currentStep = 0;

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

  String get _monthLabel => _monthNames[DateTime.now().month - 1];

  @override
  void initState() {
    super.initState();
    _openingBalanceController.addListener(_onOpeningBalanceChanged);
    if (widget.pendingAccounts.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showIntroDialog());
    }
  }

  @override
  void dispose() {
    _openingBalanceController.removeListener(_onOpeningBalanceChanged);
    _openingBalanceController.dispose();
    super.dispose();
  }

  void _onOpeningBalanceChanged() {
    if (mounted) setState(() {});
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
          'Para empezar a controlar $_monthLabel ingresá el saldo con el '
          'que arrancó la cuenta a principio de mes. Si ya tenés '
          'movimientos cargados este mes, los justificás en los '
          'siguientes pasos.',
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
  double? _difference(Account account) {
    final openingBalance = parseBalanceAmount(_openingBalanceController.text);
    if (openingBalance == null) return null;

    final cents = ((openingBalance - account.balance) * 100).round();
    return cents / 100;
  }

  void _goToNextStep() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _currentStep += 1);
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
          difference: _difference(account),
          amountField: BalanceAmountField(
            controller: _openingBalanceController,
            currencySymbol: currencySymbol(currency),
          ),
        );
      default:
        return const _StepPlaceholder(
          title: 'Justificar movimientos',
          message: 'Próximamente: en este paso vas a poder justificar la '
              'diferencia con movimientos.',
        );
    }
  }

  Widget _buildStepNav(Account account) {
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
      onPressed: _currentStep == 0 && _difference(account) != null
          ? _goToNextStep
          : null,
      child: const Text(
        'Siguiente',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );

    if (_currentStep == 0) {
      return SizedBox(width: double.infinity, child: nextButton);
    }

    final backButton = OutlinedButton(
      onPressed: () => setState(() => _currentStep -= 1),
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
    final pending = widget.pendingAccounts;
    final currency = widget.accountViewModel.primaryCurrency;
    final year = DateTime.now().year;

    return SafeArea(
      top: false,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            ScreenHeader(
              title: 'Saldos iniciales',
              subtitle: 'Ingresá el saldo con el que arrancó la cuenta en '
                  '$_monthLabel de $year para empezar a controlar el nuevo '
                  'ciclo.',
              size: ScreenHeaderSize.compact,
              onBack: widget.onDone,
            ),
            const SizedBox(height: 20),
            if (pending.isEmpty)
              const Text(
                'No hay saldos iniciales pendientes este mes.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.authTextSecondary,
                ),
              )
            else ...[
              if (pending.length > 1) ...[
                Text(
                  'Cuenta 1 de ${pending.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.authTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                pending.first.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.authTextPrimary,
                ),
              ),
              const SizedBox(height: 24),
              _buildStepContent(pending.first, currency),
              const SizedBox(height: 24),
              _buildStepNav(pending.first),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepPlaceholder extends StatelessWidget {
  final String title;
  final String message;

  const _StepPlaceholder({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.authTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.authTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
