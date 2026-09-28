import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../invoices/data/models/invoice.dart';
import '../../../invoices/presentation/view_models/invoice_view_model.dart';
import '../../../services/presentation/view_models/service_view_model.dart';
import '../../../transactions/presentation/view_models/transaction_view_model.dart';
import '../../data/models/account.dart';
import '../view_models/account_view_model.dart';

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
  State<AccountUpdateBalanceScreen> createState() => _AccountUpdateBalanceScreenState();
}

class _AccountUpdateBalanceScreenState extends State<AccountUpdateBalanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newBalanceController = TextEditingController();

  final List<PendingMovement> _pendingMovements = [];

  bool _isSaving = false;

  int _currentStep = 0;

  void _addPendingMovement(PendingMovement movement) {
    setState(() => _pendingMovements.add(movement));
  }

  void _removePendingMovement(PendingMovement movement) {
    setState(() => _pendingMovements.remove(movement));
  }

  @override
  void initState() {
    super.initState();
    _newBalanceController.addListener(_onNewBalanceChanged);
  }

  void _onNewBalanceChanged() {
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
    super.dispose();
  }

  double? _parseAmount(String? raw) {
    final text = (raw ?? '').trim().replaceAll(',', '.');
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

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

  double get _pendingMovementsTotal {
    final cents = _pendingMovements.fold<int>(
      0,
      (sum, movement) => sum + (movement.amount * 100).round(),
    );
    return cents / 100;
  }

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
  /// [_pendingMovements] as a real transaction, one at a time and in order,
  /// so it is known which ones were persisted if one fails midway (those are
  /// removed from [_pendingMovements] before the error is shown, so a retry
  /// doesn't duplicate them).
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

    setState(() => _isSaving = true);

    final userId = widget.userId ?? '';
    final saved = <PendingMovement>[];

    try {
      for (final movement in _pendingMovements) {
        final bool success = switch (movement) {
          CategoryPendingMovement(:final category) =>
            await widget.transactionViewModel.createTransaction(
              userId: userId,
              accountId: account.id,
              categoryId: category.id,
              type: category.type,
              amount: movement.amount.abs(),
              description: movement.description,
              date: movement.date,
            ),
          TransferPendingMovement(:final otherAccountId) =>
            await widget.transactionViewModel.createTransfer(
              userId: userId,
              originAccountId:
                  movement.amount < 0 ? account.id : otherAccountId,
              destinationAccountId:
                  movement.amount < 0 ? otherAccountId : account.id,
              amount: movement.amount.abs(),
              date: movement.date,
              originDescription: movement.description,
              destinationDescription: movement.description,
            ),
          InvoicePendingMovement(:final invoice, :final category) =>
            await widget.invoiceViewModel.payInvoice(
              invoice: invoice,
              userId: userId,
              accountId: account.id,
              categoryId: category.id,
              amount: movement.amount.abs(),
              description: movement.description,
              date: movement.date,
            ),
        };
        if (!success) {
          final errorMessage = movement is InvoicePendingMovement
              ? widget.invoiceViewModel.errorMessage
              : widget.transactionViewModel.errorMessage;
          throw Exception(errorMessage ?? 'No se pudo guardar un movimiento.');
        }
        saved.add(movement);
      }

      if (remainder.abs() >= _kRemainderEpsilon) {
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
      } else {
        await widget.accountViewModel.loadAccounts();
      }
      if (!mounted) return;

      setState(() {
        _pendingMovements.clear();
        _newBalanceController.clear();
      });
      widget.onDone();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pendingMovements.removeWhere(saved.contains);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Opens the bottom sheet behind the "Add movement" button to pick between
  /// Income, Expense, Transfer and Service invoice ([_MovementType]). Income
  /// and Expense open [_AddMovementDialog] with categories filtered by that
  /// type. Transfer opens [_AddTransferDialog] to choose the other account
  /// and the direction. Service invoice first opens
  /// [_SelectPendingInvoiceSheet] to pick one and, if its category resolves,
  /// [_AddInvoiceDialog] to confirm amount and date.
  Future<void> _showAddMovementDialog(BuildContext context) async {
    final account = widget.account;
    if (account == null) return;

    final type = await showModalBottomSheet<_MovementType>(
      context: context,
      backgroundColor: AppColors.authBackgroundBottom,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _MovementTypeSheet(),
    );
    if (type == null || !context.mounted) return;

    switch (type) {
      case _MovementType.income:
      case _MovementType.expense:
        final categoryType =
            type == _MovementType.income ? 'income' : 'expense';
        return showDialog<void>(
          context: context,
          builder: (dialogContext) => _AddMovementDialog(
            categoryViewModel: widget.categoryViewModel,
            categoryType: categoryType,
            onSave: _addPendingMovement,
          ),
        );
      case _MovementType.transfer:
        return showDialog<void>(
          context: context,
          builder: (dialogContext) => _AddTransferDialog(
            currentAccount: account,
            accountViewModel: widget.accountViewModel,
            onSave: _addPendingMovement,
          ),
        );
      case _MovementType.invoice:
        return _showAddInvoiceFlow(context);
    }
  }

  /// Second half of the "Service invoice" case of [_showAddMovementDialog]:
  /// pick which invoice to pay (excluding those already queued in
  /// [_pendingMovements], so one can't be paid twice before saving) and, if
  /// the service has a resolved category, confirm amount and date.
  Future<void> _showAddInvoiceFlow(BuildContext context) async {
    final alreadyQueuedIds = _pendingMovements
        .whereType<InvoicePendingMovement>()
        .map((m) => m.invoice.id)
        .toSet();
    final pendingInvoices = widget.invoiceViewModel.invoices
        .where((i) => i.isPending && !alreadyQueuedIds.contains(i.id))
        .toList();

    final invoice = await showModalBottomSheet<Invoice>(
      context: context,
      backgroundColor: AppColors.authBackgroundBottom,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _SelectPendingInvoiceSheet(
        invoices: pendingInvoices,
        serviceViewModel: widget.serviceViewModel,
        currency: widget.accountViewModel.primaryCurrency,
      ),
    );
    if (invoice == null || !context.mounted) return;

    final service = widget.serviceViewModel.serviceById(invoice.serviceId);
    final serviceName = service?.name ?? 'Servicio eliminado';
    final category = widget.categoryViewModel.categoryById(service?.categoryId);
    if (category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El servicio no tiene categoría o fue eliminado; no se puede '
            'registrar el pago.',
          ),
        ),
      );
      return;
    }

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => _AddInvoiceDialog(
        invoice: invoice,
        serviceName: serviceName,
        category: category,
        onSave: _addPendingMovement,
      ),
    );
  }

  InputDecoration _amountDecoration(String currencySymbol) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color),
        );

    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: AppColors.authCardFill,
      hintText: '0,00',
      hintStyle: const TextStyle(color: AppColors.authTextFooter),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 14, right: 6),
        child: Text(
          currencySymbol,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.authTextPrimary,
          ),
        ),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: _newBalanceController.text.isEmpty
          ? null
          : IconButton(
              onPressed: _newBalanceController.clear,
              icon: const Icon(
                Icons.cancel_rounded,
                size: 18,
                color: AppColors.authTextSecondary,
              ),
              tooltip: 'Borrar',
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
      suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      border: border(AppColors.authAccent.withValues(alpha: 0.6)),
      enabledBorder: border(AppColors.authAccent.withValues(alpha: 0.6)),
      focusedBorder: border(AppColors.authAccent),
    );
  }

  Widget _buildStepContent(
    Account account,
    String currency,
    String currencySymbol,
  ) {
    switch (_currentStep) {
      case 0:
        return _BalanceCard(
          previousBalance: account.balance,
          currency: currency,
          difference: _difference,
          amountField: TextFormField(
            controller: _newBalanceController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'^-?\d*[.,]?\d{0,2}'),
              ),
            ],
            cursorColor: AppColors.authAccent,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.authTextPrimary,
            ),
            decoration: _amountDecoration(currencySymbol),
            validator: (value) =>
                _parseAmount(value) == null ? 'Ingresa un monto válido' : null,
          ),
        );
      case 1:
        final remainder = _unjustifiedRemainder;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MovementsSectionHeader(
              onAddMovement: () => _showAddMovementDialog(context),
              enabled: !_isSaving,
            ),
            if (remainder != null) ...[
              const SizedBox(height: 4),
              Text(
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
            ],
            if (_pendingMovements.isNotEmpty) ...[
              const SizedBox(height: 12),
              _MovementsList(
                movements: _pendingMovements,
                currency: currency,
                onDelete: _removePendingMovement,
                enabled: !_isSaving,
              ),
            ],
          ],
        );
      case 2:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_pendingMovements.isNotEmpty) ...[
              const Text(
                'Movimientos cargados',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.authTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _MovementsReadOnlyList(
                movements: _pendingMovements,
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
          ? (_isSaving ? null : () => setState(() => _currentStep += 1))
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

enum _MovementType { income, expense, transfer, invoice }

class _MovementTypeSheet extends StatelessWidget {
  const _MovementTypeSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.authCardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Agregar movimiento',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.authTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _MovementTypeOption(
              icon: Icons.arrow_downward_rounded,
              iconColor: AppColors.authIncome,
              label: 'Ingreso',
              onTap: () => Navigator.of(context).pop(_MovementType.income),
            ),
            _MovementTypeOption(
              icon: Icons.arrow_upward_rounded,
              iconColor: AppColors.authExpense,
              label: 'Gasto',
              onTap: () => Navigator.of(context).pop(_MovementType.expense),
            ),
            _MovementTypeOption(
              icon: Icons.swap_horiz_rounded,
              iconColor: AppColors.authAccent,
              label: 'Transferencia',
              onTap: () => Navigator.of(context).pop(_MovementType.transfer),
            ),
            _MovementTypeOption(
              icon: Icons.request_page_outlined,
              iconColor: AppColors.authAccent,
              label: 'Factura de servicio',
              onTap: () => Navigator.of(context).pop(_MovementType.invoice),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovementTypeOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _MovementTypeOption({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: iconColor.withValues(alpha: 0.18),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.authTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovementsSectionHeader extends StatelessWidget {
  final VoidCallback onAddMovement;

  final bool enabled;

  const _MovementsSectionHeader({
    required this.onAddMovement,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Text(
            'Movimientos para justificar la diferencia',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.authTextPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: enabled ? onAddMovement : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.authAccent,
            side: const BorderSide(color: AppColors.authAccent),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            visualDensity: VisualDensity.compact,
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text(
            'Agregar movimiento',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

const _kMonthAbbreviations = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

String _formatMovementDate(DateTime date) {
  final month = _kMonthAbbreviations[date.month - 1];
  return '${date.day} $month ${date.year}';
}

const _kRemainderEpsilon = 0.005;

class _MovementsList extends StatelessWidget {
  final List<PendingMovement> movements;
  final String currency;
  final void Function(PendingMovement movement) onDelete;

  final bool enabled;

  const _MovementsList({
    required this.movements,
    required this.currency,
    required this.onDelete,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < movements.length; i++) ...[
            _MovementListTile(
              movement: movements[i],
              currency: currency,
              onDelete: enabled ? () => onDelete(movements[i]) : null,
            ),
            if (i < movements.length - 1)
              const Divider(color: AppColors.authCardBorder, height: 1),
          ],
        ],
      ),
    );
  }
}

class _MovementListTile extends StatelessWidget {
  final PendingMovement movement;
  final String currency;

  final VoidCallback? onDelete;

  const _MovementListTile({
    required this.movement,
    required this.currency,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final amount = movement.amount;
    final amountText = amount > 0
        ? '+${formatCurrency(amount, currency)}'
        : formatCurrency(amount, currency);
    final amountColor =
        amount > 0 ? AppColors.authIncome : AppColors.authExpense;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.displayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.authTextPrimary,
                  ),
                ),
                if (movement.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    movement.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.authTextSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  _formatMovementDate(movement.date),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.authTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amountText,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: AppColors.authTextSecondary,
            ),
            tooltip: 'Quitar',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _MovementsReadOnlyList extends StatelessWidget {
  final List<PendingMovement> movements;
  final String currency;

  const _MovementsReadOnlyList({
    required this.movements,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < movements.length; i++) ...[
            _MovementReadOnlyTile(movement: movements[i], currency: currency),
            if (i < movements.length - 1)
              const Divider(color: AppColors.authCardBorder, height: 1),
          ],
        ],
      ),
    );
  }
}

class _MovementReadOnlyTile extends StatelessWidget {
  final PendingMovement movement;
  final String currency;

  const _MovementReadOnlyTile({
    required this.movement,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final amount = movement.amount;
    final amountText = amount > 0
        ? '+${formatCurrency(amount, currency)}'
        : formatCurrency(amount, currency);
    final amountColor =
        amount > 0 ? AppColors.authIncome : AppColors.authExpense;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              movement.displayLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.authTextPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amountText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
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

  static const _epsilon = _kRemainderEpsilon;

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

sealed class PendingMovement {
  final double amount;
  final String? description;
  final DateTime date;

  const PendingMovement({
    required this.amount,
    required this.date,
    this.description,
  });

  String get displayLabel;
}

class CategoryPendingMovement extends PendingMovement {
  final Category category;

  const CategoryPendingMovement({
    required super.amount,
    required super.date,
    required this.category,
    super.description,
  });

  @override
  String get displayLabel => category.name;
}

class TransferPendingMovement extends PendingMovement {
  final String otherAccountId;
  final String otherAccountName;

  const TransferPendingMovement({
    required super.amount,
    required super.date,
    required this.otherAccountId,
    required this.otherAccountName,
    super.description,
  });

  @override
  String get displayLabel => amount >= 0
      ? 'Transferencia desde $otherAccountName'
      : 'Transferencia a $otherAccountName';
}

class InvoicePendingMovement extends PendingMovement {
  final Invoice invoice;
  final Category category;
  final String serviceName;

  const InvoicePendingMovement({
    required super.amount,
    required super.date,
    required this.invoice,
    required this.category,
    required this.serviceName,
    super.description,
  });

  @override
  String get displayLabel => 'Factura · $serviceName';
}

const _kDialogLabelStyle = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w600,
  color: AppColors.authTextSecondary,
);

const _kDialogFieldDecoration = InputDecoration(
  isDense: true,
  filled: true,
  fillColor: AppColors.authCardFill,
  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  hintStyle: TextStyle(color: AppColors.authTextFooter),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(14)),
    borderSide: BorderSide(color: AppColors.authCardBorder),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(14)),
    borderSide: BorderSide(color: AppColors.authCardBorder),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(14)),
    borderSide: BorderSide(color: AppColors.authAccent),
  ),
);

class _AddMovementDialog extends StatefulWidget {
  final CategoryViewModel categoryViewModel;

  final String categoryType;

  final void Function(PendingMovement movement) onSave;

  const _AddMovementDialog({
    required this.categoryViewModel,
    required this.categoryType,
    required this.onSave,
  });

  @override
  State<_AddMovementDialog> createState() => _AddMovementDialogState();
}

class _AddMovementDialogState extends State<_AddMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.authAccent,
            onPrimary: AppColors.authBackgroundBottom,
            surface: AppColors.authBackgroundBottom,
            onSurface: AppColors.authTextPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) return;

    final rawAmount = double.parse(_amountController.text.replaceAll(',', '.'));
    final signedAmount =
        _selectedCategory!.type == 'expense' ? -rawAmount : rawAmount;

    widget.onSave(
      CategoryPendingMovement(
        amount: signedAmount,
        category: _selectedCategory!,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        date: _selectedDate,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.categoryViewModel.categories
        .where((c) => c.type == widget.categoryType)
        .toList();
    final categoryTypeLabel =
        widget.categoryType == 'income' ? 'ingreso' : 'gasto';

    return AlertDialog(
      backgroundColor: AppColors.authBackgroundTop,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.authCardBorder),
      ),
      title: const Text(
        'Agregar movimiento',
        style: TextStyle(
          color: AppColors.authTextPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Monto', style: _kDialogLabelStyle),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*[.,]?\d{0,2}'),
                  ),
                ],
                style: const TextStyle(color: AppColors.authTextPrimary),
                decoration: _kDialogFieldDecoration.copyWith(hintText: '0,00'),
                validator: (value) {
                  final text = (value ?? '').trim().replaceAll(',', '.');
                  if (text.isEmpty) return 'Ingresa un monto';
                  final parsed = double.tryParse(text);
                  if (parsed == null || parsed <= 0) {
                    return 'Monto inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Categoría', style: _kDialogLabelStyle),
              const SizedBox(height: 6),
              if (widget.categoryViewModel.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.authAccent,
                    ),
                  ),
                )
              else if (categories.isEmpty)
                Text(
                  'No hay categorías de $categoryTypeLabel todavía.',
                  style: const TextStyle(
                    color: AppColors.authExpense,
                    fontSize: 13,
                  ),
                )
              else
                DropdownButtonFormField<Category>(
                  initialValue: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: AppColors.authBackgroundBottom,
                  style: const TextStyle(color: AppColors.authTextPrimary),
                  decoration: _kDialogFieldDecoration,
                  hint: const Text(
                    'Seleccioná una categoría',
                    style: TextStyle(color: AppColors.authTextSecondary),
                  ),
                  items: categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value),
                  validator: (value) =>
                      value == null ? 'Seleccioná una categoría' : null,
                ),
              const SizedBox(height: 16),
              const Text('Descripción (opcional)', style: _kDialogLabelStyle),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: AppColors.authTextPrimary),
                decoration: _kDialogFieldDecoration.copyWith(
                  hintText: 'Ej: Retiro en efectivo',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Fecha', style: _kDialogLabelStyle),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: _kDialogFieldDecoration,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedDate.day.toString().padLeft(2, '0')}/'
                        '${_selectedDate.month.toString().padLeft(2, '0')}/'
                        '${_selectedDate.year}',
                        style:
                            const TextStyle(color: AppColors.authTextPrimary),
                      ),
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: AppColors.authTextSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.authTextSecondary),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.authAccent,
            foregroundColor: AppColors.authBackgroundBottom,
          ),
          onPressed: categories.isEmpty ? null : _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _AddTransferDialog extends StatefulWidget {
  final Account currentAccount;

  final AccountViewModel accountViewModel;

  final void Function(PendingMovement movement) onSave;

  const _AddTransferDialog({
    required this.currentAccount,
    required this.accountViewModel,
    required this.onSave,
  });

  @override
  State<_AddTransferDialog> createState() => _AddTransferDialogState();
}

