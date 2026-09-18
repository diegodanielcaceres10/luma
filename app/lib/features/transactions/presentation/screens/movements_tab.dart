import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/utils/currency_format.dart';
import '../../data/models/transaction_entry.dart';
import '../view_models/transaction_view_model.dart';

enum _TypeFilter { all, income, expense }

enum _DateRangeFilter { today, thisWeek, last7Days, last15Days, thisMonth, all }

/// Contenido de la pestaña "Movimientos". No tiene Scaffold propio — vive
/// dentro del Scaffold del HomeShell, que es quien pone el header y el
/// bottomNavigationBar.
class MovementsTab extends StatefulWidget {
  final TransactionViewModel transactionViewModel;
  final String currency;

  const MovementsTab({
    super.key,
    required this.transactionViewModel,
    required this.currency,
  });

  @override
  State<MovementsTab> createState() => _MovementsTabState();
}

class _MovementsTabState extends State<MovementsTab> {
  _TypeFilter _typeFilter = _TypeFilter.all;
  _DateRangeFilter _dateRange = _DateRangeFilter.all;

  // null = "todas". Guardan category.id/account.id si existen, si no el
  // nombre — mismo criterio que categoryBreakdown en el ViewModel.
  String? _categoryKey;
  String? _accountKey;

  Map<String, List<TransactionEntry>> _groupByMonth(
      List<TransactionEntry> transactions) {
    final monthFormat = DateFormat('MMMM yyyy', 'es');
    final Map<String, List<TransactionEntry>> grouped = {};

    for (final t in transactions) {
      final key = monthFormat.format(DateTime(t.date.year, t.date.month));
      grouped.putIfAbsent(key, () => []).add(t);
    }

    return grouped;
  }

  bool _matchesType(TransactionEntry t) {
    switch (_typeFilter) {
      case _TypeFilter.all:
        return true;
      case _TypeFilter.income:
        return t.isIncome;
      case _TypeFilter.expense:
        return !t.isIncome;
    }
  }

  bool _matchesDateRange(TransactionEntry t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDate = DateTime(t.date.year, t.date.month, t.date.day);
    switch (_dateRange) {
      case _DateRangeFilter.all:
        return true;
      case _DateRangeFilter.today:
        return txDate == today;
      case _DateRangeFilter.thisWeek:
        // Semana de lunes a domingo.
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        return !txDate.isBefore(startOfWeek) && !txDate.isAfter(today);
      case _DateRangeFilter.last7Days:
        final start = today.subtract(const Duration(days: 6));
        return !txDate.isBefore(start) && !txDate.isAfter(today);
      case _DateRangeFilter.last15Days:
        final start = today.subtract(const Duration(days: 14));
        return !txDate.isBefore(start) && !txDate.isAfter(today);
      case _DateRangeFilter.thisMonth:
        return t.date.year == now.year && t.date.month == now.month;
    }
  }

  String _categoryKeyOf(TransactionEntry t) => t.category.id ?? t.category.name;

  String _accountKeyOf(TransactionEntry t) => t.account.id ?? t.account.name;

