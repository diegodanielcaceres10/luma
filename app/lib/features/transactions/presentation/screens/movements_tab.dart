import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/filter_chip_row.dart';
import '../../data/models/transaction_entry.dart';
import '../view_models/transaction_view_model.dart';

enum _TypeFilter { all, income, expense }

enum _DateRangeFilter { today, thisWeek, last7Days, last15Days, thisMonth, all }

/// Contenido de la pantalla "Movimientos" (ver router.dart/AppShellScreen,
/// que ponen el Scaffold compartido con el header y el bottomNavigationBar).
class MovementsTab extends StatefulWidget {
  final TransactionViewModel transactionViewModel;
  final String currency;

  /// Filtros con los que arranca esta instancia, tal cual vienen de la
  /// URL (`?type=income|expense&range=today|week|last7|last15|month
  /// &category=<key>&account=<key>&month=YYYY-MM`; sin un query param es
  /// "sin ese filtro"). Se leen una sola vez, al crear el State — tocar
  /// cualquier chip hace push a una URL nueva con los filtros combinados,
  /// en vez de cambiar el estado local, así que cada combinación queda
  /// como su propia entrada en el historial y se puede volver a la
  /// anterior con "atrás".
  final String? initialType;
  final String? initialRange;
  final String? initialCategory;
  final String? initialAccount;

  /// Mes puntual elegido con el selector de mes (mismo control que el de
  /// "Estadísticas"), en formato `YYYY-MM`. `null` es "todos los meses".
  final String? initialMonth;

  const MovementsTab({
    super.key,
    required this.transactionViewModel,
    required this.currency,
    this.initialType,
    this.initialRange,
    this.initialCategory,
    this.initialAccount,
    this.initialMonth,
  });

  @override
  State<MovementsTab> createState() => _MovementsTabState();
}

class _MovementsTabState extends State<MovementsTab> {
  late _TypeFilter _typeFilter;
  late _DateRangeFilter _dateRange;

  // null = "todas". Guardan category.id/account.id si existen, si no el
  // nombre — mismo criterio que categoryBreakdown en el ViewModel.
  late String? _categoryKey;
  late String? _accountKey;

