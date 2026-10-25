import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../../core/widgets/text_action_button.dart';
import '../../../accounts/presentation/view_models/account_view_model.dart';
import '../../../accounts/presentation/view_models/monthly_balance_view_model.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../services/presentation/view_models/service_view_model.dart';
import '../../data/models/invoice.dart';
import '../utils/month_names.dart';
import '../view_models/invoice_view_model.dart';
import '../widgets/pay_invoice_dialog.dart';

enum _InvoiceAction { edit, pay, cancel }

/// Invoice detail. Edit, pay and cancel are only offered while the invoice
/// is pending.
class InvoiceViewScreen extends StatelessWidget {
  final String userId;
  final Invoice invoice;
  final InvoiceViewModel invoiceViewModel;
  final ServiceViewModel serviceViewModel;
  final CategoryViewModel categoryViewModel;
  final AccountViewModel accountViewModel;
  final MonthlyBalanceViewModel monthlyBalanceViewModel;
  final String currency;
  final VoidCallback onEdit;
  final VoidCallback onBack;

  const InvoiceViewScreen({
    super.key,
    required this.userId,
    required this.invoice,
    required this.invoiceViewModel,
    required this.serviceViewModel,
    required this.categoryViewModel,
    required this.accountViewModel,
    required this.monthlyBalanceViewModel,
    required this.currency,
    required this.onEdit,
    required this.onBack,
  });

  // The route guard resolves the invoice once, so look it up again to
  // reflect changes made after the screen was opened.
  Invoice _currentInvoice() {
    for (final i in invoiceViewModel.invoices) {
      if (i.id == invoice.id) return i;
    }
    return invoice;
  }