  /// Categorías presentes en [typeFiltered] — solo se muestran chips de
  /// categorías que tengan al menos un movimiento bajo los filtros de
  /// tipo/fecha actuales, para no ofrecer filtros que siempre van a dar
  /// vacío.
  List<TransactionCategory> _visibleCategories(
      List<TransactionEntry> typeFiltered) {
    final Map<String, TransactionCategory> byKey = {};
    for (final t in typeFiltered) {
      byKey[_categoryKeyOf(t)] = t.category;
    }
    final list = byKey.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  /// Igual que [_visibleCategories], pero para cuentas.
  List<TransactionAccount> _visibleAccounts(
      List<TransactionEntry> typeFiltered) {
    final Map<String, TransactionAccount> byKey = {};
    for (final t in typeFiltered) {
      byKey[_accountKeyOf(t)] = t.account;
    }
    final list = byKey.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListenableBuilder(
        listenable: widget.transactionViewModel,
        builder: (context, _) {
          final vm = widget.transactionViewModel;

          if (vm.isLoadingAll && vm.allTransactions.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.authAccent),
            );
          }

          if (vm.allTransactions.isEmpty) {
            return RefreshIndicator(
              onRefresh: vm.loadAllTransactions,
              color: AppColors.authAccent,
              backgroundColor: AppColors.authBackgroundTop,
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      'Todavía no hay movimientos.',
                      style: AppTextStyles.authSubtitle,
                    ),
                  ),
                ],
              ),
            );
          }

          final dateFiltered =
              vm.allTransactions.where(_matchesDateRange).toList();
          final typeFiltered = dateFiltered.where(_matchesType).toList();
          final categories = _visibleCategories(typeFiltered);
          final accounts = _visibleAccounts(typeFiltered);

          // Si la categoría/cuenta elegida quedó fuera de las visibles bajo
          // los filtros actuales (p. ej. cambiaste a "Ingresos" con una
          // categoría de gasto seleccionada), la ignoramos para este build
          // sin tocar el estado — así no queda una lista vacía sin que se
          // note por qué, y el chip vuelve a aparecer resaltado si volvés
          // al filtro anterior.
          final effectiveCategoryKey = _categoryKey != null &&
                  categories.any((c) => _categoryModelKey(c) == _categoryKey)
              ? _categoryKey
              : null;
          final effectiveAccountKey = _accountKey != null &&
                  accounts.any((a) => _accountModelKey(a) == _accountKey)
              ? _accountKey
              : null;

          var filtered = typeFiltered;
          if (effectiveCategoryKey != null) {
            filtered = filtered
                .where((t) => _categoryKeyOf(t) == effectiveCategoryKey)
                .toList();
          }
          if (effectiveAccountKey != null) {
            filtered = filtered
                .where((t) => _accountKeyOf(t) == effectiveAccountKey)
                .toList();
          }

          final grouped = _groupByMonth(filtered);
          final hasActiveFilters = _typeFilter != _TypeFilter.all ||
              _dateRange != _DateRangeFilter.all ||
              effectiveCategoryKey != null ||
              effectiveAccountKey != null;

          return RefreshIndicator(
            onRefresh: vm.loadAllTransactions,
            color: AppColors.authAccent,
            backgroundColor: AppColors.authBackgroundTop,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                const Text(
                  'Movimientos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.authTextPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _TypeFilterRow(
                  value: _typeFilter,
                  onChanged: (value) => setState(() => _typeFilter = value),
                ),
                const SizedBox(height: 12),
                const _FilterSectionLabel('Período'),
                const SizedBox(height: 6),
                _DateRangeFilterRow(
                  value: _dateRange,
                  onChanged: (value) => setState(() => _dateRange = value),
                ),
                if (accounts.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const _FilterSectionLabel('Cuenta'),
                  const SizedBox(height: 6),
                  _ChipFilterRow(
                    items: accounts
                        .map((a) => (
                              key: _accountModelKey(a),
                              label: a.name,
                              color: colorFromHex(a.color,
                                  fallback: AppColors.authTextSecondary),
                            ))
                        .toList(),
                    selectedKey: effectiveAccountKey,
                    onSelect: (key) => setState(() => _accountKey = key),
                  ),
                ],
                if (categories.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const _FilterSectionLabel('Categoría'),
                  const SizedBox(height: 6),
                  _ChipFilterRow(
                    items: categories
                        .map((c) => (
                              key: _categoryModelKey(c),
                              label: c.name,
                              color: AppColors.authAccent,
                            ))
                        .toList(),
                    selectedKey: effectiveCategoryKey,
                    onSelect: (key) => setState(() => _categoryKey = key),
                  ),
                ],
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  _EmptyFilteredState(
                    onClear: hasActiveFilters
                        ? () => setState(() {
                              _typeFilter = _TypeFilter.all;
                              _dateRange = _DateRangeFilter.all;
                              _categoryKey = null;
                              _accountKey = null;
                            })
                        : null,
                  )
                else
                  for (final entry in grouped.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 8),
                      child: Text(
                        _capitalize(entry.key),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.authTextSecondary,
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.authCardFill,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.authCardBorder),
                      ),
                      child: Column(
                        children: List.generate(entry.value.length, (i) {
                          return _MovementRow(
                            movement: entry.value[i],
                            currency: widget.currency,
                            showDivider: i != entry.value.length - 1,
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _categoryModelKey(TransactionCategory c) => c.id ?? c.name;

  String _accountModelKey(TransactionAccount a) => a.id ?? a.name;

  String _capitalize(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}

/// Etiqueta chica sobre cada fila de chips (Período / Cuenta / Categoría),
/// para que se entienda qué filtra cada una sin agregar otro control.
class _FilterSectionLabel extends StatelessWidget {
  final String label;

  const _FilterSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: AppColors.authTextFooter,
      ),
    );
  }
}

/// Filtro rápido por tipo: Todos / Ingresos / Gastos, estilo segmented
/// control para no ocupar más de una fila chica.
class _TypeFilterRow extends StatelessWidget {
  final _TypeFilter value;
  final ValueChanged<_TypeFilter> onChanged;

  const _TypeFilterRow({required this.value, required this.onChanged});

  static const _options = [
    (_TypeFilter.all, 'Todos'),
    (_TypeFilter.income, 'Ingresos'),
    (_TypeFilter.expense, 'Gastos'),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: _options.map((option) {
            final isSelected = option.$1 == value;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(option.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.authAccent : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    option.$2,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.authBackgroundBottom
                          : AppColors.authTextSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Filtro rápido por rango de fechas: Todo / Hoy / Esta semana / Últimos 7
/// días / Últimos 15 días / Este mes. Se muestran en varias líneas (Wrap)
/// para que todas las opciones queden visibles sin scroll horizontal.
/// Chips sin punto de color (no representan una entidad con color propio
/// como categoría/cuenta).
class _DateRangeFilterRow extends StatelessWidget {
  final _DateRangeFilter value;
  final ValueChanged<_DateRangeFilter> onChanged;

  const _DateRangeFilterRow({required this.value, required this.onChanged});

  static const _options = [
    (_DateRangeFilter.all, 'Todo'),
    (_DateRangeFilter.today, 'Hoy'),
    (_DateRangeFilter.thisWeek, 'Esta semana'),
    (_DateRangeFilter.last7Days, 'Últimos 7 días'),
    (_DateRangeFilter.last15Days, 'Últimos 15 días'),
    (_DateRangeFilter.thisMonth, 'Este mes'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _options.map((option) {
        return _PlainChip(
          label: option.$2,
          isSelected: option.$1 == value,
          onTap: () => onChanged(option.$1),
        );
      }).toList(),
    );
  }
}

/// Filtro rápido por categoría o cuenta: chips que fluyen horizontalmente
/// y saltan de línea al llegar al borde (Wrap), una por cada valor con
/// movimientos bajo los demás filtros activos, más "Todas" para soltarlo.
/// Genérica para no duplicar la misma fila para cuenta y categoría.
class _ChipFilterRow extends StatelessWidget {
  final List<({String key, String label, Color color})> items;
  final String? selectedKey;
  final ValueChanged<String?> onSelect;

  const _ChipFilterRow({
    required this.items,
    required this.selectedKey,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ColorChip(
          label: 'Todas',
          color: AppColors.authTextSecondary,
          isSelected: selectedKey == null,
          onTap: () => onSelect(null),
        ),
        for (final item in items)
          _ColorChip(
            label: item.label,
            color: item.color,
            isSelected: selectedKey == item.key,
            onTap: () => onSelect(item.key),
          ),
      ],
    );
  }
}

/// Chip simple (sin punto de color), para el filtro de período.
class _PlainChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlainChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.authAccent.withValues(alpha: 0.18)
              : AppColors.authCardFill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.authAccent : AppColors.authCardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? AppColors.authTextPrimary
                : AppColors.authTextSecondary,
          ),
        ),
      ),
    );
  }
}

