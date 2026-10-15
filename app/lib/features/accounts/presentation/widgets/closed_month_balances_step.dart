import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart';
import '../../data/models/account.dart';
import 'balance_comparison_card.dart';

/// First step of the closed-month justification: the account (chosen among
/// [accounts], or just named when there is one) and the opening and closing
/// balance of the month.
class ClosedMonthBalancesStep extends StatelessWidget {
  final List<Account> accounts;
  final String? selectedAccountId;

  /// Called with the id of the tapped account; null disables the selection.
  final ValueChanged<String>? onSelectAccount;

  final TextEditingController openingController;
  final TextEditingController closingController;
  final String currency;

  /// Month in lowercase, as it reads inside a sentence.
  final String monthLabel;

  /// Closing minus opening balance; null until both are typed.
  final double? difference;

  const ClosedMonthBalancesStep({
    super.key,
    required this.accounts,
    required this.selectedAccountId,
    required this.onSelectAccount,
    required this.openingController,
    required this.closingController,
    required this.currency,
    required this.monthLabel,
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
        _LabeledAmount(
          label: 'Saldo inicial de $monthLabel',
          controller: openingController,
          currency: currency,
        ),
        const SizedBox(height: 16),
        _LabeledAmount(
          label: 'Saldo final de $monthLabel',
          controller: closingController,
          currency: currency,
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final account in accounts)
              ChoiceChip(
                label: Text(account.name),
                selected: account.id == selectedAccountId,
                showCheckmark: false,
                backgroundColor: AppColors.authCardFill,
                selectedColor: AppColors.authAccent.withValues(alpha: 0.25),
                side: const BorderSide(color: AppColors.authCardBorder),
                labelStyle: const TextStyle(
                  color: AppColors.authTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: onSelect == null
                    ? null
                    : (_) => onSelect(account.id),
              ),
          ],
        ),
      ],
    );
  }
}

class _LabeledAmount extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String currency;

  const _LabeledAmount({
    required this.label,
    required this.controller,
    required this.currency,
  });

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
        BalanceAmountField(
          controller: controller,
          currencySymbol: currencySymbol(currency),
        ),
      ],
    );
  }
}
