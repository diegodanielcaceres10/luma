import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/filter_chip_row.dart';
import '../../../../core/widgets/month_filter_button.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../auth/presentation/view_models/preferences_view_model.dart';
import '../../../notifications/presentation/widgets/notifications_hint.dart';
import '../../../services/presentation/view_models/service_view_model.dart';
import '../../data/models/invoice.dart';
import '../utils/month_names.dart';
import '../view_models/invoice_view_model.dart';

enum _StatusFilter { all, pending, paid, cancelled }

class InvoicesScreen extends StatefulWidget {
  final InvoiceViewModel invoiceViewModel;
  final ServiceViewModel serviceViewModel;
  final PreferencesViewModel preferencesViewModel;
  final String currency;

  /// Status filter this instance starts with, as it comes from the URL
  /// (`?filter=pending|paid|cancelled`; no param means "Todas"). Read once,
  /// when the State is created: changing a filter pushes a new URL instead
  /// of mutating local state, so "back" returns to the previous filter.
  final String? initialFilter;

  /// Month this instance starts with, as `YYYY-MM` (query param `month`).
  /// Missing or invalid falls back to the current month. Read once, like
  /// [initialFilter].
  final String? initialMonth;

  final ValueChanged<Invoice> onOpenView;

  /// Opens the create form.
  final VoidCallback onOpenForm;

  /// Opens Preferencias, from the notifications hint.
  final VoidCallback onOpenPreferences;

  final VoidCallback? onBack;

  const InvoicesScreen({
    super.key,
    required this.invoiceViewModel,
    required this.serviceViewModel,
    required this.preferencesViewModel,
    required this.currency,
    required this.onOpenView,
    required this.onOpenForm,
    required this.onOpenPreferences,
    this.onBack,
    this.initialFilter,
    this.initialMonth,
  });

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  late _StatusFilter _statusFilter;

