import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/filter_chip_row.dart';
import '../../data/models/account.dart';
import 'balance_comparison_card.dart';

/// State of the closing balance, which is not typed: it is the opening
/// balance of the following month.
enum ClosingBalanceStatus { loading, noAccount, available, missing, failed }

/// First step of the closed-month justification: the account (chosen among
/// [accounts], or just named when there is one), the typed opening balance of
/// the month and its closing balance, shown read-only.
class ClosedMonthBalancesStep extends StatelessWidget {
  final List<Account> accounts;
  final String? selectedAccountId;

  /// Called with the id of the tapped account; null disables the selection.
  final ValueChanged<String>? onSelectAccount;

  final TextEditingController openingController;

  /// Opening balance of the next month for the selected account; only shown
  /// when [closingStatus] is [ClosingBalanceStatus.available].
  final double? closingBalance;
  final ClosingBalanceStatus closingStatus;

  /// Called by the retry action shown when [closingStatus] is
  /// [ClosingBalanceStatus.failed].
  final VoidCallback? onRetryClosing;

  final String currency;

  /// Month in lowercase, as it reads inside a sentence.
  final String monthLabel;

  /// Month after [monthLabel], in the same form.
  final String nextMonthLabel;

  /// Closing minus opening balance; null until both are known.
  final double? difference;

  const ClosedMonthBalancesStep({
    super.key,
    required this.accounts,
    required this.selectedAccountId,
    required this.onSelectAccount,
    required this.openingController,
    required this.closingBalance,
    required this.closingStatus,
    required this.onRetryClosing,
    required this.currency,
    required this.monthLabel,
    required this.nextMonthLabel,
    required this.difference,
  });

  @override
  Widget build(BuildContext context) {
    final difference = this.difference;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (accounts.length > 1)
          _AccountPicker(
            accounts: accounts,
            selectedAccountId: selectedAccountId,
            onSelectAccount: onSelectAccount,
          )
        else
          Text(
            accounts.first.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.authTextPrimary,
            ),
          ),
        const SizedBox(height: 24),
        _LabeledField(
          label: 'Saldo inicial de $monthLabel',
          child: BalanceAmountField(
            controller: openingController,
            currencySymbol: currencySymbol(currency),
          ),
        ),
        const SizedBox(height: 16),
        _LabeledField(
          label: 'Saldo final de $monthLabel',
          child: _ClosingBalance(
            balance: closingBalance,
            status: closingStatus,
            onRetry: onRetryClosing,
            currency: currency,
            monthLabel: monthLabel,
            nextMonthLabel: nextMonthLabel,
          ),
        ),
        if (difference != null) ...[
          const SizedBox(height: 12),
          Text(
            'Diferencia del mes: ${formatCurrency(difference, currency)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.authTextSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _AccountPicker extends StatelessWidget {
  final List<Account> accounts;
  final String? selectedAccountId;
  final ValueChanged<String>? onSelectAccount;

  const _AccountPicker({
    required this.accounts,
    required this.selectedAccountId,
    required this.onSelectAccount,
  });

  @override
  Widget build(BuildContext context) {
    final onSelect = onSelectAccount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cuenta',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.authTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        IgnorePointer(
          key: const ValueKey('accountPickerLock'),
          ignoring: onSelect == null,
          child: FilterChipRow<String?>(
            options: [
              for (final account in accounts)
                (value: account.id, label: account.name),
            ],
            selectedValue: selectedAccountId,
            onChanged: (id) {
              if (id != null) onSelect?.call(id);
            },
          ),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.authTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

/// Closing balance of the month: the opening balance of the next one, which
/// can't be edited here. Without it the month can't be justified.
class _ClosingBalance extends StatelessWidget {
  final double? balance;
  final ClosingBalanceStatus status;
  final VoidCallback? onRetry;
  final String currency;
  final String monthLabel;
  final String nextMonthLabel;

  const _ClosingBalance({
    required this.balance,
    required this.status,
    required this.onRetry,
    required this.currency,
    required this.monthLabel,
    required this.nextMonthLabel,
  });

  static final _amountFormat = NumberFormat.decimalPatternDigits(
    locale: 'es_ES',
    decimalDigits: 2,
  );

  static const _hintStyle = TextStyle(
    fontSize: 12,
    color: AppColors.authTextSecondary,
  );

  static const _amountStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.authTextPrimary,
  );

  @override
  Widget build(BuildContext context) {
    final amount = balance;
    final effectiveStatus =
        status == ClosingBalanceStatus.available && amount == null
            ? ClosingBalanceStatus.missing
            : status;

    switch (effectiveStatus) {
      case ClosingBalanceStatus.loading:
        return const _ReadOnlyBox(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.authAccent,
            ),
          ),
        );
      case ClosingBalanceStatus.noAccount:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ReadOnlyBox(
              child: Text(
                '—',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.authTextFooter,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Elegí una cuenta para ver el saldo inicial de $nextMonthLabel.',
              style: _hintStyle,
            ),
          ],
        );
      case ClosingBalanceStatus.available:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReadOnlyBox(
              child: Row(
                children: [
                  Text(currencySymbol(currency), style: _amountStyle),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _amountFormat.format(amount),
                      overflow: TextOverflow.ellipsis,
                      style: _amountStyle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text('Es el saldo inicial de $nextMonthLabel.', style: _hintStyle),
          ],
        );
      case ClosingBalanceStatus.missing:
        return _unavailable(
          'Esta cuenta no tiene saldo inicial en $nextMonthLabel. Sin ese '
          'dato no se puede justificar $monthLabel.',
        );
      case ClosingBalanceStatus.failed:
        return _unavailable(
          'No pudimos leer el saldo inicial de $nextMonthLabel.',
          onRetry: onRetry,
        );
    }
  }

  Widget _unavailable(String message, {VoidCallback? onRetry}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ReadOnlyBox(
          child: Text(
            '—',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.authTextFooter,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: const TextStyle(fontSize: 12, color: AppColors.authExpense),
        ),
        if (onRetry != null)
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.authAccent,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Reintentar'),
          ),
      ],
    );
  }
}

/// Field-shaped container for a value the user can't edit; its border is
/// neutral, unlike the accent border of the inputs.
class _ReadOnlyBox extends StatelessWidget {
  final Widget child;

  const _ReadOnlyBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 46),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: child,
    );
  }
}