/// Chip con punto de color, para el filtro de categoría o cuenta.
class _ColorChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.18)
              : AppColors.authCardFill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? color : AppColors.authCardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.authTextPrimary
                    : AppColors.authTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFilteredState extends StatelessWidget {
  final VoidCallback? onClear;

  const _EmptyFilteredState({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          const Text(
            'No hay movimientos con estos filtros.',
            textAlign: TextAlign.center,
            style: AppTextStyles.authSubtitle,
          ),
          if (onClear != null) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: onClear,
                child: const Text(
                  'Quitar filtros',
                  style: TextStyle(
                    color: AppColors.authAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MovementRow extends StatelessWidget {
  final TransactionEntry movement;
  final String currency;
  final bool showDivider;

  const _MovementRow({
    required this.movement,
    required this.currency,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM. yyyy', 'es');
    final color =
        movement.isIncome ? AppColors.authIncome : AppColors.authAccent;
    final sign = movement.isIncome ? '+' : '-';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.85),
                child: Icon(
                  movement.isIncome
                      ? Icons.arrow_downward_rounded
                      : Icons.more_horiz_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movement.description?.isNotEmpty == true
                          ? movement.description!
                          : movement.category.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.authTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${movement.category.name} · ${dateFormat.format(movement.date)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.authTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$sign${formatCurrency(movement.amount, currency)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: movement.isIncome
                      ? AppColors.authIncome
                      : AppColors.authExpense,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: AppColors.authCardBorder),
      ],
    );
  }
}
