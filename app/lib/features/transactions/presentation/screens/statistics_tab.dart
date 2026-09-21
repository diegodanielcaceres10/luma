import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../export/statistics_pdf_builder.dart';
import '../view_models/transaction_view_model.dart';

class StatisticsTab extends StatefulWidget {
  final TransactionViewModel transactionViewModel;

  /// Para leer [CategoryViewModel.budgetedCategories] — las categorías de
  /// gasto con presupuesto asignado que arma la card de "Presupuesto"
  /// (ver [_BudgetSummaryCard]).
  final CategoryViewModel categoryViewModel;
  final String currency;

  const StatisticsTab({
    super.key,
    required this.transactionViewModel,
    required this.categoryViewModel,
    required this.currency,
  });

  @override
  State<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab> {
  bool _isExportingPdf = false;

  /// Genera el PDF del mes que se está viendo y lo descarga (web) o abre el
  /// menú de compartir (móvil). Solo se ofrece para meses ya cerrados: ver
  /// `canExportPdf` en [build].
  Future<void> _exportPdf() async {
    if (_isExportingPdf) return;

    // Se toma una foto de los datos antes del primer await: si el usuario
    // cambia de mes mientras se genera, el PDF sigue siendo del mes en que
    // tocó el botón.
    final vm = widget.transactionViewModel;
    final data = StatisticsPdfData(
      month: vm.statisticsMonth,
      monthLabel: _monthLabel(vm.statisticsMonth),
      currency: widget.currency,
      income: vm.statisticsIncome,
      expenses: vm.statisticsExpenses,
      netResult: vm.statisticsNetResult,
      incomeChangePercent: vm.statisticsIncomeChangePercent,
      expenseChangePercent: vm.statisticsExpenseChangePercent,
      netChangePercent: vm.statisticsNetResultChangePercent,
      breakdown: List.of(vm.statisticsCategoryBreakdown),
      uncategorizedCount: vm.statisticsUncategorizedCount,
      uncategorizedTotal: vm.statisticsUncategorizedTotal,
    );

    setState(() => _isExportingPdf = true);
    try {
      final bytes = await StatisticsPdfBuilder.build(data);
      await Printing.sharePdf(bytes: bytes, filename: data.fileName);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo generar el PDF.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  /// Una fila por cada categoría con presupuesto asignado, con lo gastado
  /// este mes en esa categoría puntual (0 si todavía no tiene ningún
  /// movimiento). Reemplaza al total agrupado: cada categoría tiene su
  /// propia barra, no una sola sumando todas.
  List<_BudgetProgress> get _budgetProgress {
    final spentByCategoryId = <String, double>{
      for (final total
          in widget.transactionViewModel.statisticsCategoryBreakdown)
        if (total.category.id != null) total.category.id!: total.amount,
    };

    return widget.categoryViewModel.budgetedCategories
        .map((category) => _BudgetProgress(
              category: category,
              budgeted: category.budgetAmount ?? 0,
              spent: spentByCategoryId[category.id] ?? 0,
            ))
        .toList();
  }

  Future<void> _pickMonth() async {
    final vm = widget.transactionViewModel;

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: AppColors.authBackgroundBottom,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) =>
          _MonthPickerSheet(selectedMonth: vm.statisticsMonth),
    );

    // El mes elegido vive en el TransactionViewModel (no en este State):
    // desde ahí se cargan los datos de ese mes y el ListenableBuilder de
    // abajo repinta todo el cuerpo cuando llegan.
    if (picked != null && mounted) {
      vm.loadStatisticsMonth(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(
        [widget.transactionViewModel, widget.categoryViewModel],
      ),
      builder: (context, _) {
        final vm = widget.transactionViewModel;
        final month = vm.statisticsMonth;
        final isCurrentMonth = vm.isStatisticsCurrentMonth;
        // 'Septiembre 2025' -> 'septiembre 2025', para usarlo dentro de una
        // frase ("gastados en septiembre 2025").
        final monthInSentence = _monthLabel(month).toLowerCase();

        // El PDF es un resumen del mes cerrado: no se ofrece en el mes en
        // curso (todavía no terminó) ni mientras carga, si falló la carga o
        // si el mes no tiene movimientos.
        final canExportPdf = !isCurrentMonth &&
            !vm.isStatisticsLoading &&
            vm.statisticsErrorMessage == null &&
            (vm.statisticsIncome > 0 || vm.statisticsExpenses > 0);

        final header = _StatisticsHeader(
          selectedMonth: month,
          onTapMonthSelector: _pickMonth,
          onExportPdf: canExportPdf ? _exportPdf : null,
          isExportingPdf: _isExportingPdf,
        );

        // El presupuesto es un objetivo del mes en curso — no tiene
        // sentido medir "cuánto llevás gastado de tu presupuesto" sobre un
        // mes ya cerrado, así que la card solo aparece con isCurrentMonth.
        final budgetProgress =
            isCurrentMonth ? _budgetProgress : const <_BudgetProgress>[];
        final budgetCard = budgetProgress.isEmpty
            ? null
            : _BudgetCategoriesCard(
                items: budgetProgress,
                currency: widget.currency,
              );

        // Card aparte para los movimientos (ingresos o gastos, sin contar
        // transferencias) que quedaron sin categoría asignada. No se
        // muestra si no hay ninguno.
        final uncategorizedCard = vm.statisticsUncategorizedCount == 0
            ? null
            : _UncategorizedCard(
                total: vm.statisticsUncategorizedTotal,
                count: vm.statisticsUncategorizedCount,
                currency: widget.currency,
              );

        final breakdown = vm.statisticsCategoryBreakdown;

        if (vm.isStatisticsLoading && breakdown.isEmpty) {
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

        final errorMessage = vm.statisticsErrorMessage;
        if (errorMessage != null && breakdown.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              header,
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.authTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.authAccent,
                      ),
                      onPressed: () => vm.loadStatisticsMonth(month),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        if (breakdown.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              header,
              const SizedBox(height: 20),
              _SummaryCardsRow(
                income: vm.statisticsIncome,
                expenses: vm.statisticsExpenses,
                netResult: vm.statisticsNetResult,
                incomeChangePercent: vm.statisticsIncomeChangePercent,
                expenseChangePercent: vm.statisticsExpenseChangePercent,
                netChangePercent: vm.statisticsNetResultChangePercent,
                currency: widget.currency,
              ),
              if (budgetCard != null) ...[
                const SizedBox(height: 10),
                budgetCard,
              ],
              if (uncategorizedCard != null) ...[
                const SizedBox(height: 10),
                uncategorizedCard,
              ],
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(
                    isCurrentMonth
                        ? 'Todavía no hay gastos este mes.'
                        : 'No hay gastos registrados en $monthInSentence.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.authTextSecondary),
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
              income: vm.statisticsIncome,
              expenses: vm.statisticsExpenses,
              netResult: vm.statisticsNetResult,
              incomeChangePercent: vm.statisticsIncomeChangePercent,
              expenseChangePercent: vm.statisticsExpenseChangePercent,
              netChangePercent: vm.statisticsNetResultChangePercent,
              currency: widget.currency,
            ),
            if (budgetCard != null) ...[
              const SizedBox(height: 10),
              budgetCard,
            ],
            if (uncategorizedCard != null) ...[
              const SizedBox(height: 10),
              uncategorizedCard,
            ],
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
              formatCurrency(vm.statisticsExpenses, widget.currency),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.authTextPrimary,
              ),
            ),
            Text(
              isCurrentMonth
                  ? 'gastados este mes'
                  : 'gastados en $monthInSentence',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.authTextFooter,
              ),
            ),
            const SizedBox(height: 20),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.authCardFill,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.authCardBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _CategoryDonutChart(
                      breakdown: breakdown,
                      total: vm.statisticsExpenses,
                      currency: widget.currency,
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        children: breakdown
                            .map((c) => _CategoryLegendRow(
                                  category: c,
                                  currency: widget.currency,
                                ))
                            .toList(),
                      ),
                    ),
                  ],
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

  /// `null` oculta el botón "Exportar PDF" (mes en curso, cargando, etc.).
  final VoidCallback? onExportPdf;
  final bool isExportingPdf;

  const _StatisticsHeader({
    required this.selectedMonth,
    required this.onTapMonthSelector,
    this.onExportPdf,
    this.isExportingPdf = false,
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
        if (onExportPdf != null) ...[
          const SizedBox(height: 14),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.authAccent,
              side: const BorderSide(color: AppColors.authCardBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: isExportingPdf ? null : onExportPdf,
            icon: isExportingPdf
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.authAccent,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: Text(isExportingPdf ? 'Generando…' : 'Exportar PDF'),
          ),
        ],
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

/// Datos ya resueltos para una fila de [_BudgetCategoriesCard]: la
/// categoría, lo presupuestado (`category.budgetAmount`) y lo gastado en
/// ella durante el mes en curso (`0` si todavía no tiene movimientos).
class _BudgetProgress {
  final Category category;
  final double budgeted;
  final double spent;

  const _BudgetProgress({
    required this.category,
    required this.budgeted,
    required this.spent,
  });

  double get percent => budgeted > 0 ? (spent / budgeted) * 100 : 0.0;
  double get progress =>
      budgeted > 0 ? (spent / budgeted).clamp(0.0, 1.0) : 0.0;
  bool get isOverBudget => percent > 100;
}

/// Sección "Presupuesto por categoría": una fila con su propia barra por
/// cada categoría de gasto con presupuesto asignado
/// ([CategoryViewModel.budgetedCategories]) — a diferencia de la primera
/// versión, ya no agrupa todo en una sola barra. Solo se arma con el mes
/// en curso: un presupuesto es un objetivo del mes actual, no tiene
/// sentido medirlo sobre uno ya cerrado.
class _BudgetCategoriesCard extends StatelessWidget {
  final List<_BudgetProgress> items;
  final String currency;

  const _BudgetCategoriesCard({
    required this.items,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Presupuesto por categoría',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.authTextPrimary,
              ),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < items.length; i++) ...[
              _BudgetCategoryRow(item: items[i], currency: currency),
              if (i < items.length - 1) const SizedBox(height: 18),
            ],
          ],
        ),
      ),
    );
  }
}