  // Always a specific month (never "all months"); defaults to the current one.
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _statusFilter = _filterFromQuery(widget.initialFilter);
    _selectedMonth = _monthFromQuery(widget.initialMonth);
  }

  static DateTime _currentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  static bool _isCurrentMonth(DateTime month) {
    final current = _currentMonth();
    return month.year == current.year && month.month == current.month;
  }

  /// 'YYYY-MM' -> first day of that month; the current month if the param is
  /// missing or malformed.
  static DateTime _monthFromQuery(String? value) {
    if (value == null) return _currentMonth();
    final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(value);
    if (match == null) return _currentMonth();
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    if (month < 1 || month > 12) return _currentMonth();
    return DateTime(year, month);
  }

  static _StatusFilter _filterFromQuery(String? value) {
    switch (value) {
      case 'pending':
        return _StatusFilter.pending;
      case 'paid':
        return _StatusFilter.paid;
      case 'cancelled':
        return _StatusFilter.cancelled;
      default:
        return _StatusFilter.all;
    }
  }

  static String? _filterQueryValue(_StatusFilter filter) {
    switch (filter) {
      case _StatusFilter.all:
        return null;
      case _StatusFilter.pending:
        return 'pending';
      case _StatusFilter.paid:
        return 'paid';
      case _StatusFilter.cancelled:
        return 'cancelled';
    }
  }

  /// URL combining status and month. Default values ("Todas", current month)
  /// add no param, to keep it clean.
  static String _urlFor(_StatusFilter filter, DateTime month) {
    final params = <String, String>{};
    final filterValue = _filterQueryValue(filter);
    if (filterValue != null) params['filter'] = filterValue;
    if (!_isCurrentMonth(month)) {
      final mm = month.month.toString().padLeft(2, '0');
      params['month'] = '${month.year}-$mm';
    }
    return Uri(
      path: '/invoices',
      queryParameters: params.isEmpty ? null : params,
    ).toString();
  }

  bool _matchesStatus(Invoice invoice) {
    switch (_statusFilter) {
      case _StatusFilter.all:
        return true;
      case _StatusFilter.pending:
        return invoice.isPending;
      case _StatusFilter.paid:
        return invoice.paid;
      case _StatusFilter.cancelled:
        return invoice.cancelled;
    }
  }

  bool _matchesMonth(Invoice invoice) =>
      invoice.month == _selectedMonth.month &&
      invoice.year == _selectedMonth.year;

  /// Pending invoices from a period before the month being viewed.
  int _previousPendingCount(List<Invoice> all) {
    return all.where((i) {
      if (!i.isPending) return false;
      return i.year < _selectedMonth.year ||
          (i.year == _selectedMonth.year && i.month < _selectedMonth.month);
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListenableBuilder(
        listenable: Listenable.merge([
          widget.invoiceViewModel,
          widget.serviceViewModel,
        ]),
        builder: (context, _) {
          final allInvoices = widget.invoiceViewModel.invoices;
          final invoices = allInvoices
              .where(_matchesStatus)
              .where(_matchesMonth)
              .toList();
          // The notice only makes sense where pending invoices are visible.
          final previousPending = (_statusFilter == _StatusFilter.all ||
                  _statusFilter == _StatusFilter.pending)
              ? _previousPendingCount(allInvoices)
              : 0;
          final isInitialLoad =
              widget.invoiceViewModel.isLoading && allInvoices.isEmpty;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              ScreenHeader(
                title: 'Facturas',
                subtitle: 'Gestiona tus facturas y sus pagos.',
                size: ScreenHeaderSize.compact,
                onBack: widget.onBack,
                action: HeaderAddButton(
                  tooltip: 'Nueva factura',
                  onPressed: widget.onOpenForm,
                ),
              ),
              const SizedBox(height: 12),
              NotificationsHint(
                preferencesViewModel: widget.preferencesViewModel,
                onOpenPreferences: widget.onOpenPreferences,
              ),
              const SizedBox(height: 16),
              if (isInitialLoad)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.authAccent,
                    ),
                  ),
                )
              else ...[
                if (previousPending > 0) ...[
                  _PreviousPendingNotice(count: previousPending),
                  const SizedBox(height: 16),
                ],
                Align(
                  alignment: Alignment.centerLeft,
                  child: MonthFilterButton(
                    selectedMonth: _selectedMonth,
                    onChanged: (month) =>
                        context.push(_urlFor(_statusFilter, month)),
                  ),
                ),
                const SizedBox(height: 12),
                FilterChipRow<_StatusFilter>(
                  options: const [
                    (value: _StatusFilter.all, label: 'Todas'),
                    (value: _StatusFilter.pending, label: 'Pendientes'),
                    (value: _StatusFilter.paid, label: 'Pagadas'),
                    (value: _StatusFilter.cancelled, label: 'Canceladas'),
                  ],
                  selectedValue: _statusFilter,
                  onChanged: (value) {
                    if (value == _statusFilter) return;
                    context.push(_urlFor(value, _selectedMonth));
                  },
                ),
                const SizedBox(height: 16),
                if (invoices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text(
                      allInvoices.isEmpty
                          ? 'Todavía no hay facturas.\nTocá + para crear la '
                              'primera.'
                          : 'No hay facturas con este filtro.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.authSubtitle,
                    ),
                  )
                else
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.authCardFill,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.authCardBorder),
                    ),
                    child: Column(
                      children: List.generate(invoices.length, (i) {
                        final invoice = invoices[i];
                        final service = widget.serviceViewModel
                            .serviceById(invoice.serviceId);
                        return _InvoiceRow(
                          invoice: invoice,
                          serviceName: service?.name ?? 'Servicio eliminado',
                          currency: widget.currency,
                          onTap: () => widget.onOpenView(invoice),
                          showDivider: i != invoices.length - 1,
                        );
                      }),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PreviousPendingNotice extends StatelessWidget {
  final int count;

  const _PreviousPendingNotice({required this.count});

  @override
  Widget build(BuildContext context) {
    final text = count == 1
        ? 'Tenés 1 factura pendiente de un período anterior. '
            'Cambiá el mes para verla.'
        : 'Tenés $count facturas pendientes de períodos anteriores. '
            'Cambiá el mes para verlas.';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.authTextSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.authSubtitle.copyWith(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final Invoice invoice;
  final String serviceName;
  final String currency;
  final VoidCallback onTap;
  final bool showDivider;

  const _InvoiceRow({
    required this.invoice,
    required this.serviceName,
    required this.currency,
    required this.onTap,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = invoice.cancelled
        ? AppColors.authTextFooter
        : invoice.paid
            ? AppColors.authIncome
            : AppColors.authExpense;
    final badgeLabel = invoice.cancelled
        ? 'Cancelada'
        : invoice.paid
            ? 'Pagada'
            : 'Pendiente';

    final dueDate = invoice.dueDate;
    final subtitleParts = <String>[
      '${kMonthNames[invoice.month - 1]} ${invoice.year}',
      if (dueDate != null)
        'vence el ${dueDate.day.toString().padLeft(2, '0')}/'
            '${dueDate.month.toString().padLeft(2, '0')}',
    ];

    return Column(
      children: [
        Opacity(
          opacity: invoice.cancelled ? 0.5 : 1,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$serviceName - '
                          '${formatCurrency(invoice.amount, currency)}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.authTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitleParts.join(' · '),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.authTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.authTextFooter),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: AppColors.authCardBorder),
      ],
    );
  }
}