  // null = "todos los meses". A diferencia de _dateRange (rangos
  // relativos a hoy), este elige un mes calendario puntual — mismo
  // selector que el de "Estadísticas" (ver _MonthSelectorPill).
  late DateTime? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _typeFilter = _typeFromQuery(widget.initialType);
    _dateRange = _rangeFromQuery(widget.initialRange);
    _categoryKey = widget.initialCategory;
    _accountKey = widget.initialAccount;
    _selectedMonth = _monthFromQuery(widget.initialMonth);
    // Carga perezosa: el historial completo de transacciones recién se
    // pide al entrar a "Movimientos", no al arrancar. La pantalla se crea
    // de nuevo en cada visita (no se mantiene viva al cambiar de
    // pestaña), así que el historial completo se vuelve a pedir cada vez:
    // decisión a propósito — para un uso personal el volumen es chico y
    // así los datos siempre están frescos.
    //
    // `loadAllTransactions` llama a `notifyListeners()` antes del primer
    // `await` (para prender el spinner ya mismo) — eso corre en el mismo
    // tick que este `initState`, mientras el framework todavía está
    // construyendo el árbol, y cualquier `ListenableBuilder` que ya esté
    // escuchando a este ViewModel más arriba explota con "setState() or
    // markNeedsBuild() called during build". Con `addPostFrameCallback`
    // se pide recién cuando termina de construirse este frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.transactionViewModel.loadAllTransactions();
    });
  }

  static _TypeFilter _typeFromQuery(String? value) {
    switch (value) {
      case 'income':
        return _TypeFilter.income;
      case 'expense':
        return _TypeFilter.expense;
      default:
        return _TypeFilter.all;
    }
  }

  static String? _typeQueryValue(_TypeFilter filter) {
    switch (filter) {
      case _TypeFilter.all:
        return null;
      case _TypeFilter.income:
        return 'income';
      case _TypeFilter.expense:
        return 'expense';
    }
  }

  static _DateRangeFilter _rangeFromQuery(String? value) {
    switch (value) {
      case 'today':
        return _DateRangeFilter.today;
      case 'week':
        return _DateRangeFilter.thisWeek;
      case 'last7':
        return _DateRangeFilter.last7Days;
      case 'last15':
        return _DateRangeFilter.last15Days;
      case 'month':
        return _DateRangeFilter.thisMonth;
      default:
        return _DateRangeFilter.all;
    }
  }

  static String? _rangeQueryValue(_DateRangeFilter filter) {
    switch (filter) {
      case _DateRangeFilter.all:
        return null;
      case _DateRangeFilter.today:
        return 'today';
      case _DateRangeFilter.thisWeek:
        return 'week';
      case _DateRangeFilter.last7Days:
        return 'last7';
      case _DateRangeFilter.last15Days:
        return 'last15';
      case _DateRangeFilter.thisMonth:
        return 'month';
    }
  }

  /// 'YYYY-MM' -> el 1º de ese mes, o `null` si falta el param o no
  /// tiene el formato esperado (sin filtro, en vez de reventar con un
  /// query param manipulado a mano).
  static DateTime? _monthFromQuery(String? value) {
    if (value == null) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(value);
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    if (month < 1 || month > 12) return null;
    return DateTime(year, month);
  }

  static String? _monthQueryValue(DateTime? month) {
    if (month == null) return null;
    final mm = month.month.toString().padLeft(2, '0');
    return '${month.year}-$mm';
  }

  /// Arma la URL con los filtros combinados (los que no cambiaron
  /// quedan en su valor actual) y hace push — ver el doc de
  /// [MovementsTab.initialType] y hermanos.
  void _pushFilters({
    required _TypeFilter type,
    required _DateRangeFilter range,
    required String? categoryKey,
    required String? accountKey,
    required DateTime? month,
  }) {
    final params = <String, String>{};
    final typeValue = _typeQueryValue(type);
    if (typeValue != null) params['type'] = typeValue;
    final rangeValue = _rangeQueryValue(range);
    if (rangeValue != null) params['range'] = rangeValue;
    if (categoryKey != null) params['category'] = categoryKey;
    if (accountKey != null) params['account'] = accountKey;
    final monthValue = _monthQueryValue(month);
    if (monthValue != null) params['month'] = monthValue;

    final uri = Uri(
      path: '/movements',
      queryParameters: params.isEmpty ? null : params,
    );
    context.push(uri.toString());
  }

  void _pushType(_TypeFilter value) => _pushFilters(
        type: value,
        range: _dateRange,
        categoryKey: _categoryKey,
        accountKey: _accountKey,
        month: _selectedMonth,
      );

  void _pushRange(_DateRangeFilter value) => _pushFilters(
        type: _typeFilter,
        range: value,
        categoryKey: _categoryKey,
        accountKey: _accountKey,
        month: _selectedMonth,
      );

  void _pushCategory(String? value) => _pushFilters(
        type: _typeFilter,
        range: _dateRange,
        categoryKey: value,
        accountKey: _accountKey,
        month: _selectedMonth,
      );

  void _pushAccount(String? value) => _pushFilters(
        type: _typeFilter,
        range: _dateRange,
        categoryKey: _categoryKey,
        accountKey: value,
        month: _selectedMonth,
      );

  void _pushMonth(DateTime? value) => _pushFilters(
        type: _typeFilter,
        range: _dateRange,
        categoryKey: _categoryKey,
        accountKey: _accountKey,
        month: value,
      );

  void _pushClearFilters() => _pushFilters(
        type: _TypeFilter.all,
        range: _DateRangeFilter.all,
        categoryKey: null,
        accountKey: null,
        month: null,
      );

  /// Abre la hoja del selector de mes (mismo control que el de
  /// "Estadísticas" — ver `_MonthPickerSheet` en statistics_tab.dart) y
  /// hace push del mes elegido. `null` en el resultado es "el usuario
  /// cerró la hoja sin tocar nada"; distinto de elegir "Todos los
  /// meses", que sí devuelve un [_MonthSelection] con `month: null`.
  Future<void> _pickMonth() async {
    final result = await showModalBottomSheet<_MonthSelection>(
      context: context,
      backgroundColor: AppColors.authBackgroundBottom,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _MonthPickerSheet(selectedMonth: _selectedMonth),
    );

    if (result != null && mounted) {
      _pushMonth(result.month);
    }
  }

  /// Movimientos visibles por cada grupo de mes (clave = la misma que
  /// arma [_groupByMonth]). Empieza en 10 y crece de a 10 con "Ver más".
  /// Un mes que no está acá todavía se muestra con el default de
  /// [_visibleCountFor].
  final Map<String, int> _visibleCountByMonth = {};

  static const int _pageSize = 10;

  int _visibleCountFor(String monthKey) =>
      _visibleCountByMonth[monthKey] ?? _pageSize;

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

  /// Igual criterio que [_matchesDateRange]: `_selectedMonth == null` es
  /// "todos los meses".
  bool _matchesMonth(TransactionEntry t) {
    final month = _selectedMonth;
    if (month == null) return true;
    return t.date.year == month.year && t.date.month == month.month;
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

          final dateFiltered = vm.allTransactions
              .where(_matchesDateRange)
              .where(_matchesMonth)
              .toList();
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
              _selectedMonth != null ||
              effectiveCategoryKey != null ||
              effectiveAccountKey != null;

          return RefreshIndicator(
            onRefresh: vm.loadAllTransactions,
            color: AppColors.authAccent,
            backgroundColor: AppColors.authBackgroundTop,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Text(
                        'Movimientos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.authTextPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _MonthSelectorPill(
                      selectedMonth: _selectedMonth,
                      onTap: _pickMonth,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilterChipRow<_TypeFilter>(
                  options: const [
                    (value: _TypeFilter.all, label: 'Todos'),
                    (value: _TypeFilter.income, label: 'Ingresos'),
                    (value: _TypeFilter.expense, label: 'Gastos'),
                  ],
                  selectedValue: _typeFilter,
                  onChanged: (value) {
                    if (value != _typeFilter) _pushType(value);
                  },
                ),
                const SizedBox(height: 12),
                const _FilterSectionLabel('Período'),
                const SizedBox(height: 6),
                FilterChipRow<_DateRangeFilter>(
                  options: const [
                    (value: _DateRangeFilter.all, label: 'Todo'),
                    (value: _DateRangeFilter.today, label: 'Hoy'),
                    (value: _DateRangeFilter.thisWeek, label: 'Esta semana'),
                    (value: _DateRangeFilter.last7Days, label: 'Últimos 7 días'),
                    (
                      value: _DateRangeFilter.last15Days,
                      label: 'Últimos 15 días'
                    ),
                    (value: _DateRangeFilter.thisMonth, label: 'Este mes'),
                  ],
                  selectedValue: _dateRange,
                  onChanged: (value) {
                    if (value != _dateRange) _pushRange(value);
                  },
                ),
                if (accounts.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const _FilterSectionLabel('Cuenta'),
                  const SizedBox(height: 6),
                  FilterChipRow<String?>(
                    options: <({String? value, String label})>[
                      (value: null, label: 'Todas'),
                      ...accounts.map(
                        (a) => (value: _accountModelKey(a), label: a.name),
                      ),
                    ],
                    selectedValue: effectiveAccountKey,
                    onChanged: (key) {
                      if (key != _accountKey) _pushAccount(key);
                    },
                  ),
                ],
                if (categories.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const _FilterSectionLabel('Categoría'),
                  const SizedBox(height: 6),
                  FilterChipRow<String?>(
                    options: <({String? value, String label})>[
                      (value: null, label: 'Todas'),
                      ...categories.map(
                        (c) => (value: _categoryModelKey(c), label: c.name),
                      ),
                    ],
                    selectedValue: effectiveCategoryKey,
                    onChanged: (key) {
                      if (key != _categoryKey) _pushCategory(key);
                    },
                  ),
                ],
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  _EmptyFilteredState(
                    onClear: hasActiveFilters ? _pushClearFilters : null,
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
                    Builder(builder: (context) {
                      final total = entry.value.length;
                      final visibleCount =
                          _visibleCountFor(entry.key).clamp(0, total);
                      final visible = entry.value.take(visibleCount).toList();
                      final remaining = total - visibleCount;

                      return DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.authCardFill,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.authCardBorder),
                        ),
                        child: Column(
                          children: [
                            ...List.generate(visible.length, (i) {
                              return _MovementRow(
                                movement: visible[i],
                                currency: widget.currency,
                                showDivider:
                                    i != visible.length - 1 || remaining > 0,
                              );
                            }),
                            if (remaining > 0)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: TextButton(
                                  onPressed: () => setState(() {
                                    _visibleCountByMonth[entry.key] =
                                        visibleCount + _pageSize;
                                  }),
                                  child: Text(
                                    'Ver más (${remaining > _pageSize ? _pageSize : remaining})',
                                    style: const TextStyle(
                                      color: AppColors.authAccent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
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
    final sign = movement.isIncome ? '+' : '-';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
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

/// Botón tipo pill que muestra el mes elegido (o "Todos los meses") y
/// abre el selector. Mismo patrón visual que `_MonthSelectorPill` de
/// statistics_tab.dart, adaptado acá porque ese es privado del otro
/// archivo y "todos los meses" es un estado válido en Movimientos (a
/// diferencia de Estadísticas, que siempre muestra un mes puntual).
class _MonthSelectorPill extends StatelessWidget {
  final DateTime? selectedMonth;
  final VoidCallback onTap;

  const _MonthSelectorPill({
    required this.selectedMonth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final month = selectedMonth;

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
              month == null ? 'Todos los meses' : _monthLabel(month),
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

/// Resultado de [_MonthPickerSheet]: `month` en `null` es "Todos los
/// meses". Se distingue de "el usuario cerró la hoja sin elegir nada"
/// porque en ese caso `Navigator.pop` no se llama con esta clase — el
/// modal devuelve `null` directamente (ver [_MovementsTabState._pickMonth]).
class _MonthSelection {
  final DateTime? month;

  const _MonthSelection(this.month);
}

/// Hoja del selector de mes. Igual estructura y estilo que
/// `_MonthPickerSheet` de statistics_tab.dart, con un ítem extra al
/// principio ("Todos los meses") para poder sacar el filtro.
class _MonthPickerSheet extends StatelessWidget {
  final DateTime? selectedMonth;

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
      // Mismo motivo que en statistics_tab.dart: acota el alto total de
      // la hoja a una fracción de la pantalla para que no desborde en
      // pantallas bajas.
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
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: months.length + 1,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: AppColors.authCardBorder,
                  ),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = selectedMonth == null;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Todos los meses',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
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
                        onTap: () => Navigator.of(context)
                            .pop(const _MonthSelection(null)),
                      );
                    }

                    final month = months[index - 1];
                    final current = selectedMonth;
                    final isSelected = current != null &&
                        month.year == current.year &&
                        month.month == current.month;

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
                      onTap: () =>
                          Navigator.of(context).pop(_MonthSelection(month)),
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