  Future<void> _confirmCancel(BuildContext context, Invoice invoice) async {
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
          '¿Cancelar factura?',
          style: TextStyle(
            color: AppColors.authTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'La factura quedará marcada como cancelada. Esta acción no se '
          'puede deshacer.',
          style: TextStyle(color: AppColors.authTextSecondary),
        ),
        actions: [
          TextActionButton(
            label: 'Volver',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          TextActionButton(
            label: 'Cancelar factura',
            color: AppColors.authExpense,
            fontWeight: FontWeight.w700,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ok = await invoiceViewModel.cancelInvoice(invoice.id);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            invoiceViewModel.errorMessage ?? 'No se pudo cancelar la factura.',
          ),
        ),
      );
    }
  }

  Future<void> _payInvoice(
    BuildContext context, {
    required Invoice invoice,
    required String serviceName,
    required Category? category,
  }) async {
    if (category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El servicio no tiene categoría o fue eliminado; no se puede '
            'registrar el pago.',
          ),
        ),
      );
      return;
    }

    final result = await showDialog<PayInvoiceResult>(
      context: context,
      builder: (_) => PayInvoiceDialog(
        invoice: invoice,
        serviceName: serviceName,
        category: category,
        accounts: accountViewModel.activeAccounts,
        pendingAccountIds: {
          for (final account in accountViewModel.activeAccounts)
            if (monthlyBalanceViewModel.isAccountPending(account.id)) account.id,
        },
        currency: currency,
      ),
    );

    if (result == null) return;

    final ok = await invoiceViewModel.payInvoice(
      invoice: invoice,
      userId: userId,
      accountId: result.accountId,
      categoryId: category.id,
      amount: result.amount,
      description: 'Factura · $serviceName',
      date: result.date,
    );

    // The account balance changed on the server together with the expense
    // transaction; reload accounts so the new balance is shown.
    if (ok) await accountViewModel.loadAccounts();

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            invoiceViewModel.errorMessage ?? 'No se pudo registrar el pago.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListenableBuilder(
        listenable: Listenable.merge([
          invoiceViewModel,
          serviceViewModel,
          categoryViewModel,
        ]),
        builder: (context, _) {
          final current = _currentInvoice();
          final service = serviceViewModel.serviceById(current.serviceId);
          final serviceName = service?.name ?? 'Servicio eliminado';
          final category = categoryViewModel.categoryById(service?.categoryId);
          final isBusy = invoiceViewModel.isCancelling(current.id) ||
              invoiceViewModel.isPaying(current.id);

          return Column(
            children: [
              if (isBusy)
                const LinearProgressIndicator(
                  backgroundColor: AppColors.authCardBorder,
                  color: AppColors.authAccent,
                  minHeight: 3,
                ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      children: [
                        ScreenHeader(
                          title: serviceName,
                          subtitle:
                              'Detalle de factura · ${kMonthNames[current.month - 1]} ${current.year}',
                          size: ScreenHeaderSize.compact,
                          onBack: onBack,
                          action: current.isPending
                              ? HeaderMenuButton<_InvoiceAction>(
                                  enabled: !isBusy,
                                  items: const [
                                    HeaderMenuItem(
                                      value: _InvoiceAction.edit,
                                      label: 'Editar factura',
                                      icon: Icons.edit_rounded,
                                    ),
                                    HeaderMenuItem(
                                      value: _InvoiceAction.pay,
                                      label: 'Registrar pago',
                                      icon: Icons.check_circle_outline_rounded,
                                    ),
                                    HeaderMenuItem(
                                      value: _InvoiceAction.cancel,
                                      label: 'Cancelar factura',
                                      icon: Icons.close_rounded,
                                      destructive: true,
                                    ),
                                  ],
                                  onSelected: (action) {
                                    switch (action) {
                                      case _InvoiceAction.edit:
                                        onEdit();
                                      case _InvoiceAction.pay:
                                        _payInvoice(
                                          context,
                                          invoice: current,
                                          serviceName: serviceName,
                                          category: category,
                                        );
                                      case _InvoiceAction.cancel:
                                        _confirmCancel(context, current);
                                    }
                                  },
                                )
                              : null,
                        ),
                        const SizedBox(height: 20),
                        _HeroInvoiceCard(
                          invoice: current,
                          serviceName: serviceName,
                          category: category,
                          currency: currency,
                        ),
                        if (current.isPending) ...[
                          const SizedBox(height: 14),
                          _QuickActionsRow(
                            isBusy: isBusy,
                            onPay: () => _payInvoice(
                              context,
                              invoice: current,
                              serviceName: serviceName,
                              category: category,
                            ),
                            onEdit: onEdit,
                            onCancel: () => _confirmCancel(context, current),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroInvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final String serviceName;
  final Category? category;
  final String currency;

  const _HeroInvoiceCard({
    required this.invoice,
    required this.serviceName,
    required this.category,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final isCancelled = invoice.cancelled;
    final isPaid = invoice.paid;

    final badgeColor = isCancelled
        ? AppColors.authTextFooter
        : isPaid
            ? AppColors.authIncome
            : AppColors.authExpense;
    final badgeLabel = isCancelled
        ? 'Cancelada'
        : isPaid
            ? 'Pagada'
            : 'Pendiente';

    final catColor = category?.color != null
        ? colorFromHex(category!.color)
        : AppColors.authAccent;

    final details = <_DetailRow>[
      _DetailRow(
        label: 'Estado',
        value: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: badgeColor.withValues(alpha: 0.28)),
          ),
          child: Text(
            badgeLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: badgeColor,
            ),
          ),
        ),
      ),
      _DetailRow(
        label: 'Monto',
        value: Text(
          formatCurrency(invoice.amount, currency),
          style: _valueStyle,
        ),
      ),
      _DetailRow(
        label: 'Período',
        value: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              size: 14,
              color: AppColors.authAccent,
            ),
            const SizedBox(width: 6),
            Text(
              '${kMonthNames[invoice.month - 1]} ${invoice.year}',
              style: _valueStyle,
            ),
          ],
        ),
      ),
      _DetailRow(
        label: 'Vencimiento',
        value: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (invoice.dueDate != null) ...[
              const Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: AppColors.authAccent,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              invoice.dueDate != null
                  ? formatDate(invoice.dueDate!)
                  : 'Sin vencimiento',
              style: _valueStyle,
            ),
          ],
        ),
      ),
      _DetailRow(
        label: 'Categoría',
        value: category == null
            ? const Text('Sin categoría', style: _valueStyle)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: catColor,
                      boxShadow: [
                        BoxShadow(
                          color: catColor.withValues(alpha: 0.45),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(category!.name, style: _valueStyle),
                ],
              ),
      ),
      if (invoice.paid && invoice.paidAt != null)
        _DetailRow(
          label: 'Fecha de pago',
          value: Text(formatDate(invoice.paidAt!), style: _valueStyle),
        ),
      if (invoice.cancelled && invoice.cancelledAt != null)
        _DetailRow(
          label: 'Fecha de cancelación',
          value: Text(
            formatDate(invoice.cancelledAt!),
            style: _valueStyle,
          ),
        ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.authCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: catColor.withValues(alpha: 0.32),
                  ),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  size: 24,
                  color: catColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: AppColors.authTextPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: badgeColor.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPaid
                                ? Icons.check_circle_rounded
                                : isCancelled
                                    ? Icons.cancel_outlined
                                    : Icons.schedule_rounded,
                            size: 13,
                            color: badgeColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            badgeLabel,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Monto de la factura',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: AppColors.authTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatCurrency(invoice.amount, currency),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: AppColors.authTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.authCardBorder),
          const SizedBox(height: 4),
          for (var i = 0; i < details.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                color: AppColors.authCardBorder,
              ),
            details[i],
          ],
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final bool isBusy;
  final VoidCallback onPay;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  const _QuickActionsRow({
    required this.isBusy,
    required this.onPay,
    required this.onEdit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Primary Action: Registrar pago
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.authCardFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.authCardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isBusy ? null : onPay,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.authAccent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.authAccent.withValues(alpha: 0.30),
                        ),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                        color: AppColors.authAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Registrar pago',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.authAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Secondary Actions Row
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.authCardFill,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.authCardBorder),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isBusy ? null : onEdit,
                    borderRadius: BorderRadius.circular(14),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            size: 16,
                            color: AppColors.authTextSecondary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Editar',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.authTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.authCardFill,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.authCardBorder),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isBusy ? null : onCancel,
                    borderRadius: BorderRadius.circular(14),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: AppColors.authExpense,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Cancelar',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.authExpense,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

const _valueStyle = TextStyle(
  fontSize: 14.5,
  fontWeight: FontWeight.w600,
  color: AppColors.authTextPrimary,
);

class _DetailRow extends StatelessWidget {
  final String label;
  final Widget value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.authTextSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          value,
        ],
      ),
    );
  }
}