class _AddTransferDialogState extends State<_AddTransferDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _otherAccountId;

  bool _isIncoming = true;

  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.authAccent,
            onPrimary: AppColors.authBackgroundBottom,
            surface: AppColors.authBackgroundBottom,
            onSurface: AppColors.authTextPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final otherAccountId = _otherAccountId;
    if (otherAccountId == null) return;

    final otherAccount = widget.accountViewModel.activeAccounts
        .firstWhere((a) => a.id == otherAccountId);

    final rawAmount = double.parse(_amountController.text.replaceAll(',', '.'));
    final signedAmount = _isIncoming ? rawAmount : -rawAmount;

    widget.onSave(
      TransferPendingMovement(
        amount: signedAmount,
        otherAccountId: otherAccount.id,
        otherAccountName: otherAccount.name,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        date: _selectedDate,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final otherAccounts = widget.accountViewModel.activeAccounts
        .where((a) => a.id != widget.currentAccount.id)
        .toList();

    return AlertDialog(
      backgroundColor: AppColors.authBackgroundTop,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.authCardBorder),
      ),
      title: const Text(
        'Agregar transferencia',
        style: TextStyle(
          color: AppColors.authTextPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (otherAccounts.isEmpty)
                const Text(
                  'Necesitás al menos otra cuenta activa para cargar una '
                  'transferencia.',
                  style: TextStyle(color: AppColors.authExpense, fontSize: 13),
                )
              else ...[
                const Text('Dirección', style: _kDialogLabelStyle),
                const SizedBox(height: 6),
                SegmentedButton<bool>(
                  style: SegmentedButton.styleFrom(
                    backgroundColor: AppColors.authCardFill,
                    foregroundColor: AppColors.authTextSecondary,
                    selectedBackgroundColor: AppColors.authAccent,
                    selectedForegroundColor: AppColors.authBackgroundBottom,
                    side: const BorderSide(color: AppColors.authCardBorder),
                  ),
                  segments: const [
                    ButtonSegment(value: true, label: Text('Entra')),
                    ButtonSegment(value: false, label: Text('Sale')),
                  ],
                  selected: {_isIncoming},
                  onSelectionChanged: (selection) =>
                      setState(() => _isIncoming = selection.first),
                ),
                const SizedBox(height: 16),
                Text(
                  _isIncoming
                      ? 'Otra cuenta (de dónde sale)'
                      : 'Otra cuenta (a dónde va)',
                  style: _kDialogLabelStyle,
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _otherAccountId,
                  isExpanded: true,
                  dropdownColor: AppColors.authBackgroundBottom,
                  style: const TextStyle(color: AppColors.authTextPrimary),
                  decoration: _kDialogFieldDecoration,
                  hint: const Text(
                    'Seleccioná una cuenta',
                    style: TextStyle(color: AppColors.authTextSecondary),
                  ),
                  items: otherAccounts
                      .map(
                        (a) => DropdownMenuItem(
                          value: a.id,
                          child: Text(a.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _otherAccountId = value),
                  validator: (value) =>
                      value == null ? 'Seleccioná una cuenta' : null,
                ),
                const SizedBox(height: 16),
                const Text('Monto', style: _kDialogLabelStyle),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*[.,]?\d{0,2}'),
                    ),
                  ],
                  style: const TextStyle(color: AppColors.authTextPrimary),
                  decoration:
                      _kDialogFieldDecoration.copyWith(hintText: '0,00'),
                  validator: (value) {
                    final text = (value ?? '').trim().replaceAll(',', '.');
                    if (text.isEmpty) return 'Ingresa un monto';
                    final parsed = double.tryParse(text);
                    if (parsed == null || parsed <= 0) {
                      return 'Monto inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Descripción (opcional)',
                  style: _kDialogLabelStyle,
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(color: AppColors.authTextPrimary),
                  decoration: _kDialogFieldDecoration.copyWith(
                    hintText: 'Ej: Traspaso entre cuentas propias',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Fecha', style: _kDialogLabelStyle),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: _kDialogFieldDecoration,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_selectedDate.day.toString().padLeft(2, '0')}/'
                          '${_selectedDate.month.toString().padLeft(2, '0')}/'
                          '${_selectedDate.year}',
                          style:
                              const TextStyle(color: AppColors.authTextPrimary),
                        ),
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: AppColors.authTextSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.authTextSecondary),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.authAccent,
            foregroundColor: AppColors.authBackgroundBottom,
          ),
          onPressed: otherAccounts.isEmpty ? null : _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _SelectPendingInvoiceSheet extends StatelessWidget {
  final List<Invoice> invoices;
  final ServiceViewModel serviceViewModel;
  final String currency;

  const _SelectPendingInvoiceSheet({
    required this.invoices,
    required this.serviceViewModel,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.authCardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Facturas pendientes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.authTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            if (invoices.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No hay facturas pendientes para pagar.',
                  style: TextStyle(color: AppColors.authTextSecondary),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: invoices.length,
                  separatorBuilder: (_, __) => const Divider(
                    color: AppColors.authCardBorder,
                    height: 1,
                  ),
                  itemBuilder: (context, i) {
                    final invoice = invoices[i];
                    final service =
                        serviceViewModel.serviceById(invoice.serviceId);
                    final serviceName = service?.name ?? 'Servicio eliminado';
                    final dueDate = invoice.dueDate;
                    final monthYear =
                        '${_kMonthAbbreviations[invoice.month - 1]} '
                        '${invoice.year}';
                    return InkWell(
                      onTap: () => Navigator.of(context).pop(invoice),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    serviceName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.authTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    dueDate == null
                                        ? monthYear
                                        : '$monthYear · vence '
                                            '${_formatMovementDate(dueDate)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.authTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              formatCurrency(invoice.amount, currency),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.authTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddInvoiceDialog extends StatefulWidget {
  final Invoice invoice;
  final String serviceName;
  final Category category;
  final void Function(PendingMovement movement) onSave;

  const _AddInvoiceDialog({
    required this.invoice,
    required this.serviceName,
    required this.category,
    required this.onSave,
  });

  @override
  State<_AddInvoiceDialog> createState() => _AddInvoiceDialogState();
}

class _AddInvoiceDialogState extends State<_AddInvoiceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.invoice.amount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.authAccent,
            onPrimary: AppColors.authBackgroundBottom,
            surface: AppColors.authBackgroundBottom,
            onSurface: AppColors.authTextPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(
      _amountController.text.trim().replaceAll(',', '.'),
    );

    widget.onSave(
      InvoicePendingMovement(
        amount: -amount,
        date: _selectedDate,
        invoice: widget.invoice,
        category: widget.category,
        serviceName: widget.serviceName,
        description: 'Factura · ${widget.serviceName}',
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.authBackgroundTop,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.authCardBorder),
      ),
      title: const Text(
        'Pagar factura',
        style: TextStyle(
          color: AppColors.authTextPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.serviceName} · ${widget.category.name}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.authTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Monto a pagar', style: _kDialogLabelStyle),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*[.,]?\d{0,2}'),
                  ),
                ],
                style: const TextStyle(color: AppColors.authTextPrimary),
                decoration: _kDialogFieldDecoration.copyWith(hintText: '0,00'),
                validator: (value) {
                  final text = (value ?? '').trim().replaceAll(',', '.');
                  if (text.isEmpty) return 'Ingresa un monto';
                  final parsed = double.tryParse(text);
                  if (parsed == null || parsed <= 0) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Fecha de pago', style: _kDialogLabelStyle),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: _kDialogFieldDecoration,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedDate.day.toString().padLeft(2, '0')}/'
                        '${_selectedDate.month.toString().padLeft(2, '0')}/'
                        '${_selectedDate.year}',
                        style: const TextStyle(
                          color: AppColors.authTextPrimary,
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: AppColors.authTextSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.authTextSecondary),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.authAccent,
            foregroundColor: AppColors.authBackgroundBottom,
          ),
          onPressed: _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double previousBalance;
  final String currency;
  final double? difference;
  final Widget amountField;

  const _BalanceCard({
    required this.previousBalance,
    required this.currency,
    required this.difference,
    required this.amountField,
  });

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
          const Text(
            'Saldo anterior (en la app)',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.authTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatCurrency(previousBalance, currency),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.authTextPrimary,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Icon(
              Icons.arrow_downward_rounded,
              size: 22,
              color: AppColors.authTextSecondary,
            ),
          ),
          const Text(
            'Nuevo saldo actual',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.authTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          amountField,
          const SizedBox(height: 16),
          _DifferenceBox(difference: difference, currency: currency),
        ],
      ),
    );
  }
}

class _DifferenceBox extends StatelessWidget {
  final double? difference;
  final String currency;

  const _DifferenceBox({required this.difference, required this.currency});

  @override
  Widget build(BuildContext context) {
    final diff = difference;

    final Color tone;
    final IconData icon;
    final String valueText;
    final String message;

    if (diff == null) {
      tone = AppColors.authTextSecondary;
      icon = Icons.remove_rounded;
      valueText = '—';
      message = 'Ingresa el nuevo saldo para calcular la diferencia.';
    } else if (diff == 0) {
      tone = AppColors.authAccent;
      icon = Icons.check_rounded;
      valueText = formatCurrency(0, currency);
      message = 'El nuevo saldo coincide con el anterior. '
          'No hay diferencia que justificar.';
    } else if (diff > 0) {
      tone = AppColors.authIncome;
      icon = Icons.arrow_upward_rounded;
      valueText = '+${formatCurrency(diff, currency)}';
      message = 'El nuevo saldo es mayor al anterior. En la siguiente '
          'pantalla podés cargar los movimientos que la justifiquen.';
    } else {
      tone = AppColors.authExpense;
      icon = Icons.arrow_downward_rounded;
      valueText = formatCurrency(diff, currency);
      message = 'El nuevo saldo es menor al anterior. En la siguiente '
          'pantalla podés cargar los movimientos que la justifiquen.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: tone, size: 22),
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Diferencia',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.authTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    valueText,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: diff == null || diff == 0
                          ? AppColors.authTextPrimary
                          : tone,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.authTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
