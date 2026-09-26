import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/filter_chip_row.dart';
import '../../../accounts/presentation/view_models/account_view_model.dart';
import '../../data/models/transaction_entry.dart';
import '../view_models/transaction_view_model.dart';

enum _TypeFilter { all, income, expense }

enum _DateRangeFilter { today, thisWeek, last7Days, last15Days, all }

/// Contenido de la pantalla "Movimientos" (ver router.dart/AppShellScreen,
/// que ponen el Scaffold compartido con el header y el bottomNavigationBar).
class MovementsTab extends StatefulWidget {
  final String userId;
  final TransactionViewModel transactionViewModel;
  final AccountViewModel accountViewModel;
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
  /// "Estadísticas"), en formato `YYYY-MM`. `null`, o un valor con formato
  /// inválido, usan el mes en curso por default.
  final String? initialMonth;

  const MovementsTab({
    super.key,
    required this.userId,
    required this.transactionViewModel,
    required this.accountViewModel,
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

  // A diferencia de _dateRange (rangos relativos a hoy), este elige un
  // mes calendario puntual — mismo selector que el de "Estadísticas"
  // (ver _MonthSelectorPill). Siempre tiene un valor: si no viene por la
  // URL, arranca en el mes en curso.
  late DateTime _selectedMonth;

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
    }
  }

  /// El 1º del mes en curso — default cuando no hay `?month=` en la URL
  /// o cuando viene con un formato inválido.
  static DateTime _currentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  static bool _isCurrentMonth(DateTime month) {
    final current = _currentMonth();
    return month.year == current.year && month.month == current.month;
  }

  /// 'YYYY-MM' -> el 1º de ese mes, o el mes en curso si falta el param
  /// o no tiene el formato esperado (en vez de reventar con un query
  /// param manipulado a mano).
  static DateTime _monthFromQuery(String? value) {
    if (value == null) return _currentMonth();
    final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(value);
    if (match == null) return _currentMonth();
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    if (month < 1 || month > 12) return _currentMonth();
    return DateTime(year, month);
  }