/// Card aparte para la suma de movimientos (ingresos o gastos, sin
/// transferencias) sin categoría asignada — ayuda a notar cuánto del mes
/// todavía no está clasificado. Solo aparece si hay al menos uno (ver
/// [_StatisticsTabState.build]).
class _UncategorizedCard extends StatelessWidget {
  final double total;
  final int count;
  final String currency;

  const _UncategorizedCard({
    required this.total,
    required this.count,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.authTextSecondary.withValues(
                alpha: 0.18,
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                size: 18,
                color: AppColors.authTextSecondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sin categoría',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.authTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count == 1 ? '1 movimiento' : '$count movimientos',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.authTextFooter,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              formatCurrency(total, currency),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.authTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Una fila de [_BudgetCategoriesCard]: nombre de la categoría y
/// "$presupuesto / mes" arriba de su propia barra, y a la derecha lo
/// gastado en esa categoría puntual con su %. La barra usa el color de la
/// categoría — salvo que se haya pasado del presupuesto, ahí pasa a rojo
/// para que se note.
class _BudgetCategoryRow extends StatelessWidget {
  final _BudgetProgress item;
  final String currency;

  const _BudgetCategoryRow({required this.item, required this.currency});

  @override
  Widget build(BuildContext context) {
    final category = item.category;
    final categoryColor =
        colorFromHex(category.color, fallback: AppColors.authAccent);
    final barColor = item.isOverBudget ? AppColors.authExpense : categoryColor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.authTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${formatCurrency(item.budgeted, currency)} / mes',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.authTextSecondary,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: item.progress,
                  minHeight: 6,
                  backgroundColor: AppColors.authCardBorder,
                  color: barColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatCurrency(item.spent, currency),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.authTextPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${item.percent.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: barColor,
              ),
            ),
          ],
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

/// Gráfico de dona con el total de gastos en el centro. Cada segmento usa
/// el color propio de la categoría (category.color en la DB), igual que
/// el puntito de color de cada fila de la leyenda.
class _CategoryDonutChart extends StatelessWidget {
  final List<CategoryTotal> breakdown;
  final double total;
  final String currency;

  const _CategoryDonutChart({
    required this.breakdown,
    required this.total,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    const size = 128.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(size, size),
            painter: _DonutChartPainter(breakdown: breakdown),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Total gastos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.authTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatCurrency(total, currency),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.authTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dibuja los segmentos de la dona a partir de [CategoryTotal.percent].
/// No usa ninguna librería de gráficos — el proyecto no tenía ninguna
/// como dependencia todavía.
class _DonutChartPainter extends CustomPainter {
  final List<CategoryTotal> breakdown;
  final double strokeWidth;

  _DonutChartPainter({required this.breakdown}) : strokeWidth = 15;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Fondo de la dona, por si los porcentajes no suman 100% justo
    // (redondeo) y queda un resto sin cubrir.
    final backgroundPaint = Paint()
      ..color = AppColors.authBackgroundTop
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, 0, 2 * pi, false, backgroundPaint);

    double startAngle = -pi / 2;
    for (final item in breakdown) {
      if (item.percent <= 0) continue;

      final sweepAngle = (item.percent / 100) * 2 * pi;
      final paint = Paint()
        ..color =
            colorFromHex(item.category.color, fallback: AppColors.authAccent)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.breakdown != breakdown;
  }
}

/// Fila de la leyenda: punto de color + nombre + monto + %, todos
/// tomados de la misma categoría que pinta su segmento en la dona.
class _CategoryLegendRow extends StatelessWidget {
  final CategoryTotal category;
  final String currency;

  const _CategoryLegendRow({required this.category, required this.currency});

  @override
  Widget build(BuildContext context) {
    final color =
        colorFromHex(category.category.color, fallback: AppColors.authAccent);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              category.category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.authTextPrimary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            formatCurrency(category.amount, currency),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.authTextPrimary,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 28,
            child: Text(
              '${category.percent.toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.authTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
