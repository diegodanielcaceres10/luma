import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/utils/currency_format.dart';
import '../../data/models/transaction_entry.dart';
import '../view_models/transaction_view_model.dart';

enum _TypeFilter { all, income, expense }

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

  // null = "todas las categorías". Guarda category.id si existe, si no
  // category.name — mismo criterio que categoryBreakdown en el ViewModel.
  String? _categoryKey;

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

  String _categoryKeyOf(TransactionEntry t) => t.category.id ?? t.category.name;

  /// Categorías presentes en [typeFiltered] — solo se muestran chips de
  /// categorías que tengan al menos un movimiento bajo el filtro de tipo
  /// actual, para no ofrecer filtros que siempre van a dar vacío.
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

          final typeFiltered = vm.allTransactions.where(_matchesType).toList();
          final categories = _visibleCategories(typeFiltered);

          // Si la categoría elegida quedó fuera de las visibles bajo el
          // tipo actual (p. ej. cambiaste a "Ingresos" con una categoría de
          // gasto seleccionada), la ignoramos para este build sin tocar el
          // estado — así no queda una lista vacía sin que se note por qué.
          final effectiveCategoryKey = _categoryKey != null &&
                  categories.any((c) => _keyOf(c) == _categoryKey)
              ? _categoryKey
              : null;

          final filtered = effectiveCategoryKey == null
              ? typeFiltered
              : typeFiltered
                  .where((t) => _categoryKeyOf(t) == effectiveCategoryKey)
                  .toList();

          final grouped = _groupByMonth(filtered);
          final hasActiveFilters =
              _typeFilter != _TypeFilter.all || effectiveCategoryKey != null;

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
                  onChanged: (value) {
                    setState(() {
                      _typeFilter = value;
                      _categoryKey = null;
                    });
                  },
                ),
                if (categories.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _CategoryFilterRow(
                    categories: categories,
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
                              _categoryKey = null;
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

  String _keyOf(TransactionCategory c) => c.id ?? c.name;

  String _capitalize(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
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

/// Filtro rápido por categoría: chips horizontales, una por categoría con
/// movimientos bajo el filtro de tipo actual, más "Todas" para soltarlo.
class _CategoryFilterRow extends StatelessWidget {
  final List<TransactionCategory> categories;
  final String? selectedKey;
  final ValueChanged<String?> onSelect;

  const _CategoryFilterRow({
    required this.categories,
    required this.selectedKey,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _CategoryChip(
              label: 'Todas',
              color: AppColors.authTextSecondary,
              isSelected: selectedKey == null,
              onTap: () => onSelect(null),
            );
          }
          final category = categories[index - 1];
          final key = category.id ?? category.name;
          return _CategoryChip(
            label: category.name,
            color: colorFromHex(category.color, fallback: AppColors.authAccent),
            isSelected: selectedKey == key,
            onTap: () => onSelect(key),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
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
    final color = movement.isIncome
        ? AppColors.authIncome
        : colorFromHex(movement.category.color, fallback: AppColors.authAccent);
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
                      : iconFromName(movement.category.icon),
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