  /// El mes en curso es el default, así que no ensucia la URL — mismo
  /// criterio que el resto de los filtros (p. ej. `_typeQueryValue`, que
  /// tampoco agrega param para "Todos").
  static String? _monthQueryValue(DateTime month) {
    if (_isCurrentMonth(month)) return null;
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
    required DateTime month,
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

  void _pushMonth(DateTime value) => _pushFilters(
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
        month: _currentMonth(),
      );

  /// Abre la hoja del selector de mes (mismo control y mismo mes en
  /// curso por default que "Estadísticas" — ver `_MonthPickerSheet` en
  /// statistics_tab.dart) y hace push del mes elegido. `null` en el
  /// resultado es "el usuario cerró la hoja sin tocar nada".
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
      _pushMonth(picked);
    }
  }

  /// Movimientos visibles en la lista. Empieza en 10 y crece de a 10 con
  /// "Ver más". Ya no hace falta agruparlos por mes (ver el diff que
  /// borró [_groupByMonth]): `filtered` siempre queda acotado a un único
  /// mes calendario por [_matchesMonth], el que ya se ve en
  /// [_MonthSelectorPill], así que un segundo encabezado con el mismo
  /// mes era redundante.
  int _visibleCount = _pageSize;

  static const int _pageSize = 10;

  // Id del movimiento que se está borrando en este momento, o null si no
  // hay ninguno en curso. Deshabilita el botón de esa fila mientras dura
  // el pedido, para no disparar dos borrados del mismo movimiento con un
  // doble tap.
  String? _deletingId;

  /// Confirma con el usuario antes de borrar (mismo patrón de AlertDialog
  /// que `_confirmCancel` en invoices_tab.dart) y, si confirma, borra el
  /// movimiento y refresca el saldo de la cuenta.
  Future<void> _confirmDelete(TransactionEntry movement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.authBackgroundTop,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.authCardBorder),
        ),
        title: const Text(
          '¿Eliminar movimiento?',
          style: TextStyle(
            color: AppColors.authTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '${movement.description?.isNotEmpty == true ? movement.description! : movement.category.name} · '
          '${formatCurrency(movement.amount, widget.currency)}\n\n'
          'El saldo de la cuenta se va a actualizar. Esta acción no se '
          'puede deshacer.',
          style: const TextStyle(color: AppColors.authTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Volver',
              style: TextStyle(color: AppColors.authTextSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(
                color: AppColors.authExpense,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteMovement(movement);
    }
  }

  Future<void> _deleteMovement(TransactionEntry movement) async {
    setState(() => _deletingId = movement.id);

    final success = await widget.transactionViewModel.deleteTransaction(
      userId: widget.userId,
      transactionId: movement.id,
    );

    if (!mounted) return;

    if (success) {
      // El saldo de la cuenta se revirtió en el servidor junto con el
      // borrado (RPC delete_transaction); acá solo recargamos la lista
      // de cuentas para que el nuevo saldo se vea en pantalla — mismo
      // criterio que _AddTransactionTabState._submit tras crear.
      await widget.accountViewModel.loadAccounts();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.transactionViewModel.errorMessage ??
                'No se pudo eliminar el movimiento.',
          ),
        ),
      );
    }

    if (mounted) setState(() => _deletingId = null);
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
    }
  }

  bool _matchesMonth(TransactionEntry t) =>
      t.date.year == _selectedMonth.year &&
      t.date.month == _selectedMonth.month;

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

          final hasActiveFilters = _typeFilter != _TypeFilter.all ||
              _dateRange != _DateRangeFilter.all ||
              !_isCurrentMonth(_selectedMonth) ||
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
                    (
                      value: _DateRangeFilter.last7Days,
                      label: 'Últimos 7 días'
                    ),
                    (
                      value: _DateRangeFilter.last15Days,
                      label: 'Últimos 15 días'
                    ),
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
                  Builder(builder: (context) {
                    final total = filtered.length;
                    final visibleCount = _visibleCount.clamp(0, total);
                    final visible = filtered.take(visibleCount).toList();
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
                            final movement = visible[i];
                            return _MovementRow(
                              movement: movement,
                              currency: widget.currency,
                              showDivider:
                                  i != visible.length - 1 || remaining > 0,
                              isDeleting: _deletingId == movement.id,
                              onDelete: () => _confirmDelete(movement),
                            );
                          }),
                          if (remaining > 0)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: TextButton(
                                onPressed: () => setState(() {
                                  _visibleCount = visibleCount + _pageSize;
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
              ],
            ),
          );
        },
      ),
    );
  }

  String _categoryModelKey(TransactionCategory c) => c.id ?? c.name;

  String _accountModelKey(TransactionAccount a) => a.id ?? a.name;
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

  /// true mientras este movimiento puntual se está borrando — deshabilita
  /// el botón y muestra un spinner en su lugar, para no disparar un
  /// segundo borrado con un doble tap.
  final bool isDeleting;

  /// Pide confirmación y borra el movimiento (ver
  /// `_MovementsTabState._confirmDelete`). null lo deja sin botón de
  /// borrado (no se usa hoy, pero deja la fila reutilizable).
  final VoidCallback? onDelete;

  const _MovementRow({
    required this.movement,
    required this.currency,
    required this.showDivider,
    this.isDeleting = false,
    this.onDelete,
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
                  // Una transferencia no es ni ingreso ni gasto (ver
                  // TransactionEntry.isTransfer): color neutro en vez de
                  // authIncome/authExpense.
                  color: movement.isTransfer
                      ? AppColors.authTransfer
                      : movement.isIncome
                          ? AppColors.authIncome
                          : AppColors.authExpense,
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 4),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: isDeleting
                      ? const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.authTextSecondary,
                            ),
                          ),
                        )
                      : IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: AppColors.authTextSecondary,
                          ),
                          tooltip: 'Eliminar movimiento',
                          onPressed: onDelete,
                        ),
                ),
              ],
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: AppColors.authCardBorder),
      ],
    );
  }
}

/// Botón tipo pill que muestra el mes elegido y abre el selector. Mismo
/// patrón visual y mismo comportamiento (siempre un mes puntual, nunca
/// "todos los meses") que `_MonthSelectorPill` de statistics_tab.dart;
/// adaptado acá porque ese es privado del otro archivo.
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

/// Hoja del selector de mes. Misma estructura y estilo que
/// `_MonthPickerSheet` de statistics_tab.dart (siempre un mes puntual,
/// sin opción de "Todos los meses").
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
