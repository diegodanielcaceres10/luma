import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/currency_format.dart';
import '../view_models/transaction_view_model.dart';

class StatisticsTab extends StatefulWidget {
  final TransactionViewModel transactionViewModel;
  final String currency;

  const StatisticsTab({
    super.key,
    required this.transactionViewModel,
    required this.currency,
  });

  @override
  State<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab> {
  // Mes que se muestra en el selector del header. Por ahora solo cambia el
  // label: todavía no dispara una recarga de datos de ese mes puntual (el
  // resto del cuerpo sigue mostrando el mes en curso, que es lo único que
  // carga TransactionViewModel.loadCurrentMonth()). Se conecta con datos
  // reales en una próxima entrega.
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  Future<void> _pickMonth() async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: AppColors.authBackgroundBottom,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _MonthPickerSheet(selectedMonth: _selectedMonth),
    );

    if (picked != null && mounted) {
      setState(() => _selectedMonth = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.transactionViewModel,
      builder: (context, _) {
        final vm = widget.transactionViewModel;

        final header = _StatisticsHeader(
          selectedMonth: _selectedMonth,
          onTapMonthSelector: _pickMonth,
        );

        if (vm.isLoading && vm.categoryBreakdown.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              header,
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.authAccent),
                ),
              ),
            ],
          );
        }

        final breakdown = vm.categoryBreakdown;

        if (breakdown.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              header,
              const SizedBox(height: 20),
              _SummaryCardsRow(
                income: vm.totalIncome,
                expenses: vm.totalExpenses,
                netResult: vm.netResult,
                incomeChangePercent: vm.incomeChangePercent,
                expenseChangePercent: vm.expenseChangePercent,
                netChangePercent: vm.netResultChangePercent,
                currency: widget.currency,
              ),
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(
                    'Todavía no hay gastos este mes.',
                    style: TextStyle(color: AppColors.authTextSecondary),
                  ),
                ),
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            header,
            const SizedBox(height: 20),
            _SummaryCardsRow(
              income: vm.totalIncome,
              expenses: vm.totalExpenses,
              netResult: vm.netResult,
              incomeChangePercent: vm.incomeChangePercent,
              expenseChangePercent: vm.expenseChangePercent,
              netChangePercent: vm.netResultChangePercent,
              currency: widget.currency,
            ),
            const SizedBox(height: 24),
            const Text(
              'Gastos por categoría',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.authTextSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatCurrency(vm.totalExpenses, widget.currency),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.authTextPrimary,
              ),
            ),
            const Text(
              'gastados este mes',
              style: TextStyle(fontSize: 12, color: AppColors.authTextFooter),
            ),
            const SizedBox(height: 20),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.authCardFill,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.authCardBorder),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: breakdown
                      .map((c) => _CategoryBar(
                            category: c,
                            currency: widget.currency,
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Título de la pantalla, subtítulo y selector de mes.
class _StatisticsHeader extends StatelessWidget {
  final DateTime selectedMonth;
  final VoidCallback onTapMonthSelector;

  const _StatisticsHeader({
    required this.selectedMonth,
    required this.onTapMonthSelector,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Text(
                'Estadísticas',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.authTextPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _MonthSelectorPill(
              selectedMonth: selectedMonth,
              onTap: onTapMonthSelector,
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Analiza tus ingresos, gastos y mantén el control de tus finanzas.',
          style: AppTextStyles.authSubtitle,
        ),
      ],
    );
  }
}

/// Botón tipo pill que muestra el mes elegido y abre el selector.
class _MonthSelectorPill extends StatelessWidget {
  final DateTime selectedMonth;
  final VoidCallback onTap;

  const _MonthSelectorPill({
    required this.selectedMonth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.authCardFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.authCardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 15,
              color: AppColors.authTextPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              _monthLabel(selectedMonth),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.authTextPrimary,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.authTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila con las 3 cards de resumen del mes: Ingresos, Gastos y Balance.
class _SummaryCardsRow extends StatelessWidget {
  final double income;
  final double expenses;
  final double netResult;
  final double? incomeChangePercent;
  final double? expenseChangePercent;
  final double? netChangePercent;
  final String currency;

  const _SummaryCardsRow({
    required this.income,
    required this.expenses,
    required this.netResult,
    required this.incomeChangePercent,
    required this.expenseChangePercent,
    required this.netChangePercent,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.arrow_downward_rounded,
            iconBackground: AppColors.authIncome,
            label: 'Ingresos',
            amount: income,
            changePercent: incomeChangePercent,
            // Más ingresos es una mejora.
            isFavorable:
                incomeChangePercent == null ? null : incomeChangePercent! >= 0,
            currency: currency,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.arrow_upward_rounded,
            iconBackground: AppColors.authExpense,
            label: 'Gastos',
            amount: expenses,
            changePercent: expenseChangePercent,
            // Acá es al revés: gastar menos que el mes pasado es la mejora.
            isFavorable: expenseChangePercent == null
                ? null
                : expenseChangePercent! <= 0,
            currency: currency,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.account_balance_wallet_outlined,
            iconBackground: AppColors.authAccentDark,
            label: 'Balance del mes',
            amount: netResult,
            changePercent: netChangePercent,
            isFavorable:
                netChangePercent == null ? null : netChangePercent! >= 0,
            currency: currency,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final String label;
  final double amount;
  final double? changePercent;
  final bool? isFavorable;
  final String currency;

  const _SummaryCard({
    required this.icon,
    required this.iconBackground,
    required this.label,
    required this.amount,
    required this.changePercent,
    required this.isFavorable,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: iconBackground,
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.authTextSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formatCurrency(amount, currency),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.authTextPrimary,
              ),
            ),
            if (changePercent != null && isFavorable != null) ...[
              const SizedBox(height: 6),
              _ChangeIndicator(
                changePercent: changePercent!,
                isFavorable: isFavorable!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// '+18% vs. mes anterior' con flecha y color según si el cambio es una
/// mejora o no (para Gastos, bajar es la mejora, así que la lectura de
/// isFavorable no siempre coincide con el signo del propio porcentaje).
class _ChangeIndicator extends StatelessWidget {
  final double changePercent;
  final bool isFavorable;

  const _ChangeIndicator({
    required this.changePercent,
    required this.isFavorable,
  });

  @override
  Widget build(BuildContext context) {
    final color = isFavorable ? AppColors.authAccent : AppColors.authExpense;
    final icon = changePercent >= 0
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;
    final sign = changePercent > 0 ? '+' : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            '$sign${changePercent.toStringAsFixed(0)}% vs. mes anterior',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Hoja inferior para elegir uno de los últimos 12 meses.
class _MonthPickerSheet extends StatelessWidget {
  final DateTime selectedMonth;

  const _MonthPickerSheet({required this.selectedMonth});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final months = List.generate(
      12,
      (i) => DateTime(currentMonth.year, currentMonth.month - i),
    );

    return SafeArea(
      top: false,
      // Acota el alto total de la hoja (handle + título + lista) a una
      // fracción de la pantalla. Antes solo se limitaba la lista a un %
      // fijo por su cuenta, sin contar el resto del contenido, así que en
      // pantallas bajas el conjunto terminaba pidiendo más alto del que
      // el modal tenía disponible (RenderFlex overflow).
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.authCardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Elegí un mes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.authTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              // Flexible (no un % fijo propio): toma lo que quede del alto
              // ya acotado arriba, así nunca desborda a la lista le
              // sobra o falta espacio según el resto del contenido.
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: months.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: AppColors.authCardBorder,
                  ),
                  itemBuilder: (context, index) {
                    final month = months[index];
                    final isSelected = month.year == selectedMonth.year &&
                        month.month == selectedMonth.month;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _monthLabel(month),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.authAccent
                              : AppColors.authTextPrimary,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              color: AppColors.authAccent,
                              size: 20,
                            )
                          : null,
                      onTap: () => Navigator.of(context).pop(month),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 'septiembre 2025' -> 'Septiembre 2025'.
String _monthLabel(DateTime date) {
  final formatted = DateFormat('MMMM yyyy', 'es').format(date);
  return formatted[0].toUpperCase() + formatted.substring(1);
}

class _CategoryBar extends StatelessWidget {
  final CategoryTotal category;
  final String currency;

  const _CategoryBar({required this.category, required this.currency});

  @override
  Widget build(BuildContext context) {
    const color = AppColors.authAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category.category.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.authTextPrimary,
                  ),
                ),
              ),
              Text(
                formatCurrency(category.amount, currency),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.authTextPrimary,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                child: Text(
                  '${category.percent.toStringAsFixed(0)}%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.authTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (category.percent / 100).clamp(0, 1),
              minHeight: 6,
              backgroundColor: AppColors.authBackgroundTop,
              valueColor: const AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
