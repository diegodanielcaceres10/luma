import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/monthly_bar_chart.dart';
import '../../../../core/widgets/trend_card.dart';
import '../../data/models/monthly_opening_balance.dart';
import '../../domain/account_trend.dart';

/// How the balance of an account moved in each of the last 3 months, with
/// the opening balance of each month under its bar. Reads the opening
/// history already loaded in AccountViewModel; the parent rebuilds it when
/// that or the balance changes.
class AccountTrendSection extends StatelessWidget {
  final List<MonthlyOpeningBalance> history;
  final double currentBalance;
  final String currency;

  const AccountTrendSection({
    super.key,
    required this.history,
    required this.currentBalance,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return TrendCard(
      title: 'Últimos 3 meses',
      child: _content(),
    );
  }

  Widget _content() {
    final trend = buildAccountTrend(
      history: history,
      currentBalance: currentBalance,
      today: DateTime.now(),
    );

    if (trend.isEmpty) {
      return const Text(
        'Todavía no hay saldos iniciales para calcular la variación.',
        style: TextStyle(fontSize: 14, color: AppColors.authTextSecondary),
      );
    }

    final total = trend.totalChange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MonthlyBarChart(
          bars: [
            for (final month in trend.months)
              MonthlyBar(
                month: month.month,
                value: month.change,
                color: _colorOf(month.change),
                caption: month.opening == null
                    ? null
                    : formatCurrency(month.opening!, currency),
              ),
          ],
          currency: currency,
          color: AppColors.authIncome,
        ),
        const SizedBox(height: 8),
        const Text(
          'Bajo cada mes: saldo inicial.',
          style: TextStyle(fontSize: 11, color: AppColors.authTextSecondary),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: AppColors.authCardBorder),
        TrendSummaryRow(
          label: 'Variación acumulada',
          value: total == null
              ? const Text('—', style: trendValueStyle)
              : _SignedAmount(amount: total, currency: currency),
        ),
      ],
    );
  }

  Color? _colorOf(double? change) {
    if (change == null) return null;
    return change < 0 ? AppColors.authExpense : AppColors.authIncome;
  }
}

class _SignedAmount extends StatelessWidget {
  final double amount;
  final String currency;

  const _SignedAmount({required this.amount, required this.currency});

  @override
  Widget build(BuildContext context) {
    final (color, sign) = amount > 0
        ? (AppColors.authIncome, '+')
        : amount < 0
            ? (AppColors.authExpense, '-')
            : (AppColors.authTextPrimary, '');

    return Text(
      '$sign${formatCurrency(amount.abs(), currency)}',
      style: trendValueStyle.copyWith(color: color),
    );
  }
}
