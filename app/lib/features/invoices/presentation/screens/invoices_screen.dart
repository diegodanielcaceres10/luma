import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/app_clock.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/utils/date_format.dart';
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
    final now = nowLocal();
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
          final monthInvoices = allInvoices.where(_matchesMonth).toList();
          final invoices = monthInvoices.where(_matchesStatus).toList();

          // Total commitment for the selected month (excluding cancelled)
          final totalMonthAmount = monthInvoices
              .where((i) => !i.cancelled)
              .fold<double>(0, (sum, i) => sum + i.amount);
          final paidMonthCount =
              monthInvoices.where((i) => i.paid).length;
          final pendingMonthCount =
              monthInvoices.where((i) => i.isPending).length;

          // The notice only makes sense where pending invoices are visible.
          final previousPending = (_statusFilter == _StatusFilter.all ||
                  _statusFilter == _StatusFilter.pending)
              ? _previousPendingCount(allInvoices)
              : 0;
          final isInitialLoad =
              widget.invoiceViewModel.isLoading && allInvoices.isEmpty;

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
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
                    _InvoiceMonthSummaryCard(
                      totalAmount: totalMonthAmount,
                      paidCount: paidMonthCount,
                      pendingCount: pendingMonthCount,
                      currency: widget.currency,
                    ),
                    const SizedBox(height: 16),
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
                      _EmptyInvoicesCard(
                        message: allInvoices.isEmpty
                            ? 'Todavía no hay facturas.\nTocá + para crear la primera.'
                            : 'No hay facturas con este filtro.',
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.authCardFill,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.authCardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: List.generate(invoices.length, (i) {
                            final invoice = invoices[i];
                            final service = widget.serviceViewModel
                                .serviceById(invoice.serviceId);
                            return _InvoiceRow(
                              invoice: invoice,
                              serviceName:
                                  service?.name ?? 'Servicio eliminado',
                              currency: widget.currency,
                              onTap: () => widget.onOpenView(invoice),
                              showDivider: i != invoices.length - 1,
                            );
                          }),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InvoiceMonthSummaryCard extends StatelessWidget {
  final double totalAmount;
  final int paidCount;
  final int pendingCount;
  final String currency;

  const _InvoiceMonthSummaryCard({
    required this.totalAmount,
    required this.paidCount,
    required this.pendingCount,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.authCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.authAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.authAccent.withValues(alpha: 0.30),
              ),
            ),
            child: const Icon(
              Icons.receipt_rounded,
              color: AppColors.authAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total mensual facturado',
                  style: TextStyle(
                    color: AppColors.authTextSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  formatCurrency(totalAmount, currency),
                  style: const TextStyle(
                    color: AppColors.authTextPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.authIncome,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$paidCount pagadas',
                      style: const TextStyle(
                        color: AppColors.authTextFooter,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.authExpense,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$pendingCount pendientes',
                      style: const TextStyle(
                        color: AppColors.authTextFooter,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInvoicesCard extends StatelessWidget {
  final String message;

  const _EmptyInvoicesCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.authAccent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.authAccent.withValues(alpha: 0.25),
              ),
            ),
            child: const Icon(
              Icons.receipt_outlined,
              size: 28,
              color: AppColors.authAccent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.authSubtitle,
          ),
        ],
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.authAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.authAccent.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.schedule_rounded,
              size: 16,
              color: AppColors.authAccent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.authTextPrimary,
              ),
            ),
          ),
        ],
      ),
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
    final isCancelled = invoice.cancelled;
    final isPaid = invoice.paid;

    final statusColor = isCancelled
        ? AppColors.authTextFooter
        : isPaid
            ? AppColors.authIncome
            : AppColors.authExpense;
    final badgeLabel = isCancelled
        ? 'Cancelada'
        : isPaid
            ? 'Pagada'
            : 'Pendiente';

    final dueDate = invoice.dueDate;
    final subtitleParts = <String>[
      '${kMonthNames[invoice.month - 1]} ${invoice.year}',
      if (dueDate != null) 'vence el ${formatDate(dueDate)}',
    ];

    final iconData = isCancelled
        ? Icons.cancel_outlined
        : isPaid
            ? Icons.check_circle_rounded
            : Icons.schedule_rounded;

    return Column(
      children: [
        Opacity(
          opacity: isCancelled ? 0.5 : 1.0,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Icon(
                        iconData,
                        size: 20,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            serviceName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.authTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitleParts.join(' · '),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.authTextSecondary,
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
                          formatCurrency(invoice.amount, currency),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isCancelled
                                ? AppColors.authTextFooter
                                : AppColors.authTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.24),
                            ),
                          ),
                          child: Text(
                            badgeLabel,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.authTextFooter,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 70,
            endIndent: 16,
            color: AppColors.authCardBorder,
          ),
      ],
    );
  }
}
